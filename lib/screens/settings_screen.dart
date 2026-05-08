import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/credential_storage.dart';
import '../services/firestore_service.dart';
import 'items_screen.dart';
import 'profiles_screen.dart';
import 'transactions_screen.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  const SettingsScreen({super.key, required this.userId});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoBrightness = true;
  bool _flipQr = false;
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    BiometricService().isAvailable().then((available) {
      if (!mounted) return;
      setState(() => _biometricAvailable = available);
    });
    FirestoreService().loadSettings(widget.userId).then((s) {
      if (!mounted) return;
      setState(() {
        _autoBrightness = s['auto_brightness'] as bool? ?? true;
        _flipQr = s['flip_qr'] as bool? ?? false;
        _biometricEnabled = s['biometric_enabled'] as bool? ?? false;
      });
    });
  }

  Future<void> _saveAll() async {
    await FirestoreService().saveSettings(widget.userId, {
      'auto_brightness': _autoBrightness,
      'flip_qr': _flipQr,
      'biometric_enabled': _biometricEnabled,
    });
  }

  Future<void> _setAutoBrightness(bool value) async {
    setState(() => _autoBrightness = value);
    await _saveAll();
  }

  Future<void> _setFlipQr(bool value) async {
    setState(() => _flipQr = value);
    await _saveAll();
  }

  Future<void> _setBiometricEnabled(bool value) async {
    if (value) {
      final ok = await BiometricService()
          .authenticate(reason: 'Potvrďte aktivaci biometriky');
      if (!ok) return;
    } else {
      await CredentialStorage().clear();
    }
    setState(() => _biometricEnabled = value);
    await _saveAll();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        title: const Text('Nastavení'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Účet ────────────────────────────────────────────────────────
          _SectionHeader('Účet'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Icon(
                      Icons.person_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.email ?? '',
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: FirestoreService().getUserData(widget.userId),
                          builder: (context, snapshot) {
                            final createdAt =
                                snapshot.data?['createdAt'] as DateTime?;
                            if (createdAt == null) return const SizedBox.shrink();
                            return Text(
                              'Člen od ${createdAt.day}. ${createdAt.month}. ${createdAt.year}',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Platební nastavení ───────────────────────────────────────────
          _SectionHeader('Platební nastavení'),
          _SettingsTile(
            icon: Icons.account_balance_outlined,
            title: 'Platební profily',
            subtitle: 'Správa IBAN, BIC a platebních údajů',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ProfilesScreen(userId: widget.userId)),
            ),
          ),
          _SettingsTile(
            icon: Icons.fastfood_outlined,
            title: 'Katalog položek',
            subtitle: 'Pivo, klobása a další přednastavené ceny',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => ItemsScreen(userId: widget.userId)),
            ),
          ),

          const SizedBox(height: 24),

          // ── Historie ────────────────────────────────────────────────────
          _SectionHeader('Historie'),
          _SettingsTile(
            icon: Icons.receipt_long_outlined,
            title: 'Historie plateb',
            subtitle: 'Přehled vygenerovaných QR kódů',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => TransactionsScreen(userId: widget.userId)),
            ),
          ),

          const SizedBox(height: 24),

          // ── Aplikace ────────────────────────────────────────────────────
          _SectionHeader('Aplikace'),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: SwitchListTile(
              secondary: Icon(
                Icons.brightness_high_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                'Maximální jas při QR kódu',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Při zobrazení QR kódu zvýší jas obrazovky',
                style: TextStyle(fontSize: 12),
              ),
              value: _autoBrightness,
              onChanged: _setAutoBrightness,
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: SwitchListTile(
              secondary: Icon(
                Icons.screen_rotation_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text(
                'Otočit QR kód',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              subtitle: const Text(
                'Zobrazí QR kód vzhůru nohama — zákazník ho vidí správně',
                style: TextStyle(fontSize: 12),
              ),
              value: _flipQr,
              onChanged: _setFlipQr,
            ),
          ),
          if (_biometricAvailable)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: SwitchListTile(
                secondary: Icon(
                  Icons.fingerprint,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text(
                  'Vyžadovat Face ID při otevření',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: const Text(
                  'Aplikace se po spuštění odemkne biometrikou',
                  style: TextStyle(fontSize: 12),
                ),
                value: _biometricEnabled,
                onChanged: _setBiometricEnabled,
              ),
            ),
          _SettingsTile(
            icon: Icons.logout,
            title: 'Odhlásit se',
            titleColor: Colors.red,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Odhlásit se?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Zrušit'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style:
                          TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Odhlásit'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) await authService.signOut();
            },
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading:
            Icon(icon, color: titleColor ?? Theme.of(context).colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w500, color: titleColor),
        ),
        subtitle: subtitle != null
            ? Text(subtitle!, style: const TextStyle(fontSize: 12))
            : null,
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}
