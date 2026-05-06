import 'package:flutter/material.dart';
import '../models/payment_profile.dart';
import '../services/firestore_service.dart';
import 'profile_form_screen.dart';

class ProfilesScreen extends StatelessWidget {
  final String userId;
  const ProfilesScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(title: const Text('Platební profily')),
      body: StreamBuilder<List<PaymentProfile>>(
        stream: firestoreService.profilesStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final profiles = snapshot.data ?? [];

          if (profiles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.account_balance_outlined, size: 64, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  const Text('Žádné profily', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: profiles.length,
            itemBuilder: (context, index) {
              final profile = profiles[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.account_balance_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(
                    profile.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    _formatIban(profile.iban),
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileFormScreen(
                              userId: userId,
                              firestoreService: firestoreService,
                              profile: profile,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _confirmDelete(context, firestoreService, profile),
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
          MaterialPageRoute(
            builder: (_) => ProfileFormScreen(
              userId: userId,
              firestoreService: FirestoreService(),
            ),
          ),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Nový profil'),
      ),
    );
  }

  String _formatIban(String iban) =>
      iban.replaceAllMapped(RegExp(r'.{4}'), (m) => '${m.group(0)} ').trim();

  Future<void> _confirmDelete(
    BuildContext context,
    FirestoreService service,
    PaymentProfile profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat profil?'),
        content: Text('Opravdu chcete smazat "${profile.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
    if (confirmed == true && profile.id != null) {
      await service.deleteProfile(userId, profile.id!);
    }
  }
}
