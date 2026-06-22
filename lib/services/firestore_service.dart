import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Couche d'accès Firestore de l'app PARTENAIRE, alignée sur le CONTRAT de
/// l'app Client (mêmes collections, mêmes noms de champs, mêmes statuts).
///
///   taxiRides/{id}   -> course (créée par le Client, status 'requested')
///   orders/{id}      -> commande (status 'ready' = prête à enlever)
///   partners/{uid}   -> ADMIN : { role, approved, name, phone }
///   partner_status/{uid} -> écrit par l'app : { online, lat, lng, stats... }
///   reviews/{id}     -> avis
///
/// Courses :  requested -> accepted -> arriving -> arrived -> started -> completed
/// Commandes: ... -> ready -> delivering -> completed
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // ───────────────────────── VÉRIFICATION DU RÔLE ────────────────────────────
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
    required String role,
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
      await _db
          .collection('partner_status')
          .doc(uid)
          .set(data, SetOptions(merge: true));
    } catch (_) {}
  }

  static Stream<Map<String, dynamic>> partnerStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('partner_status').doc(uid).snapshots().map(
          (d) => d.data() ?? <String, dynamic>{},
        );
  }

  static Stream<List<Map<String, dynamic>>> myReviews() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('reviews')
        .where('targetId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  // ═══════════════════════════ LIVRAISONS (orders) ═══════════════════════════
  /// Commandes PRÊTES à enlever et pas encore prises par un livreur.
  static Stream<List<Map<String, dynamic>>> pendingOrders() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'ready')
        .where('deliveryDriverId', isNull: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Ma livraison en cours.
  static Stream<List<Map<String, dynamic>>> myActiveOrders() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('orders')
        .where('deliveryDriverId', isEqualTo: uid)
        .where('status', whereIn: ['ready', 'delivering'])
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Stream<List<Map<String, dynamic>>> completedOrders() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('orders')
        .where('deliveryDriverId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Le livreur prend la livraison (transaction) + écrit son nom/téléphone.
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
        if (od['deliveryDriverId'] != null || od['status'] != 'ready') {
          return false;
        }
        final pd = (await tx.get(pref)).data() ?? {};
        tx.update(oref, {
          'deliveryDriverId': uid,
          'deliveryDriverName':
              pd['name'] ?? FirebaseAuth.instance.currentUser?.email,
          'deliveryDriverPhone': pd['phone'] ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  /// Change le statut d'une commande (+ horodatage associé).
  static Future<void> setOrderStatus(String orderId, String status) {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'delivering') data['pickedUpAt'] = FieldValue.serverTimestamp();
    return _db.collection('orders').doc(orderId).update(data);
  }

  /// Termine une livraison (+ stats livreur).
  static Future<void> completeOrder(String orderId, num amount) async {
    await _finish(
      missionRef: _db.collection('orders').doc(orderId),
      finalStatus: 'completed',
      stampKey: 'deliveredAt',
      amount: amount,
      counterKey: 'deliveries',
      doneKey: 'delivered',
    );
  }

  // ════════════════════════════ COURSES (taxiRides) ══════════════════════════
  /// Courses DEMANDÉES, pas encore prises.
  static Stream<List<Map<String, dynamic>>> pendingRides() {
    return _db
        .collection('taxiRides')
        .where('status', isEqualTo: 'requested')
        .where('driverId', isNull: true)
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Stream<List<Map<String, dynamic>>> myActiveRides() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('taxiRides')
        .where('driverId', isEqualTo: uid)
        .where('status',
            whereIn: ['accepted', 'arriving', 'arrived', 'started'])
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Stream<List<Map<String, dynamic>>> completedRides() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('taxiRides')
        .where('driverId', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((s) => s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Le chauffeur prend la course (transaction) + écrit son nom/téléphone.
  static Future<bool> acceptRide(String rideId) async {
    final uid = _uid;
    if (uid == null) return false;
    final rref = _db.collection('taxiRides').doc(rideId);
    final pref = _db.collection('partners').doc(uid);
    try {
      return await _db.runTransaction<bool>((tx) async {
        final rsnap = await tx.get(rref);
        if (!rsnap.exists) return false;
        final rd = rsnap.data() as Map<String, dynamic>;
        if (rd['driverId'] != null || rd['status'] != 'requested') {
          return false;
        }
        final pd = (await tx.get(pref)).data() ?? {};
        tx.update(rref, {
          'driverId': uid,
          'driverName':
              pd['name'] ?? FirebaseAuth.instance.currentUser?.email,
          'driverPhone': pd['phone'] ?? '',
          'status': 'accepted',
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      });
    } catch (_) {
      return false;
    }
  }

  /// Change le statut d'une course (+ horodatage associé).
  static Future<void> setRideStatus(String rideId, String status) {
    final data = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (status == 'arrived') data['arrivedAt'] = FieldValue.serverTimestamp();
    if (status == 'started') data['startedAt'] = FieldValue.serverTimestamp();
    return _db.collection('taxiRides').doc(rideId).update(data);
  }

  /// Termine une course (+ stats chauffeur + finalFare).
  static Future<void> completeRide(String rideId, num amount) async {
    await _db.collection('taxiRides').doc(rideId).update({
      'finalFare': amount,
    }).catchError((_) {});
    await _finish(
      missionRef: _db.collection('taxiRides').doc(rideId),
      finalStatus: 'completed',
      stampKey: 'completedAt',
      amount: amount,
      counterKey: 'rides',
      doneKey: 'done',
    );
  }

  // ───────────────── Terminer une mission + agréger les stats ─────────────────
  static Future<void> _finish({
    required DocumentReference<Map<String, dynamic>> missionRef,
    required String finalStatus,
    required String stampKey,
    required num amount,
    required String counterKey,
    required String doneKey,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    final sref = _db.collection('partner_status').doc(uid);
    final now = DateTime.now();
    final today = '${now.year}-${now.month}-${now.day}';
    final month = '${now.year}-${now.month}';
    final wi = now.weekday - 1;
    try {
      await _db.runTransaction((tx) async {
        final s = await tx.get(sref);
        final d = s.data() ?? <String, dynamic>{};
        final sameDay = d['statsDate'] == today;
        final sameMonth = d['statsMonth'] == month;

        num gainsToday = sameDay ? (d['gainsToday'] ?? 0) as num : 0;
        int counter = sameDay ? ((d[counterKey] ?? 0) as num).toInt() : 0;
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
          stampKey: FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
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
