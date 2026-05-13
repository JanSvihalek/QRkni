import 'package:cloud_firestore/cloud_firestore.dart';

class Worker {
  final String? id;
  final String name;
  final String pinHash;
  final DateTime createdAt;
  final DateTime? lastSeen;

  const Worker({
    this.id,
    required this.name,
    required this.pinHash,
    required this.createdAt,
    this.lastSeen,
  });

  bool get isOnline =>
      lastSeen != null &&
      DateTime.now().difference(lastSeen!).inMinutes < 15;

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'pinHash': pinHash,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Worker.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Worker(
      id: doc.id,
      name: data['name'] as String,
      pinHash: data['pinHash'] as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }
}
