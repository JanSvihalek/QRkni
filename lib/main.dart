import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/payment_profile.dart';
import 'services/auth_service.dart';
import 'services/credential_storage.dart';
import 'services/firestore_service.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/worker_login_screen.dart';
import 'theme/app_theme.dart';

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
        title: 'QRkni',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: buildAppTheme(),
        home: const _AppEntry(),
      ),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool? _isWorkerDevice;
  String? _workerOwnerId;
  String? _workerName;
  String? _workerPinHash;
  String? _startupCheckError;

  @override
  void initState() {
    super.initState();
    _checkWorkerDevice();
  }

  Future<void> _checkWorkerDevice() async {
    final storage = CredentialStorage();
    final isWorker = await storage.isWorkerDevice();
    if (isWorker) {
      final ownerId = await storage.getWorkerOwnerId();
      final name = await storage.getWorkerName();
      final pinHash = await storage.getWorkerPinHash();
      if (FirebaseAuth.instance.currentUser == null) {
        try {
          await FirebaseAuth.instance
              .signInAnonymously()
              .timeout(const Duration(seconds: 10));
        } catch (_) {
          // Pokračujeme i bez sítě — brigádník uvidí PIN obrazovku,
          // Firestore se připojí po obnovení připojení.
        }
      }

      // Pokud je síť k dispozici, ověříme že vlastník brigádníka nesmazal
      if (ownerId != null && pinHash != null) {
        try {
          final exists = await FirestoreService()
              .workerExistsByPinHash(ownerId, pinHash)
              .timeout(const Duration(seconds: 5));
          if (!exists) {
            await storage.unpairWorkerDevice();
            await FirebaseAuth.instance.signOut();
            if (mounted) setState(() => _isWorkerDevice = false);
            return;
          }
        } catch (e) {
          _startupCheckError = '$e';
          // Offline — přeskočíme, kontrola proběhne při zadání PINu
        }
      }

      if (mounted) {
        setState(() {
          _isWorkerDevice = true;
          _workerOwnerId = ownerId;
          _workerName = name;
          _workerPinHash = pinHash;
        });
      }
    } else {
      if (mounted) setState(() => _isWorkerDevice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isWorkerDevice == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isWorkerDevice! &&
        _workerOwnerId != null &&
        _workerName != null &&
        _workerPinHash != null) {
      return WorkerLoginScreen(
        ownerUserId: _workerOwnerId!,
        workerName: _workerName!,
        pinHash: _workerPinHash!,
        onUnpaired: _checkWorkerDevice,
        startupError: _startupCheckError,
      );
    }

    final authService = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) {
          return AuthScreen(onWorkerRegistered: _checkWorkerDevice);
        }
        return _ProfileChecker(userId: snapshot.data!.uid);
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
        if (!snapshot.hasData &&
            snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
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
