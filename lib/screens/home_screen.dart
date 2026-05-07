import 'package:flutter/material.dart';
import '../models/payment_item.dart';
import '../models/payment_profile.dart';
import '../models/payment_transaction.dart';
import '../services/firestore_service.dart';
import 'items_screen.dart';
import 'profiles_screen.dart';
import 'qr_display_screen.dart';

// Položka v košíku
class _CartEntry {
  final PaymentItem item;
  int quantity = 1;
  _CartEntry({required this.item});
}

class HomeScreen extends StatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _firestoreService = FirestoreService();
  String? _selectedProfileId;

  // Manuální vstup přes klávesnici
  String _input = '0';

  // Košík
  final List<_CartEntry> _cart = [];

  // ── Košík ────────────────────────────────────────────────────────────────

  void _addToCart(PaymentItem item) {
    setState(() {
      final existing = _cart.where((e) => e.item.id == item.id).firstOrNull;
      if (existing != null) {
        existing.quantity++;
      } else {
        _cart.add(_CartEntry(item: item));
      }
    });
  }

  void _removeFromCart(String itemId) {
    setState(() {
      final entry = _cart.where((e) => e.item.id == itemId).firstOrNull;
      if (entry == null) return;
      if (entry.quantity > 1) {
        entry.quantity--;
      } else {
        _cart.removeWhere((e) => e.item.id == itemId);
      }
    });
  }

  void _clearCart() => setState(() => _cart.clear());

  double get _cartTotal =>
      _cart.fold(0, (sum, e) => sum + e.item.price * e.quantity);

  bool get _hasCart => _cart.isNotEmpty;

  // ── Klávesnice ────────────────────────────────────────────────────────────

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

  double? get _manualAmount {
    final v = double.tryParse(_input.replaceAll(',', '.'));
    return (v != null && v > 0) ? v : null;
  }

  double? get _finalAmount => _hasCart ? _cartTotal : _manualAmount;

  // ── Picker položek ────────────────────────────────────────────────────────

  void _showItemsPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          maxChildSize: 0.9,
          builder: (_, controller) => Column(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    const Text(
                      'Přidat položku',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemsScreen(userId: widget.userId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.settings_outlined, size: 18),
                      label: const Text('Spravovat'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: StreamBuilder<List<PaymentItem>>(
                  stream: _firestoreService.itemsStream(widget.userId),
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fastfood_outlined,
                                size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('Žádné položky v katalogu',
                                style: TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ItemsScreen(userId: widget.userId),
                                  ),
                                );
                              },
                              child: const Text('Přidat položky do katalogu'),
                            ),
                          ],
                        ),
                      );
                    }
                    return ListView.builder(
                      controller: controller,
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final item = items[i];
                        final cartEntry = _cart
                            .where((e) => e.item.id == item.id)
                            .firstOrNull;
                        final qty = cartEntry?.quantity ?? 0;

                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.price.toStringAsFixed(2).replaceAll('.', ',')} Kč',
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (qty > 0) ...[
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    _removeFromCart(item.id!);
                                    setSheetState(() {});
                                  },
                                ),
                                Text(
                                  '$qty',
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                              ],
                              IconButton(
                                icon: Icon(
                                  Icons.add_circle_outline,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                onPressed: () {
                                  _addToCart(item);
                                  setSheetState(() {});
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_hasCart)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: FilledButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: Text(
                      'Hotovo — celkem ${_cartTotal.toStringAsFixed(2).replaceAll('.', ',')} Kč',
                    ),
                  ),
                ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  // ── Profil switcher ───────────────────────────────────────────────────────

  void _showProfilePicker(
      BuildContext context, List<PaymentProfile> profiles, PaymentProfile selected) {
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Vybrat profil',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          ),
          ...profiles.map((p) => ListTile(
                leading: const Icon(Icons.account_balance_outlined),
                title: Text(p.name),
                subtitle: Text(_formatIban(p.iban),
                    style: const TextStyle(fontSize: 12)),
                trailing: p.id == selected.id
                    ? Icon(Icons.check,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _selectedProfileId = p.id);
                  Navigator.pop(ctx);
                },
              )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tune),
            title: const Text('Spravovat profily'),
            onTap: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProfilesScreen(userId: widget.userId)),
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
        PaymentProfile? selected;
        if (profiles.isNotEmpty) {
          selected = profiles.firstWhere(
            (p) => p.id == _selectedProfileId,
            orElse: () => profiles.first,
          );
        }

        final amount = _finalAmount;
        final displayText = _hasCart
            ? '${_cartTotal.toStringAsFixed(2).replaceAll('.', ',')} Kč'
            : '$_input Kč';

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            title: selected != null
                ? GestureDetector(
                    onTap: () =>
                        _showProfilePicker(context, profiles, selected!),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(selected.name,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        const Icon(Icons.expand_more, size: 20),
                      ],
                    ),
                  )
                : const Text('QR platby'),
            centerTitle: true,
            actions: const [],
          ),
          body: Column(
            children: [
              // ── Displej ──────────────────────────────────────────────────
              Expanded(
                child: Center(
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.w300,
                          color: amount != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Košík ─────────────────────────────────────────────────────
              if (_hasCart)
                Container(
                  constraints: const BoxConstraints(maxHeight: 160),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          shrinkWrap: true,
                          itemCount: _cart.length,
                          itemBuilder: (_, i) {
                            final entry = _cart[i];
                            return Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${entry.item.name} ×${entry.quantity}',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                                Text(
                                  '${(entry.item.price * entry.quantity).toStringAsFixed(2).replaceAll('.', ',')} Kč',
                                  style: const TextStyle(fontSize: 14),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 16),
                                  onPressed: () =>
                                      _removeFromCart(entry.item.id!),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 32, minHeight: 32),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: _clearCart,
                              icon: const Icon(Icons.delete_outline, size: 16),
                              label: const Text('Vymazat košík',
                                  style: TextStyle(fontSize: 12)),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  padding: EdgeInsets.zero),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // ── Klávesnice nebo placeholder ───────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                      if (!_hasCart) ...[
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
                            _NumpadKey(
                                label: '0', onTap: () => _onDigit('0')),
                            _NumpadKey(
                              icon: Icons.backspace_outlined,
                              onTap: _onBackspace,
                              onLongPress: () =>
                                  setState(() => _input = '0'),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: selected != null && amount != null
                            ? () async {
                                final paid = await Navigator.push<bool>(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => QrDisplayScreen(
                                      userId: widget.userId,
                                      profile: selected!,
                                      amount: amount,
                                      items: _cart
                                          .map((e) => TransactionItem(
                                                name: e.item.name,
                                                price: e.item.price,
                                                quantity: e.quantity,
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                );
                                if (paid == true) {
                                  _clearCart();
                                  setState(() => _input = '0');
                                }
                              }
                            : null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.qr_code_2),
                            SizedBox(width: 10),
                            Text('Generovat QR kód',
                                style: TextStyle(fontSize: 17)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () => _showItemsPicker(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Přidat položku'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ── Pomocné widgety klávesnice ───────────────────────────────────────────────

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
