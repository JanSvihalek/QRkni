import 'package:flutter/material.dart';
import '../services/credential_storage.dart';
import '../services/worker_service.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_scan_brackets.dart';
import 'main_screen.dart';

class WorkerLoginScreen extends StatefulWidget {
  final String ownerUserId;
  final String workerName;
  final String pinHash;
  final VoidCallback onUnpaired;

  const WorkerLoginScreen({
    super.key,
    required this.ownerUserId,
    required this.workerName,
    required this.pinHash,
    required this.onUnpaired,
  });

  @override
  State<WorkerLoginScreen> createState() => _WorkerLoginScreenState();
}

class _WorkerLoginScreenState extends State<WorkerLoginScreen> {
  String _pin = '';
  bool _error = false;

  void _onDigit(String d) {
    if (_pin.length >= 6) return;
    setState(() {
      _pin += d;
      _error = false;
    });
    if (_pin.length == 6) _verify();
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _error = false;
    });
  }

  void _verify() {
    final ok = WorkerService.verifyPin(
      widget.ownerUserId,
      _pin,
      widget.pinHash,
    );
    if (ok) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainScreen(
            userId: widget.ownerUserId,
            isWorkerMode: true,
          ),
        ),
      );
    } else {
      setState(() {
        _pin = '';
        _error = true;
      });
    }
  }

  Future<void> _unpair() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Odregistrovat zařízení?'),
        content: const Text(
            'Toto zařízení přestane být spárováno s brigádnickým účtem. Pro opětovné použití bude nutné naskenovat QR kód znovu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Odregistrovat'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await CredentialStorage().unpairWorkerDevice();
      widget.onUnpaired();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(),
              const LogoScanBrackets(size: 60),
              const SizedBox(height: 20),
              Text(
                widget.workerName,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Brigádnický přístup',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 40),
              // PIN tečky
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error
                          ? AppColors.danger
                          : filled
                              ? AppColors.primaryBlue
                              : AppColors.border,
                    ),
                  );
                }),
              ),
              if (_error) ...[
                const SizedBox(height: 12),
                const Text(
                  'Nesprávný PIN',
                  style: TextStyle(color: AppColors.danger, fontSize: 13),
                ),
              ],
              const SizedBox(height: 40),
              // Numpad
              _buildNumpad(),
              const Spacer(),
              TextButton(
                onPressed: _unpair,
                child: const Text(
                  'Odregistrovat toto zařízení',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        _numpadRow(['1', '2', '3']),
        _numpadRow(['4', '5', '6']),
        _numpadRow(['7', '8', '9']),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            _numpadKey('0'),
            _backspaceKey(),
          ],
        ),
      ],
    );
  }

  Widget _numpadRow(List<String> digits) {
    return Row(children: digits.map(_numpadKey).toList());
  }

  Widget _numpadKey(String digit) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AspectRatio(
          aspectRatio: 1.6,
          child: Material(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onDigit(digit),
              child: Center(
                child: Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w400,
                    color: AppColors.heading,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _backspaceKey() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: AspectRatio(
          aspectRatio: 1.6,
          child: Material(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _onBackspace,
              onLongPress: () => setState(() {
                _pin = '';
                _error = false;
              }),
              child: const Center(
                child: Icon(Icons.backspace_outlined, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
