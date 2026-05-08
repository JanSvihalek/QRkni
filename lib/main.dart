import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/payment_profile.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'services/biometric_service.dart';
import 'screens/auth_screen.dart';
import 'screens/lock_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'QR kódy na platby',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          ),
        ),
        home: const _AuthWrapper(),
      ),
    );
  }
}

class _AuthWrapper extends StatefulWidget {
  const _AuthWrapper();

  @override
  State<_AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<_AuthWrapper> {
  String? _unlockedFor;

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final user = snapshot.data;
        if (user == null) {
          _unlockedFor = null;
          return const AuthScreen();
        }
        if (_unlockedFor == user.uid) {
          return _ProfileChecker(userId: user.uid);
        }
        return _BiometricGate(
          userId: user.uid,
          onUnlocked: () => setState(() => _unlockedFor = user.uid),
        );
      },
    );
  }
}

class _BiometricGate extends StatefulWidget {
  final String userId;
  final VoidCallback onUnlocked;
  const _BiometricGate({required this.userId, required this.onUnlocked});

  @override
  State<_BiometricGate> createState() => _BiometricGateState();
}

class _BiometricGateState extends State<_BiometricGate> {
  late final Future<bool> _shouldLock;

  @override
  void initState() {
    super.initState();
    _shouldLock = _decideLock();
  }

  Future<bool> _decideLock() async {
    final settings = await FirestoreService().loadSettings(widget.userId);
    final enabled = settings['biometric_enabled'] as bool? ?? false;
    if (!enabled) return false;
    return BiometricService().isAvailable();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldLock,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == true) {
          return LockScreen(onUnlocked: widget.onUnlocked);
        }
        WidgetsBinding.instance.addPostFrameCallback((_) => widget.onUnlocked());
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}

class _ProfileChecker extends StatelessWidget {
  final String userId;
  const _ProfileChecker({required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentProfile>>(
      stream: FirestoreService().profilesStream(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final profiles = snapshot.data ?? [];
        if (profiles.isEmpty) {
          return OnboardingScreen(userId: userId);
        }
        return MainScreen(userId: userId);
      },
    );
  }
}
