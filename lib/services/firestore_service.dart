import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_profile.dart';
import '../models/payment_item.dart';
import '../models/payment_transaction.dart';
import '../models/worker.dart';

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
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    final doc = await _userRef(uid).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    return {
      ...data,
      if (data['createdAt'] != null)
        'createdAt': (data['createdAt'] as Timestamp).toDate(),
    };
  }

  Future<void> saveUser({
    required String uid,
    required String email,
    bool isNewUser = false,
    DateTime? termsAcceptedAt,
  }) async {
    final data = <String, dynamic>{
      'email': email,
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
    if (isNewUser) {
      data['createdAt'] = FieldValue.serverTimestamp();
    }
    if (termsAcceptedAt != null) {
      data['termsAcceptedAt'] = Timestamp.fromDate(termsAcceptedAt);
      data['termsVersion'] = '2026-05-15';
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

  // ── Transakce (historie plateb) ──────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _transactionsRef(String uid) =>
      _db.collection('users').doc(uid).collection('transactions');

  Stream<List<PaymentTransaction>> transactionsStream(String uid) {
    return _transactionsRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PaymentTransaction.fromFirestore).toList());
  }

  Future<void> addTransaction(String uid, PaymentTransaction transaction) async {
    await _transactionsRef(uid).add(transaction.toFirestore());
  }

  // ── Měsíční počet QR kódů (free tier) ───────────────────────────────────

  String _monthKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  Future<int> getMonthlyQrCount(String uid) async {
    final doc = await _userRef(uid).get();
    if (!doc.exists) return 0;
    final data = doc.data()!;
    if ((data['qr_month'] as String?) != _monthKey()) return 0;
    return (data['qr_count'] as int?) ?? 0;
  }

  Future<void> incrementQrCount(String uid) async {
    final month = _monthKey();
    await _db.runTransaction((tx) async {
      final ref = _userRef(uid);
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final storedMonth = data['qr_month'] as String? ?? '';
      final current =
          storedMonth == month ? (data['qr_count'] as int? ?? 0) : 0;
      tx.update(ref, {'qr_month': month, 'qr_count': current + 1});
    });
  }

  // ── Nastavení aplikace ───────────────────────────────────────────────────

  Future<Map<String, dynamic>> loadSettings(String uid) async {
    final doc = await _userRef(uid).get();
    if (!doc.exists) return {};
    return (doc.data()!['settings'] as Map<String, dynamic>?) ?? {};
  }

  Future<void> saveSettings(String uid, Map<String, dynamic> settings) async {
    await _userRef(uid).set({'settings': settings}, SetOptions(merge: true));
  }

  // ── Brigádníci ───────────────────────────────────────────────────────────

  CollectionReference<Map<String, dynamic>> _workersRef(String uid) =>
      _db.collection('users').doc(uid).collection('workers');

  Stream<List<Worker>> workersStream(String uid) =>
      _workersRef(uid)
          .orderBy('createdAt', descending: false)
          .snapshots()
          .map((s) => s.docs.map(Worker.fromFirestore).toList());

  Future<void> addWorker(String uid, Worker worker) async {
    await _workersRef(uid).add(worker.toFirestore());
  }

  Future<void> deleteWorker(String uid, String workerId) async {
    await _workersRef(uid).doc(workerId).delete();
  }

  Future<bool> workerExistsByPinHash(String ownerUid, String pinHash) async {
    final snap = await _workersRef(ownerUid)
        .where('pinHash', isEqualTo: pinHash)
        .limit(1)
        .get(const GetOptions(source: Source.server));
    return snap.docs.isNotEmpty;
  }

  Future<void> updateWorkerLastSeen(String ownerUid, String pinHash) async {
    final snap = await _workersRef(ownerUid)
        .where('pinHash', isEqualTo: pinHash)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return;
    await snap.docs.first.reference
        .update({'lastSeen': FieldValue.serverTimestamp()});
  }
}
