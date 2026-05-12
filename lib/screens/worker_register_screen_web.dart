import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_scan_brackets.dart';

// ignore: unused_element
class WorkerRegisterScreen extends StatelessWidget {
  // onRegistered se na webu nevyvolá — web nepodporuje skenování QR
  // ignore: unused_field
  final VoidCallback onRegistered;
  const WorkerRegisterScreen({super.key, required this.onRegistered});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrace zařízení')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const LogoScanBrackets(size: 64, color: AppColors.label),
              const SizedBox(height: 24),
              const Text(
                'Registrace není dostupná na webu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.heading,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'Stáhněte si mobilní aplikaci a zaregistrujte zařízení tam.',
                style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
