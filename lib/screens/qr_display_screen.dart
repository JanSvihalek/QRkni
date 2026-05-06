import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/payment_profile.dart';

class QrDisplayScreen extends StatelessWidget {
  final PaymentProfile profile;
  final double amount;

  const QrDisplayScreen({
    super.key,
    required this.profile,
    required this.amount,
  });

  String get _qrData => profile.toSpaydString(amount: amount);

  String get _formattedAmount {
    final s = amount.toStringAsFixed(2).replaceAll('.', ',');
    return '$s Kč';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          profile.name,
          style: const TextStyle(fontSize: 16, color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Text(
                'Otevřete svou bankovní aplikaci a naskenujte QR kód',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),

            // ── QR kód — zabere většinu obrazovky ──────────────────────────
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth * 0.85
                      : constraints.maxHeight * 0.85;
                  return Center(
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: size,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                      errorStateBuilder: (_, e) => const Center(
                        child: Text(
                          'Chyba generování QR.\nZkontrolujte IBAN.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // ── Částka a info dole ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey.shade100, width: 1)),
              ),
              child: Column(
                children: [
                  Text(
                    _formattedAmount,
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatIban(profile.iban),
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  if (profile.recipientName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      profile.recipientName!,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatIban(String iban) =>
      iban.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim();
}
