import 'package:flutter/material.dart';
import '../models/payment_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'profiles_screen.dart';
import 'qr_display_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  String? _selectedProfileId;
  String _input = '0';

  // ── Numpad logika ────────────────────────────────────────────────────────

  void _onDigit(String d) {
    setState(() {
      if (_input == '0') {
        _input = d;
      } else {
        final commaIdx = _input.indexOf(',');
        if (commaIdx != -1 && (_input.length - commaIdx) > 2) return;
        _input += d;
      }
    });
  }

  void _onComma() {
    if (_input.contains(',')) return;
    setState(() => _input += ',');
  }

  void _onBackspace() {
    setState(() {
      if (_input.length <= 1) {
        _input = '0';
      } else {
        _input = _input.substring(0, _input.length - 1);
        if (_input.endsWith(',')) _input = _input.substring(0, _input.length - 1);
      }
    });
  }

  double? get _parsedAmount {
    final s = _input.replaceAll(',', '.');
    final v = double.tryParse(s);
    return (v != null && v > 0) ? v : null;
  }

  // ── Výběr profilu ────────────────────────────────────────────────────────

  void _showProfilePicker(
    BuildContext context,
    List<PaymentProfile> profiles,
    PaymentProfile selected,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Vybrat profil',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
          ),
          ...profiles.map(
            (p) => ListTile(
              leading: const Icon(Icons.account_balance_outlined),
              title: Text(p.name),
              subtitle: Text(
                _formatIban(p.iban),
                style: const TextStyle(fontSize: 12),
              ),
              trailing: p.id == selected.id
                  ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                  : null,
              onTap: () {
                setState(() => _selectedProfileId = p.id);
                Navigator.pop(ctx);
              },
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Spravovat profily'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfilesScreen(userId: widget.userId),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatIban(String iban) =>
      iban.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim();

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentProfile>>(
      stream: _firestoreService.profilesStream(widget.userId),
      builder: (context, snapshot) {
        final profiles = snapshot.data ?? [];

        // Udržuj vybraný profil platný i po smazání
        PaymentProfile? selected;
        if (profiles.isNotEmpty) {
          selected = profiles.firstWhere(
            (p) => p.id == _selectedProfileId,
            orElse: () => profiles.first,
          );
        }

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            title: selected != null
                ? GestureDetector(
                    onTap: () => _showProfilePicker(context, profiles, selected!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          selected.name,
                          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, size: 20),
                      ],
                    ),
                  )
                : const Text('QR platby'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                tooltip: 'Spravovat profily',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilesScreen(userId: widget.userId),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Odhlásit se',
                onPressed: () => context.read<AuthService>().signOut(),
              ),
            ],
          ),
          body: Column(
            children: [
              // ── Displej částky ──────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FittedBox(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            '$_input Kč',
                            style: TextStyle(
                              fontSize: 56,
                              fontWeight: FontWeight.w300,
                              color: _parsedAmount != null
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      if (selected?.recipientName != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            selected!.recipientName!,
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // ── Číselná klávesnice ──────────────────────────────────────
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _NumpadRow(labels: ['1', '2', '3'], onTap: _onDigit),
                      _NumpadRow(labels: ['4', '5', '6'], onTap: _onDigit),
                      _NumpadRow(labels: ['7', '8', '9'], onTap: _onDigit),
                      Row(
                        children: [
                          _NumpadKey(
                            label: ',',
                            onTap: _onComma,
                            enabled: !_input.contains(','),
                          ),
                          _NumpadKey(label: '0', onTap: () => _onDigit('0')),
                          _NumpadKey(
                            icon: Icons.backspace_outlined,
                            onTap: _onBackspace,
                            onLongPress: () => setState(() => _input = '0'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: selected != null && _parsedAmount != null
                            ? () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QrDisplayScreen(
                                      profile: selected!,
                                      amount: _parsedAmount!,
                                    ),
                                  ),
                                )
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2),
                            SizedBox(width: 10),
                            Text('Generovat QR kód', style: TextStyle(fontSize: 17)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Pomocné widgety ──────────────────────────────────────────────────────────

class _NumpadRow extends StatelessWidget {
  final List<String> labels;
  final void Function(String) onTap;

  const _NumpadRow({required this.labels, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: labels.map((l) => _NumpadKey(label: l, onTap: () => onTap(l))).toList(),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool enabled;

  const _NumpadKey({
    this.label,
    this.icon,
    required this.onTap,
    this.onLongPress,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AspectRatio(
          aspectRatio: 1.6,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: enabled ? onTap : null,
              onLongPress: onLongPress,
              child: Center(
                child: icon != null
                    ? Icon(icon, size: 24)
                    : Text(
                        label!,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w400,
                          color: enabled
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey.shade400,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
