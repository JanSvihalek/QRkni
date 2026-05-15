import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentProfile {
  final String? id;
  final String name;
  final String iban;
  final String? bic;
  final String? recipientName;
  final double? defaultAmount;
  final String? message;
  final String? variableSymbol;
  final String? specificSymbol;
  final String? constantSymbol;
  final DateTime createdAt;
  final bool requireCustomerConfirmation;

  const PaymentProfile({
    this.id,
    required this.name,
    required this.iban,
    this.bic,
    this.recipientName,
    this.defaultAmount,
    this.message,
    this.variableSymbol,
    this.specificSymbol,
    this.constantSymbol,
    required this.createdAt,
    this.requireCustomerConfirmation = false,
  });

  /// Generuje SPAYD řetězec pro český QR platební kód.
  /// Formát: SPD*1.0*ACC:{IBAN}[+{BIC}]*AM:{amount}*CC:CZK*...
  ///
  /// Override sémantika: null = použít hodnotu z profilu, prázdný string =
  /// explicitně bez hodnoty (pole se do SPAYD nepřidá).
  String toSpaydString({
    double? amount,
    String? messageOverride,
    String? variableSymbolOverride,
    String? constantSymbolOverride,
    String? specificSymbolOverride,
  }) {
    final effectiveAmount = amount ?? defaultAmount;
    final parts = <String>['SPD', '1.0'];

    final acc = (bic != null && bic!.isNotEmpty) ? '$iban+$bic' : iban;
    parts.add('ACC:$acc');

    if (effectiveAmount != null) {
      parts.add('AM:${effectiveAmount.toStringAsFixed(2)}');
    }

    parts.add('CC:CZK');

    if (recipientName != null && recipientName!.isNotEmpty) {
      final rn = recipientName!.length > 35 ? recipientName!.substring(0, 35) : recipientName!;
      parts.add('RN:$rn');
    }

    final effectiveMessage = messageOverride ?? message;
    if (effectiveMessage != null && effectiveMessage.isNotEmpty) {
      final msg = effectiveMessage.length > 60 ? effectiveMessage.substring(0, 60) : effectiveMessage;
      parts.add('MSG:$msg');
    }

    final effectiveVs = variableSymbolOverride ?? variableSymbol;
    if (effectiveVs != null && effectiveVs.isNotEmpty) {
      parts.add('X-VS:$effectiveVs');
    }

    final effectiveKs = constantSymbolOverride ?? constantSymbol;
    if (effectiveKs != null && effectiveKs.isNotEmpty) {
      parts.add('X-KS:$effectiveKs');
    }

    final effectiveSs = specificSymbolOverride ?? specificSymbol;
    if (effectiveSs != null && effectiveSs.isNotEmpty) {
      parts.add('X-SS:$effectiveSs');
    }

    return parts.join('*');
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'iban': iban,
      if (bic != null && bic!.isNotEmpty) 'bic': bic,
      if (recipientName != null && recipientName!.isNotEmpty) 'recipientName': recipientName,
      if (defaultAmount != null) 'defaultAmount': defaultAmount,
      if (message != null && message!.isNotEmpty) 'message': message,
      if (variableSymbol != null && variableSymbol!.isNotEmpty) 'variableSymbol': variableSymbol,
      if (specificSymbol != null && specificSymbol!.isNotEmpty) 'specificSymbol': specificSymbol,
      if (constantSymbol != null && constantSymbol!.isNotEmpty) 'constantSymbol': constantSymbol,
      'requireCustomerConfirmation': requireCustomerConfirmation,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory PaymentProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PaymentProfile(
      id: doc.id,
      name: data['name'] as String,
      iban: data['iban'] as String,
      bic: data['bic'] as String?,
      recipientName: data['recipientName'] as String?,
      defaultAmount: (data['defaultAmount'] as num?)?.toDouble(),
      message: data['message'] as String?,
      variableSymbol: data['variableSymbol'] as String?,
      specificSymbol: data['specificSymbol'] as String?,
      constantSymbol: data['constantSymbol'] as String?,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      requireCustomerConfirmation: data['requireCustomerConfirmation'] as bool? ?? false,
    );
  }
}
