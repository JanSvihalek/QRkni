import 'package:flutter/material.dart';
import '../models/payment_profile.dart';
import '../services/firestore_service.dart';

class ProfileFormScreen extends StatefulWidget {
  final String userId;
  final FirestoreService firestoreService;
  final PaymentProfile? profile;

  const ProfileFormScreen({
    super.key,
    required this.userId,
    required this.firestoreService,
    this.profile,
  });

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _ibanCtrl;
  late final TextEditingController _bicCtrl;
  late final TextEditingController _recipientCtrl;
  late final TextEditingController _amountCtrl;
  late final TextEditingController _messageCtrl;
  late final TextEditingController _vsCtrl;
  late final TextEditingController _ssCtrl;
  late final TextEditingController _ksCtrl;
  bool _isSaving = false;
  bool _requireCustomerConfirmation = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _ibanCtrl = TextEditingController(text: p?.iban ?? '');
    _bicCtrl = TextEditingController(text: p?.bic ?? '');
    _recipientCtrl = TextEditingController(text: p?.recipientName ?? '');
    _amountCtrl = TextEditingController(
      text: p?.defaultAmount != null ? p!.defaultAmount!.toStringAsFixed(2) : '',
    );
    _messageCtrl = TextEditingController(text: p?.message ?? '');
    _vsCtrl = TextEditingController(text: p?.variableSymbol ?? '');
    _ssCtrl = TextEditingController(text: p?.specificSymbol ?? '');
    _ksCtrl = TextEditingController(text: p?.constantSymbol ?? '');
    _requireCustomerConfirmation = p?.requireCustomerConfirmation ?? false;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ibanCtrl.dispose();
    _bicCtrl.dispose();
    _recipientCtrl.dispose();
    _amountCtrl.dispose();
    _messageCtrl.dispose();
    _vsCtrl.dispose();
    _ssCtrl.dispose();
    _ksCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final profile = PaymentProfile(
        id: widget.profile?.id,
        name: _nameCtrl.text.trim(),
        iban: _ibanCtrl.text.trim().replaceAll(' ', '').toUpperCase(),
        bic: _bicCtrl.text.trim().isNotEmpty ? _bicCtrl.text.trim().toUpperCase() : null,
        recipientName: _recipientCtrl.text.trim().isNotEmpty ? _recipientCtrl.text.trim() : null,
        defaultAmount: _amountCtrl.text.trim().isNotEmpty
            ? double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.'))
            : null,
        message: _messageCtrl.text.trim().isNotEmpty ? _messageCtrl.text.trim() : null,
        variableSymbol: _vsCtrl.text.trim().isNotEmpty ? _vsCtrl.text.trim() : null,
        specificSymbol: _ssCtrl.text.trim().isNotEmpty ? _ssCtrl.text.trim() : null,
        constantSymbol: _ksCtrl.text.trim().isNotEmpty ? _ksCtrl.text.trim() : null,
        createdAt: widget.profile?.createdAt ?? DateTime.now(),
        requireCustomerConfirmation: _requireCustomerConfirmation,
      );

      if (widget.profile == null) {
        await widget.firestoreService.addProfile(widget.userId, profile);
      } else {
        await widget.firestoreService.updateProfile(widget.userId, profile);
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Chyba při ukládání: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.profile == null ? 'Nový profil' : 'Upravit profil'),
        actions: [
          _isSaving
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _save,
                  child: const Text('Uložit'),
                ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SectionLabel('Základní informace'),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Název profilu *',
                hintText: 'např. Stánek č. 1, Kavárna',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Vyplňte název profilu' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _recipientCtrl,
              decoration: const InputDecoration(
                labelText: 'Jméno příjemce',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 24),
            _SectionLabel('Bankovní údaje'),
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
                  return 'Neplatný formát IBAN (začíná CZ a obsahuje 24 znaků)';
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
            const SizedBox(height: 24),
            _SectionLabel('Platební údaje'),
            TextFormField(
              controller: _amountCtrl,
              decoration: const InputDecoration(
                labelText: 'Výchozí částka (Kč)',
                hintText: 'Ponechte prázdné pro zadání při každé platbě',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: 'Kč',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                final amount = double.tryParse(v.trim().replaceAll(',', '.'));
                if (amount == null || amount < 0) return 'Neplatná částka';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageCtrl,
              decoration: const InputDecoration(
                labelText: 'Zpráva pro příjemce',
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
              validator: _symbolValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ksCtrl,
              decoration: const InputDecoration(
                labelText: 'Konstantní symbol',
                prefixIcon: Icon(Icons.tag),
              ),
              keyboardType: TextInputType.number,
              validator: _symbolValidator,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ssCtrl,
              decoration: const InputDecoration(
                labelText: 'Specifický symbol',
                prefixIcon: Icon(Icons.tag),
              ),
              keyboardType: TextInputType.number,
              validator: _symbolValidator,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Chování při platbě'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.how_to_reg_outlined),
              title: const Text('Vyžadovat potvrzení od zákazníka'),
              subtitle: const Text('Po stisknutí Hotovo zákazník potvrdí platbu na displeji'),
              value: _requireCustomerConfirmation,
              onChanged: (v) => setState(() => _requireCustomerConfirmation = v),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(widget.profile == null ? 'Vytvořit profil' : 'Uložit změny'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String? _symbolValidator(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > 10) return 'Max. 10 číslic';
    if (!RegExp(r'^\d+$').hasMatch(v.trim())) return 'Pouze číslice';
    return null;
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
