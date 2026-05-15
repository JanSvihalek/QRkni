import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screen_brightness/screen_brightness.dart';
import '../models/payment_profile.dart';
import '../models/payment_transaction.dart';
import '../services/firestore_service.dart';

class QrDisplayScreen extends StatefulWidget {
  final String userId;
  final PaymentProfile profile;
  final double amount;
  final List<TransactionItem> items;
  final String? customMessage;
  final String? customVariableSymbol;
  final String? customConstantSymbol;
  final String? customSpecificSymbol;
  final String? createdBy;

  const QrDisplayScreen({
    super.key,
    required this.userId,
    required this.profile,
    required this.amount,
    this.items = const [],
    this.customMessage,
    this.customVariableSymbol,
    this.customConstantSymbol,
    this.customSpecificSymbol,
    this.createdBy,
  });

  @override
  State<QrDisplayScreen> createState() => _QrDisplayScreenState();
}

class _QrDisplayScreenState extends State<QrDisplayScreen> {
  bool _saving = false;
  bool _flipQr = false;
  bool _awaitingConfirmation = false;
  bool _confirmed = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await FirestoreService().loadSettings(widget.userId);
    if (!kIsWeb && (settings['auto_brightness'] as bool? ?? true)) {
      await ScreenBrightness().setScreenBrightness(1.0);
    }
    if (mounted) setState(() => _flipQr = settings['flip_qr'] as bool? ?? false);
  }

  @override
  void dispose() {
    if (!kIsWeb) ScreenBrightness().resetScreenBrightness();
    super.dispose();
  }

  String get _qrData => widget.profile.toSpaydString(
        amount: widget.amount,
        messageOverride: widget.customMessage,
        variableSymbolOverride: widget.customVariableSymbol,
        constantSymbolOverride: widget.customConstantSymbol,
        specificSymbolOverride: widget.customSpecificSymbol,
      );

  String get _formattedAmount =>
      '${widget.amount.toStringAsFixed(2).replaceAll('.', ',')} Kč';

  void _onHotovo() {
    if (widget.profile.requireCustomerConfirmation) {
      setState(() => _awaitingConfirmation = true);
    } else {
      _markPaid();
    }
  }

  Future<void> _onCustomerConfirmed() async {
    setState(() => _confirmed = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    await _markPaid();
  }

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
          createdBy: widget.createdBy,
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('addTransaction error: $e');
      if (mounted) {
        setState(() { _saving = false; _confirmed = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Chyba: $e')));
      }
    }
  }

  Widget _buildCustomerConfirmView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.payment_outlined, size: 64, color: Colors.black45),
        const SizedBox(height: 20),
        const Text(
          'Zaplatil/a jsi?',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _formattedAmount,
          style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, letterSpacing: -1),
        ),
        const SizedBox(height: 36),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: FilledButton.icon(
            onPressed: _onCustomerConfirmed,
            icon: const Icon(Icons.check_circle_outline, size: 24),
            label: const Text('Ano, zaplatil/a jsem', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 64),
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.check_circle, size: 96, color: Colors.green),
        const SizedBox(height: 20),
        const Text(
          'Platba potvrzena!',
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          _formattedAmount,
          style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.green.shade700, letterSpacing: -1),
        ),
      ],
    );
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
            // ── Zákazníkova část (volitelně otočená) ──────────────────────
            Expanded(
              child: RotatedBox(
                quarterTurns: _flipQr ? 2 : 0,
                child: _awaitingConfirmation
                    ? (_confirmed ? _buildSuccessView() : _buildCustomerConfirmView())
                    : Column(
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
                          // ── Částka a IBAN (zákazníkova část) ──────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 12, 32, 16),
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
                                      horizontal: 10, vertical: 4),
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
                                        fontSize: 13, color: Colors.grey.shade500),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            // ── Prodejcova část (vždy normální orientace) ─────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100, width: 1),
                ),
              ),
              child: _awaitingConfirmation
                  ? OutlinedButton.icon(
                      onPressed: _confirmed || _saving
                          ? null
                          : () => setState(() => _awaitingConfirmation = false),
                      icon: const Icon(Icons.qr_code_2),
                      label: const Text('Zpět na QR kód'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: _saving ? null : _onHotovo,
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Hotovo/Zaplaceno'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(double.infinity, 52),
                        backgroundColor: Colors.green.shade600,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
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
