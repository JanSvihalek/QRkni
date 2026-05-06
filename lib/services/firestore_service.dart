import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_profile.dart';
import '../models/payment_item.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instanceFor(
    app: FirebaseFirestore.instance.app,
    databaseId: 'qrkni',
  );

  DocumentReference<Map<String, dynamic>> _userRef(String uid) =>
      _db.collection('users').doc(uid);

  CollectionReference<Map<String, dynamic>> _profilesRef(String uid) =>
      _db.collection('users').doc(uid).collection('profiles');

  /// Vytvoří nebo aktualizuje dokument uživatele.
  /// Bezpečné volat při registraci i přihlášení (merge: true).
  Future<void> saveUser({
    required String uid,
    required String email,
    bool isNewUser = false,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
    if (isNewUser) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    await _userRef(uid).set(data, SetOptions(merge: true));
  }

  Stream<List<PaymentProfile>> profilesStream(String uid) {
    return _profilesRef(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(PaymentProfile.fromFirestore).toList());
  }

  Future<void> addProfile(String uid, PaymentProfile profile) async {
    await _profilesRef(uid).add(profile.toFirestore());
  }

  Future<void> updateProfile(String uid, PaymentProfile profile) async {
    await _profilesRef(uid).doc(profile.id).update(profile.toFirestore());
  }

  Future<void> deleteProfile(String uid, String profileId) async {
    await _profilesRef(uid).doc(profileId).delete();
  }

  // ── Položky (items) ──────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _itemsRef(String uid) =>
      _db.collection('users').doc(uid).collection('items');

  Stream<List<PaymentItem>> itemsStream(String uid) {
    return _itemsRef(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) => snap.docs.map(PaymentItem.fromFirestore).toList());
  }

  Future<void> addItem(String uid, PaymentItem item) async {
    await _itemsRef(uid).add(item.toFirestore());
  }

  Future<void> updateItem(String uid, PaymentItem item) async {
    await _itemsRef(uid).doc(item.id).update(item.toFirestore());
  }

  Future<void> deleteItem(String uid, String itemId) async {
    await _itemsRef(uid).doc(itemId).delete();
  }
}
