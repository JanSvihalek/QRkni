import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/subscription.dart';
import '../models/worker.dart';
import '../services/firestore_service.dart';
import '../services/subscription_service.dart';
import '../services/worker_service.dart';
import '../theme/app_theme.dart';

class WorkersScreen extends StatelessWidget {
  final String userId;
  const WorkersScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Zaměstnanci/Brigádníci')),
      body: FutureBuilder<SubscriptionStatus>(
        future: SubscriptionService.getStatus(),
        builder: (context, subSnap) {
          final status = subSnap.data ?? SubscriptionStatus.none;
          return StreamBuilder<List<Worker>>(
            stream: FirestoreService().workersStream(userId),
            builder: (context, snapshot) {
              final workers = snapshot.data ?? [];
              final atLimit = !status.isPro && workers.length >= 3;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _InfoBanner(),
                  const SizedBox(height: 20),
                  if (workers.isEmpty)
                    _EmptyState()
                  else
                    ...workers.map((w) => _WorkerTile(
                          worker: w,
                          userId: userId,
                        )),
                  const SizedBox(height: 20),
                  if (atLimit) _LimitBanner(),
                  FilledButton.icon(
                    onPressed:
                        atLimit ? null : () => _showAddWorkerDialog(context),
                    icon: const Icon(Icons.person_add_outlined),
                    label: const Text('Přidat zaměstnance/brigádníka'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showAddWorkerDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final pinCtrl = TextEditingController();
    final pin2Ctrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Nový zaměstnanec/brigádník'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Jméno',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Zadejte jméno' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: pinCtrl,
                  decoration: const InputDecoration(
                    labelText: 'PIN (6 číslic)',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  validator: (v) {
                    if (v == null || v.length != 6) return 'PIN musí mít 6 číslic';
                    if (!RegExp(r'^\d{6}$').hasMatch(v)) return 'Pouze číslice';
                    return null;
                  },
                ),
                const SizedBox(height: 4),
                TextFormField(
                  controller: pin2Ctrl,
                  decoration: const InputDecoration(
                    labelText: 'Potvrdit PIN',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  keyboardType: TextInputType.number,
                  obscureText: true,
                  maxLength: 6,
                  validator: (v) =>
                      v != pinCtrl.text ? 'PINy se neshodují' : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Zrušit'),
            ),
            FilledButton(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setState(() => saving = true);
                      final pinHash =
                          WorkerService.hashPin(userId, pinCtrl.text);
                      await FirestoreService().addWorker(
                        userId,
                        Worker(
                          name: nameCtrl.text.trim(),
                          pinHash: pinHash,
                          createdAt: DateTime.now(),
                        ),
                      );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Přidat'),
            ),
          ],
        ),
      ),
    );

    nameCtrl.dispose();
    pinCtrl.dispose();
    pin2Ctrl.dispose();
  }
}

class _LimitBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.warn),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Dosáhli jste limitu 3 brigádníků plánu Basic. Pro přidání dalších přejděte na plán Pro.',
              style: TextStyle(
                  fontSize: 13, color: AppColors.ink700, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryFaint,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryTint),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: AppColors.primaryBlue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Brigádník stáhne aplikaci, zvolí „Jsem zaměstnanec/brigádník" a naskenuje svůj QR kód. Poté se přihlašuje PINem.',
              style: TextStyle(fontSize: 13, color: AppColors.ink700, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          const Text('Žádní zaměstnanci/brigádníci',
              style: TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _WorkerTile extends StatelessWidget {
  final Worker worker;
  final String userId;
  const _WorkerTile({required this.worker, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border, width: 1.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primaryFaint,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.person_outline,
              size: 20, color: AppColors.primaryBlue),
        ),
        title: Text(worker.name,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: AppColors.heading)),
        subtitle: Text(
          'Přidán ${_formatDate(worker.createdAt)}',
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.qr_code_2, color: AppColors.primaryBlue),
              tooltip: 'Zobrazit QR kód',
              onPressed: () => _showQrDialog(context),
            ),
            IconButton(
              icon:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              tooltip: 'Odebrat',
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context) {
    final qrData = WorkerService.buildQrData(
      ownerUserId: userId,
      workerName: worker.name,
      pinHash: worker.pinHash,
    );
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('QR kód — ${worker.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
            ),
            const SizedBox(height: 12),
            const Text(
              'Zaměstnanec/brigádník naskenuje tento kód při registraci zařízení.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zavřít'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Odebrat ${worker.name}?'),
        content: const Text(
            'Zaměstnanec/brigádník ztratí přístup po příštím restartu aplikace na svém zařízení.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Odebrat'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await FirestoreService().deleteWorker(userId, worker.id!);
    }
  }

  String _formatDate(DateTime dt) => '${dt.day}. ${dt.month}. ${dt.year}';
}
