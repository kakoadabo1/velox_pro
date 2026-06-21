import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Couche d'accès Firestore partagée par TOUTES les apps VELOX.
/// C'est le "contrat" : les apps Client et Restaurant écrivent/ lisent les
/// mêmes collections, et l'app Partenaire réagit en temps réel.
///
/// Collections :
///   partners/{uid}   -> { role, online, name, updatedAt }
///   orders/{id}      -> commande de livraison (créée par le Client)
///   rides/{id}       -> course taxi (créée par le Client)
///
/// Cycle de vie d'une commande (champ `status`) :
///   en_attente_resto -> en_preparation -> prete
///   -> assignee -> recuperee -> livree   (gérée par le livreur)
///
/// Cycle de vie d'une course (champ `status`) :
///   recherche -> assignee -> en_route -> terminee
class FirestoreService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

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
        'name': FirebaseAuth.instance.currentUser?.email,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (lat != null && lng != null) {
        data['lat'] = lat;
        data['lng'] = lng;
      }
      await _db.collection('partners').doc(uid).set(
            data,
            SetOptions(merge: true),
          );
    } catch (_) {
      // silencieux : ne jamais bloquer l'UI si le réseau/les règles échouent
    }
  }

  /// Document du partenaire (stats : gainsToday, deliveries, rating, ...).
  static Stream<Map<String, dynamic>> partnerStream() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db.collection('partners').doc(uid).snapshots().map(
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

  /// Missions terminées (pour l'historique).
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
  /// Commandes prêtes et pas encore prises par un livreur.
  static Stream<List<Map<String, dynamic>>> pendingOrders() {
    return _db
        .collection('orders')
        .where('status', isEqualTo: 'prete')
        .where('courierId', isNull: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Ma livraison en cours (assignée à moi, non terminée).
  static Stream<List<Map<String, dynamic>>> myActiveOrders() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('orders')
        .where('courierId', isEqualTo: uid)
        .where('status', whereIn: ['assignee', 'recuperee'])
        .snapshots()
        .map((s) =>
            s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Accepte une commande de façon SÛRE (transaction).
  /// Renvoie true si réussi, false si déjà prise par un autre.
  static Future<bool> acceptOrder(String orderId) async {
    final uid = _uid;
    if (uid == null) return false;
    final ref = _db.collection('orders').doc(orderId);
    try {
      return await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data() as Map<String, dynamic>;
        if (data['courierId'] != null || data['status'] != 'prete') {
          return false; // déjà prise / plus disponible
        }
        tx.update(ref, {
          'courierId': uid,
          'status': 'assignee',
          'assignedAt': FieldValue.serverTimestamp(),
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

  // ───────────────────────────── COURSES (rides) ─────────────────────────────
  static Stream<List<Map<String, dynamic>>> pendingRides() {
    return _db
        .collection('rides')
        .where('status', isEqualTo: 'recherche')
        .where('driverId', isNull: true)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  static Stream<List<Map<String, dynamic>>> myActiveRides() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    return _db
        .collection('rides')
        .where('driverId', isEqualTo: uid)
        .where('status', whereIn: ['assignee', 'en_route'])
        .snapshots()
        .map((s) =>
            s.docs.map((d) => {'id': d.id, ...d.data()}).toList());
  }

  /// Accepte une course de façon SÛRE (transaction).
  /// Renvoie true si réussi, false si déjà prise par un autre.
  static Future<bool> acceptRide(String rideId) async {
    final uid = _uid;
    if (uid == null) return false;
    final ref = _db.collection('rides').doc(rideId);
    try {
      return await _db.runTransaction<bool>((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) return false;
        final data = snap.data() as Map<String, dynamic>;
        if (data['driverId'] != null || data['status'] != 'recherche') {
          return false; // déjà prise / plus disponible
        }
        tx.update(ref, {
          'driverId': uid,
          'status': 'assignee',
          'assignedAt': FieldValue.serverTimestamp(),
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
}
