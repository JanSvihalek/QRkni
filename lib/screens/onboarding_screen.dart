import 'package:flutter/material.dart';
import '../models/payment_profile.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  final String userId;
  const OnboardingScreen({super.key, required this.userId});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firestoreService = FirestoreService();

  final _nameCtrl = TextEditingController();
  final _ibanCtrl = TextEditingController();
  final _bicCtrl = TextEditingController();
  final _recipientCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  final _vsCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ibanCtrl.dispose();
    _bicCtrl.dispose();
    _recipientCtrl.dispose();
    _messageCtrl.dispose();
    _vsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final profile = PaymentProfile(
        name: _nameCtrl.text.trim(),
        iban: _ibanCtrl.text.trim().replaceAll(' ', '').toUpperCase(),
        bic: _bicCtrl.text.trim().isNotEmpty ? _bicCtrl.text.trim().toUpperCase() : null,
        recipientName: _recipientCtrl.text.trim().isNotEmpty ? _recipientCtrl.text.trim() : null,
        message: _messageCtrl.text.trim().isNotEmpty ? _messageCtrl.text.trim() : null,
        variableSymbol: _vsCtrl.text.trim().isNotEmpty ? _vsCtrl.text.trim() : null,
        createdAt: DateTime.now(),
      );
      await _firestoreService.addProfile(widget.userId, profile);
      // _ProfileChecker v main.dart se sám překreslí jakmile Firestore vrátí data
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba: $e')),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              const Icon(Icons.qr_code_2, size: 64, color: AppColors.primaryBlue),
              const SizedBox(height: 16),
              Text(
                'Vítejte!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Nastavte svůj první platební profil.\nZákazníci naskenují QR kód a platba proběhne převodem.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              _Label('Název profilu'),
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  hintText: 'např. Stánek č. 1, Kavárna...',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Vyplňte název' : null,
              ),
              const SizedBox(height: 20),
              _Label('Bankovní účet'),
              TextFormField(
                controller: _ibanCtrl,
                decoration: const InputDecoration(
                  labelText: 'IBAN *',
                  hintText: 'CZ6508000000192000145399',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
                validator: (v) {
                  final iban = v?.trim().replaceAll(' ', '') ?? '';
                  if (iban.isEmpty) return 'Vyplňte IBAN';
                  if (!RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z0-9]{4,30}$').hasMatch(iban)) {
                    return 'Neplatný formát IBAN';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _bicCtrl,
                decoration: const InputDecoration(
                  labelText: 'BIC/SWIFT (volitelné)',
                  hintText: 'GIBACZPX',
                  prefixIcon: Icon(Icons.business_outlined),
                ),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _recipientCtrl,
                decoration: const InputDecoration(
                  labelText: 'Jméno příjemce (volitelné)',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 20),
              _Label('Platební detaily (volitelné)'),
              TextFormField(
                controller: _messageCtrl,
                decoration: const InputDecoration(
                  labelText: 'Zpráva pro plátce',
                  prefixIcon: Icon(Icons.message_outlined),
                ),
                maxLength: 60,
              ),
              const SizedBox(height: 4),
              TextFormField(
                controller: _vsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Variabilní symbol',
                  prefixIcon: Icon(Icons.tag),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (!RegExp(r'^\d{1,10}$').hasMatch(v.trim())) {
                    return 'Max. 10 číslic';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Začít používat', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
