import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/credential_storage.dart';
import '../theme/app_theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  static const _primaryBlue = AppColors.primaryBlue;
  static const _headingColor = AppColors.heading;
  static const _mutedText = AppColors.muted;
  static const _labelColor = AppColors.label;
  static const _borderColor = AppColors.border;
  static const _fieldFill = AppColors.surface;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _credentials = CredentialStorage();
  final _biometric = BiometricService();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _hasStoredCredentials = false;
  bool _biometricAvailable = false;
  bool _passwordVisible = false;
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

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await context.read<AuthService>().signInWithGoogle();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() => _errorMessage = _getErrorMessage(e.code));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Přihlášení přes Google se nezdařilo.');
      }
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

  Future<void> _showForgotPasswordDialog() async {
    final controller = TextEditingController(
      text: _emailController.text.trim(),
    );
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Obnovit heslo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Zadejte svůj e-mail a pošleme vám odkaz pro obnovení hesla.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Odeslat'),
          ),
        ],
      ),
    );
    if (email == null || email.isEmpty || !mounted) return;
    try {
      await context.read<AuthService>().resetPassword(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Odkaz pro obnovení byl odeslán.')),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getErrorMessage(e.code))),
      );
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

  InputDecoration _fieldDecoration({String? hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(color: _labelColor),
      filled: true,
      fillColor: _fieldFill,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: _labelColor,
        ),
      ),
    );
  }

  Widget _socialButton({
    required Widget child,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: SizedBox(
        height: 56,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: Colors.white,
            side: const BorderSide(color: _borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _googleIcon() {
    return Image.asset(
      'assets/images/google_logo.png',
      width: 22,
      height: 22,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showFaceId = _biometricAvailable && _isLogin;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo + název
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      border: Border.all(color: _primaryBlue, width: 3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'QRkni',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _headingColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              Text(
                _isLogin ? 'Vítej zpátky' : 'Vytvoř si účet',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _headingColor,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Plať přes QR kód bez poplatků'
                'Bez sdílení bankovního účtu s ostatními.',
                style: TextStyle(
                  fontSize: 15,
                  color: _mutedText,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),

              _fieldLabel('E-MAIL'),
              TextField(
                controller: _emailController,
                decoration: _fieldDecoration(hintText: 'jana@stanek.cz'),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 20),

              _fieldLabel('HESLO'),
              TextField(
                controller: _passwordController,
                decoration: _fieldDecoration().copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: _labelColor,
                    ),
                    onPressed: () => setState(
                      () => _passwordVisible = !_passwordVisible,
                    ),
                  ),
                ),
                obscureText: !_passwordVisible,
                enabled: !_isLoading,
              ),

              if (_isLogin)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _isLoading ? null : _showForgotPasswordDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 8,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: _primaryBlue,
                    ),
                    child: const Text(
                      'Zapomenuté heslo?',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                )
              else
                const SizedBox(height: 16),

              if (_errorMessage != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              ],
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isLogin ? 'Přihlásit se' : 'Zaregistrovat se'),
                ),
              ),

              const SizedBox(height: 24),
              const Row(
                children: [
                  Expanded(child: Divider(color: _borderColor)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'NEBO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.8,
                        color: _labelColor,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: _borderColor)),
                ],
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  _socialButton(
                    onPressed: _isLoading ? null : _signInWithGoogle,
                    child: _googleIcon(),
                  ),
                  if (showFaceId) ...[
                    const SizedBox(width: 12),
                    _socialButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_hasStoredCredentials) {
                                _tryBiometricLogin();
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Nejdřív se přihlas e-mailem — pak budeš moct používat Face ID.',
                                    ),
                                  ),
                                );
                              }
                            },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.face_outlined,
                            color: _primaryBlue,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Face ID',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _headingColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 32),
              Center(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _isLogin ? 'Nemáš účet? ' : 'Máš už účet? ',
                      style: const TextStyle(color: _mutedText),
                    ),
                    GestureDetector(
                      onTap: _isLoading
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
                        _isLogin ? 'Vytvoř si ho' : 'Přihlas se',
                        style: const TextStyle(
                          color: _primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
