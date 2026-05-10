import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'models/payment_profile.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'screens/auth_screen.dart';
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
    final base = ThemeData.light();
    final baseText = base.textTheme;
    final textTheme = GoogleFonts.jetBrainsMonoTextTheme(baseText).copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(textStyle: baseText.displayLarge),
      displayMedium: GoogleFonts.spaceGrotesk(textStyle: baseText.displayMedium),
      displaySmall: GoogleFonts.spaceGrotesk(textStyle: baseText.displaySmall),
      headlineLarge: GoogleFonts.spaceGrotesk(textStyle: baseText.headlineLarge),
      headlineMedium:
          GoogleFonts.spaceGrotesk(textStyle: baseText.headlineMedium),
      headlineSmall: GoogleFonts.spaceGrotesk(textStyle: baseText.headlineSmall),
      titleLarge: GoogleFonts.spaceGrotesk(textStyle: baseText.titleLarge),
    );

    return Provider<AuthService>(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'QR kódy na platby',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.light,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
          textTheme: textTheme,
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

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) return const AuthScreen();
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
