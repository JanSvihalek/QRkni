import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/credential_storage.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import '../widgets/logo_scan_brackets.dart';
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
      final ok = await BiometricService().authenticate(
        reason: 'Potvrďte aktivaci biometriky',
      );
      if (!ok) return;
    } else {
      await CredentialStorage().clear();
    }
    setState(() => _biometricEnabled = value);
    await _saveAll();
  }

  Future<void> _confirmSignOut(AuthService authService) async {
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
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Odhlásit'),
          ),
        ],
      ),
    );
    if (confirmed == true) await authService.signOut();
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final user = authService.currentUser;

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(title: const Text('Nastavení')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          // ── Účet ────────────────────────────────────────────────────────
          _AccountCard(user: user, userId: widget.userId),

          const SizedBox(height: 32),

          // ── Platební nastavení ───────────────────────────────────────────
          const _SectionHeader('Platební nastavení'),
          _TileGroup(
            children: [
              _NavTile(
                icon: Icons.account_balance_outlined,
                title: 'Platební profily',
                subtitle: 'Správa IBAN, BIC a platebních údajů',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilesScreen(userId: widget.userId),
                  ),
                ),
              ),
              _NavTile(
                icon: Icons.fastfood_outlined,
                title: 'Katalog položek',
                subtitle: 'Pivo, klobása a další přednastavené ceny',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemsScreen(userId: widget.userId),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Historie ────────────────────────────────────────────────────
          const _SectionHeader('Historie'),
          _TileGroup(
            children: [
              _NavTile(
                icon: Icons.receipt_long_outlined,
                title: 'Historie plateb',
                subtitle: 'Přehled vygenerovaných QR kódů',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => TransactionsScreen(userId: widget.userId),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Aplikace ────────────────────────────────────────────────────
          const _SectionHeader('Aplikace'),
          _TileGroup(
            children: [
              _SwitchTile(
                icon: Icons.brightness_high_outlined,
                title: 'Maximální jas při QR kódu',
                subtitle: 'Při zobrazení QR kódu zvýší jas obrazovky',
                value: _autoBrightness,
                onChanged: _setAutoBrightness,
              ),
              _SwitchTile(
                icon: Icons.screen_rotation_outlined,
                title: 'Otočit QR kód',
                subtitle:
                    'Zobrazí QR kód vzhůru nohama — zákazník ho vidí správně',
                value: _flipQr,
                onChanged: _setFlipQr,
              ),
              if (_biometricAvailable)
                _SwitchTile(
                  icon: Icons.fingerprint,
                  title: 'Vyžadovat Face ID při otevření',
                  subtitle: 'Aplikace se po spuštění odemkne biometrikou',
                  value: _biometricEnabled,
                  onChanged: _setBiometricEnabled,
                ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Odhlášení ───────────────────────────────────────────────────
          _SignOutButton(onPressed: () => _confirmSignOut(authService)),

          const SizedBox(height: 40),

          // ── Footer s logem ──────────────────────────────────────────────
          const Center(
            child: Column(
              children: [
                LogoScanBrackets(size: 36, color: AppColors.label),
                SizedBox(height: 10),
                Text(
                  'QRkni',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: AppColors.muted,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'v2.3.6',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.label,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Components
// ──────────────────────────────────────────────────────────────────────────────

class _AccountCard extends StatelessWidget {
  final dynamic user;
  final String userId;
  const _AccountCard({required this.user, required this.userId});

  @override
  Widget build(BuildContext context) {
    final email = user?.email as String? ?? '';
    final initials = _initialsFromEmail(email);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primaryHover, AppColors.primaryBlue],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.heading,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                FutureBuilder<Map<String, dynamic>?>(
                  future: FirestoreService().getUserData(userId),
                  builder: (context, snapshot) {
                    final createdAt = snapshot.data?['createdAt'] as DateTime?;
                    if (createdAt == null) return const SizedBox.shrink();
                    return Text(
                      'Člen od ${createdAt.day}. ${createdAt.month}. ${createdAt.year}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _initialsFromEmail(String email) {
    if (email.isEmpty) return '?';
    final localPart = email.split('@').first;
    final cleaned = localPart.replaceAll(RegExp(r'[^a-zA-Z]'), '');
    if (cleaned.isEmpty) return localPart.substring(0, 1).toUpperCase();
    if (cleaned.length == 1) return cleaned.toUpperCase();
    return cleaned.substring(0, 2).toUpperCase();
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Skupina dlaždic pohromadě v jednom bordered kontejneru s dělícími čárami.
class _TileGroup extends StatelessWidget {
  final List<Widget> children;
  const _TileGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) const Divider(height: 1, indent: 60),
          ],
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            _IconBubble(icon: icon),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.heading,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.label, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconBubble(icon: icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.heading,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _IconBubble extends StatelessWidget {
  final IconData icon;
  const _IconBubble({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 18, color: AppColors.primaryBlue),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _SignOutButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.logout, size: 18, color: AppColors.danger),
        label: const Text(
          'Odhlásit se',
          style: TextStyle(
            color: AppColors.danger,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border, width: 1.5),
          ),
        ),
      ),
    );
  }
}
