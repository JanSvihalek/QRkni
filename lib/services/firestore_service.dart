import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_profile.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _profilesRef(String uid) =>
      _db.collection('users').doc(uid).collection('profiles');

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
}
