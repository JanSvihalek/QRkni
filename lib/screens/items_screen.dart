import 'package:flutter/material.dart';
import '../models/payment_item.dart';
import '../services/firestore_service.dart';
import '../theme/app_theme.dart';
import 'item_form_screen.dart';

class ItemsScreen extends StatelessWidget {
  final String userId;
  const ItemsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final service = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Katalog položek')),
      body: StreamBuilder<List<PaymentItem>>(
        stream: service.itemsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fastfood_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Žádné položky', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  const Text(
                    'Přidejte položky jako Pivo, Klobása...',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final item = items[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${item.price.toStringAsFixed(2).replaceAll('.', ',')} Kč',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ItemFormScreen(
                              userId: userId,
                              item: item,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.danger),
                        onPressed: () => _confirmDelete(context, service, item),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => ItemFormScreen(userId: userId)),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nová položka'),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FirestoreService service,
    PaymentItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat položku?'),
        content: Text('Opravdu smazat "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
    if (confirmed == true && item.id != null) {
      await service.deleteItem(userId, item.id!);
    }
  }
}
