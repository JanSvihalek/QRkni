import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';

class LockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const LockScreen({super.key, required this.onUnlocked});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> {
  final _biometric = BiometricService();
  bool _authenticating = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryAuthenticate());
  }

  Future<void> _tryAuthenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _failed = false;
    });
    final ok = await _biometric.authenticate(reason: 'Odemkněte aplikaci QRkni');
    if (!mounted) return;
    if (ok) {
      widget.onUnlocked();
    } else {
      setState(() {
        _authenticating = false;
        _failed = true;
      });
    }
  }

  Future<void> _signOut() async {
    await context.read<AuthService>().signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.lock_outline,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                const Text(
                  'QRkni je zamčeno',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  _failed
                      ? 'Ověření se nezdařilo. Zkuste to znovu.'
                      : 'Pro odemčení použijte Face ID',
                  style: TextStyle(color: Colors.grey.shade700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                FilledButton.icon(
                  onPressed: _authenticating ? null : _tryAuthenticate,
                  icon: const Icon(Icons.face),
                  label: Text(_authenticating ? 'Ověřuji…' : 'Odemknout pomocí Face ID'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _signOut,
                  child: const Text('Odhlásit se'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
