import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionItem {
  final String name;
  final double price;
  final int quantity;

  const TransactionItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  Map<String, dynamic> toMap() => {'name': name, 'price': price, 'quantity': quantity};

  factory TransactionItem.fromMap(Map<String, dynamic> m) => TransactionItem(
        name: m['name'] as String,
        price: (m['price'] as num).toDouble(),
        quantity: (m['quantity'] as num).toInt(),
      );
}

class PaymentTransaction {
  final String? id;
  final String profileId;
  final String profileName;
  final double amount;
  final List<TransactionItem> items;
  final DateTime createdAt;
  final String? createdBy;

  const PaymentTransaction({
    this.id,
    required this.profileId,
    required this.profileName,
    required this.amount,
    required this.items,
    required this.createdAt,
    this.createdBy,
  });

  Map<String, dynamic> toFirestore() => {
        'profileId': profileId,
        'profileName': profileName,
        'amount': amount,
        'items': items.map((i) => i.toMap()).toList(),
        'createdAt': Timestamp.fromDate(createdAt),
        if (createdBy != null) 'createdBy': createdBy,
      };

  factory PaymentTransaction.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentTransaction(
      id: doc.id,
      profileId: data['profileId'] as String,
      profileName: data['profileName'] as String,
      amount: (data['amount'] as num).toDouble(),
      items: (data['items'] as List<dynamic>?)
              ?.map((i) => TransactionItem.fromMap(i as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdBy: data['createdBy'] as String?,
    );
  }
}
