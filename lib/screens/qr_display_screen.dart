import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_profile.dart';
import '../models/payment_transaction.dart';
import '../services/firestore_service.dart';

class QrDisplayScreen extends StatefulWidget {
  final String userId;
  final PaymentProfile profile;
  final double amount;
  final List<TransactionItem> items;

  const QrDisplayScreen({
    super.key,
    required this.userId,
    required this.profile,
    required this.amount,
    this.items = const [],
  });

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) _applyBrightness();
  }

  Future<void> _applyBrightness() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('auto_brightness') ?? true) {
      await ScreenBrightness().setScreenBrightness(1.0);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) ScreenBrightness().resetScreenBrightness();
    super.dispose();
  }

  String get _qrData => widget.profile.toSpaydString(amount: widget.amount);

  String get _formattedAmount =>
      '${widget.amount.toStringAsFixed(2).replaceAll('.', ',')} Kč';

  Future<void> _markPaid() async {
    setState(() => _saving = true);
    try {
      await FirestoreService().addTransaction(
        widget.userId,
        PaymentTransaction(
          profileId: widget.profile.id ?? '',
          profileName: widget.profile.name,
          amount: widget.amount,
          items: widget.items,
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('addTransaction error: $e');
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Chyba: $e')));
      }
    }
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
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          widget.profile.name,
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
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            // ── QR kód ────────────────────────────────────────────────────
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

            // ── Částka, info a tlačítko ───────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 16, 32, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
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
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _formatIban(widget.profile.iban),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (widget.profile.recipientName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      widget.profile.recipientName!,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _saving ? null : _markPaid,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.check_circle_outline),
                    label: Text(_saving ? 'Ukládám…' : 'Hotovo/Zaplaceno'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      backgroundColor: Colors.green.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
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
