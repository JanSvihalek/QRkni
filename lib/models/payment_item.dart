import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentItem {
  final String? id;
  final String name;
  final double price;
  final DateTime createdAt;

  const PaymentItem({
    this.id,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'price': price,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory PaymentItem.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentItem(
      id: doc.id,
      name: data['name'] as String,
      price: (data['price'] as num).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
