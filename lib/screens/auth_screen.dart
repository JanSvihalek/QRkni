import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/credential_storage.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _credentials = CredentialStorage();
  final _biometric = BiometricService();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _hasStoredCredentials = false;
  bool _biometricAvailable = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initBiometric();
  }

  Future<void> _initBiometric() async {
    final available = await _biometric.isAvailable();
    final hasCreds = await _credentials.hasCredentials();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _hasStoredCredentials = hasCreds;
    });
    if (available && hasCreds && _isLogin) {
      _tryBiometricLogin();
    }
  }

  Future<void> _tryBiometricLogin() async {
    if (_isLoading) return;
    final ok = await _biometric.authenticate(reason: 'Přihlaste se do QRkni');
    if (!ok || !mounted) return;
    final creds = await _credentials.read();
    if (creds == null || !mounted) return;
    setState(() {
      _emailController.text = creds.email;
      _passwordController.text = creds.password;
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthService>().signIn(
            email: creds.email,
            password: creds.password,
          );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      // Pokud heslo selhalo, smažeme stará data — uživatel si změnil heslo apod.
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        await _credentials.clear();
        setState(() => _hasStoredCredentials = false);
      }
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Došlo k chybě: $e';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);

      if (_isLogin) {
        await authService.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await authService.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      }
      // Pokud má uživatel dostupnou biometriku, nabídneme uložení přihlašovacích údajů
      if (_biometricAvailable && mounted) {
        await _offerToSaveCredentials(
          _emailController.text.trim(),
          _passwordController.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Došlo k chybě: ${e.toString()}';
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _offerToSaveCredentials(String email, String password) async {
    final save = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zapamatovat přihlášení?'),
        content: const Text(
          'Můžete se příště přihlásit pomocí Face ID místo psaní e-mailu a hesla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ne'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Zapamatovat'),
          ),
        ],
      ),
    );
    if (save == true) {
      await _credentials.save(email, password);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Uživatel nenalezen.';
      case 'wrong-password':
        return 'Nesprávné heslo.';
      case 'invalid-credential':
        return 'Nesprávné přihlašovací údaje.';
      case 'email-already-in-use':
        return 'Tento e-mail je již registrován.';
      case 'weak-password':
        return 'Heslo je příliš slabé.';
      case 'invalid-email':
        return 'Neplatná e-mailová adresa.';
      default:
        return 'Ověřování se nezdařilo: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isLogin ? 'Přihlášení' : 'Registrace'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.1),
            const Icon(Icons.qr_code_2, size: 64, color: Colors.blue),
            const SizedBox(height: 24),
            Text(
              'QRkni',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _isLogin ? 'Přihlaste se ke svému účtu' : 'Vytvořte nový účet',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            if (_isLogin && _biometricAvailable && _hasStoredCredentials) ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isLoading ? null : _tryBiometricLogin,
                  icon: const Icon(Icons.face),
                  label: const Text('Přihlásit se pomocí Face ID'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('nebo', style: TextStyle(color: Colors.grey)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 16),
            ],
            // Email
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'E-mail',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            // Heslo
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Heslo',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 24),
            // Chybová zpráva
            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            if (_errorMessage != null) const SizedBox(height: 16),
            // Tlačítko
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _authenticate,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isLogin ? 'Přihlásit se' : 'Zaregistrovat se'),
              ),
            ),
            const SizedBox(height: 16),
            // Přepínač Login/Registrace
            TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                      setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                        _emailController.clear();
                        _passwordController.clear();
                      });
                    },
              child: Text(
                _isLogin
                    ? 'Nemáte účet? Zaregistrujte se'
                    : 'Máte už účet? Přihlaste se',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
