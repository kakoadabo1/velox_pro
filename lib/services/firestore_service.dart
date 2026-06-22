import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Couche d'accès Firestore partagée par TOUTES les apps VELOX.
///
/// Modèle (séparation sécurité) :
///   partners/{uid}        -> ADMIN uniquement : { role, approved, name, phone }
///   partner_status/{uid}  -> écrit par l'app  : { online, lat, lng, stats... }
///   orders/{id}           -> commande de livraison (créée par le Client)
///   rides/{id}            -> course taxi (créée par le Client)
///   reviews/{id}          -> avis (créé par le Client)
///
/// Le ROLE est dans partners/{uid}, écrit seulement par l'admin (console) :
/// l'utilisateur ne peut donc PAS se déclarer livreur tout seul.
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ───────────────────────── VÉRIFICATION DU RÔLE ────────────────────────────
  /// Vrai si le compte connecté est un partenaire APPROUVÉ pour ce rôle.
  /// Lit partners/{uid} (doc contrôlé par l'admin).
  static Future<bool> hasRole(String role) async {
    final uid = _uid;
    if (uid == null) return false;
    try {
      final doc = await _db.collection('partners').doc(uid).get();
      if (!doc.exists) return false;
      final d = doc.data() ?? {};
      return d['role'] == role && d['approved'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─────────────── Statut du partenaire (en ligne / hors ligne) ───────────────
  static Future<void> setPartnerOnline({
    required String role, // 'livreur' | 'driver'
    required bool online,
    double? lat,
    double? lng,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final data = <String, dynamic>{
        'role': role,
        'online': online,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (lat != null && lng != null) {
        data['lat'] = lat;
        data['lng'] = lng;
      }
      await _db.collection('partner_status').doc(uid).set(
            data,
            SetOptions(merge: true),
          );
    } catch (_) {
      // silencieux : ne jamais bloquer l'UI
    }
  }

  /// Statut + stats du partenaire (gainsToday, deliveries, weekly, ...).
  static Stream<Map<String, dynamic>> partnerStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('partner_status').doc(uid).snapshots().map(
          (d) => d.data() ?? <String, dynamic>{},
        );
  }

  /// Avis reçus par ce partenaire.
  static Stream<List<Map<String, dynamic>>> myReviews() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('reviews')
        .where('targetId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Stream<List<Map<String, dynamic>>> completedOrders() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('orders')
        .where('courierId', isEqualTo: uid)
        .where('status', isEqualTo: 'livree')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Stream<List<Map<String, dynamic>>> completedRides() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('rides')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'terminee')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ─────────────────────────── LIVRAISONS (orders) ───────────────────────────
  static Stream<List<Map<String, dynamic>>> pendingOrders() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'prete')
        .where('courierId', isNull: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Stream<List<Map<String, dynamic>>> myActiveOrders() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('orders')
        .where('courierId', isEqualTo: uid)
        .where('status', whereIn: ['assignee', 'recuperee'])
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Accepte une commande SÛREMENT (transaction) ET écrit le téléphone du
  /// livreur pour que le CLIENT puisse l'appeler.
  static Future<bool> acceptOrder(String orderId) async {
    final uid = _uid;
    if (uid == null) return false;
    final oref = _db.collection('orders').doc(orderId);
    final pref = _db.collection('partners').doc(uid);
    try {
      return await _db.runTransaction<bool>((tx) async {
        final osnap = await tx.get(oref);
        if (!osnap.exists) return false;
        final od = osnap.data() as Map<String, dynamic>;
        if (od['courierId'] != null || od['status'] != 'prete') {
          return false; // déjà prise
        }
        final psnap = await tx.get(pref);
        final pd = psnap.data() ?? {};
        tx.update(oref, {
          'courierId': uid,
          'status': 'assignee',
          'assignedAt': FieldValue.serverTimestamp(),
          'courierName':
              pd['name'] ?? FirebaseAuth.instance.currentUser?.email,
          'courierPhone': pd['phone'] ?? '',
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  static Future<void> setOrderStatus(String orderId, String status) {
    return _db.collection('orders').doc(orderId).update({'status': status});
  }

  /// Termine une livraison ET met à jour les gains/stats du livreur.
  static Future<void> completeOrder(String orderId, num amount) async {
    await _finish(
      missionRef: _db.collection('orders').doc(orderId),
      finalStatus: 'livree',
      amount: amount,
      counterKey: 'deliveries',
      doneKey: 'delivered',
    );
  }

  // ───────────────────────────── COURSES (rides) ─────────────────────────────
  static Stream<List<Map<String, dynamic>>> pendingRides() {
    return _db
        .collection('rides')
        .where('status', isEqualTo: 'recherche')
        .where('driverId', isNull: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Stream<List<Map<String, dynamic>>> myActiveRides() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('rides')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['assignee', 'en_route'])
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Accepte une course SÛREMENT (transaction) ET écrit le téléphone du
  /// chauffeur pour que le CLIENT puisse l'appeler.
  static Future<bool> acceptRide(String rideId) async {
    final uid = _uid;
    if (uid == null) return false;
    final rref = _db.collection('rides').doc(rideId);
    final pref = _db.collection('partners').doc(uid);
    try {
      return await _db.runTransaction<bool>((tx) async {
        final rsnap = await tx.get(rref);
        if (!rsnap.exists) return false;
        final rd = rsnap.data() as Map<String, dynamic>;
        if (rd['driverId'] != null || rd['status'] != 'recherche') {
          return false; // déjà prise
        }
        final psnap = await tx.get(pref);
        final pd = psnap.data() ?? {};
        tx.update(rref, {
          'driverId': uid,
          'status': 'assignee',
          'assignedAt': FieldValue.serverTimestamp(),
          'driverName':
              pd['name'] ?? FirebaseAuth.instance.currentUser?.email,
          'driverPhone': pd['phone'] ?? '',
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  static Future<void> setRideStatus(String rideId, String status) {
    return _db.collection('rides').doc(rideId).update({'status': status});
  }

  /// Termine une course ET met à jour les gains/stats du chauffeur.
  static Future<void> completeRide(String rideId, num amount) async {
    await _finish(
      missionRef: _db.collection('rides').doc(rideId),
      finalStatus: 'terminee',
      amount: amount,
      counterKey: 'rides',
      doneKey: 'done',
    );
  }

  // ───────────────── Cœur : terminer une mission + agréger les stats ──────────
  /// Met le statut final sur la mission ET incrémente les stats du partenaire
  /// dans partner_status/{uid} (réinitialisation quotidienne/mensuelle).
  static Future<void> _finish({
    required DocumentReference<Map<String, dynamic>> missionRef,
    required String finalStatus,
    required num amount,
    required String counterKey, // 'deliveries' | 'rides'
    required String doneKey, // 'delivered' | 'done'
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final sref = _db.collection('partner_status').doc(uid);
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final month = '${now.year}-${now.month}';
    final wi = now.weekday - 1; // lundi=0 ... dimanche=6
    try {
      await _db.runTransaction((tx) async {
        final s = await tx.get(sref);
        final d = s.data() ?? <String, dynamic>{};
        final sameDay = d['statsDate'] == today;
        final sameMonth = d['statsMonth'] == month;

        num gainsToday = sameDay ? (d['gainsToday'] ?? 0) as num : 0;
        int counter =
            sameDay ? ((d[counterKey] ?? 0) as num).toInt() : 0;
        num gainsMonth = sameMonth ? (d['gainsMonth'] ?? 0) as num : 0;

        List<dynamic> weekly =
            List<dynamic>.from(d['weekly'] ?? List.filled(7, 0));
        if (weekly.length < 7) weekly = List.filled(7, 0);

        gainsToday += amount;
        counter += 1;
        gainsMonth += amount;
        weekly[wi] = ((weekly[wi] ?? 0) as num) + amount;
        final done = ((d[doneKey] ?? 0) as num).toInt() + 1;
        final gainsWeek = weekly.fold<num>(0, (a, b) => a + (b as num));

        tx.update(missionRef, {
          'status': finalStatus,
          'completedAt': FieldValue.serverTimestamp(),
        });
        tx.set(
          sref,
          {
            'statsDate': today,
            'statsMonth': month,
            'gainsToday': gainsToday,
            counterKey: counter,
            'gainsMonth': gainsMonth,
            'gainsWeek': gainsWeek,
            'weekly': weekly,
            doneKey: done,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      });
    } catch (_) {}
  }
}
