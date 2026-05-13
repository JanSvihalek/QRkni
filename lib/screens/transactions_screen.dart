import 'package:flutter/material.dart';
import '../models/payment_transaction.dart';
import '../services/firestore_service.dart';

class TransactionsScreen extends StatelessWidget {
  final String userId;
  const TransactionsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historie plateb'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<PaymentTransaction>>(
        stream: FirestoreService().transactionsStream(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final all = snapshot.data ?? [];
          if (all.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Zatím žádné platby',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          final now = DateTime.now();
          final todayTxns = all
              .where((t) =>
                  t.createdAt.year == now.year &&
                  t.createdAt.month == now.month &&
                  t.createdAt.day == now.day)
              .toList();

          return Column(
            children: [
              _SummaryCard(
                todayCount: todayTxns.length,
                todayTotal: todayTxns.fold(0.0, (s, t) => s + t.amount),
                allCount: all.length,
                allTotal: all.fold(0.0, (s, t) => s + t.amount),
              ),
              Expanded(child: _TransactionList(transactions: all)),
            ],
          );
        },
      ),
    );
  }
}

// ── Summary karta nahoře ─────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final int todayCount;
  final double todayTotal;
  final int allCount;
  final double allTotal;

  const _SummaryCard({
    required this.todayCount,
    required this.todayTotal,
    required this.allCount,
    required this.allTotal,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatCell(label: 'Dnes', count: todayCount, total: todayTotal),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: cs.onPrimaryContainer.withValues(alpha: 0.2),
            ),
            Expanded(
              child: _StatCell(label: 'Celkem', count: allCount, total: allTotal),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final int count;
  final double total;

  const _StatCell(
      {required this.label, required this.count, required this.total});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final amountStr = total.toStringAsFixed(2).replaceAll('.', ',');
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
              fontSize: 12, color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
        ),
        const SizedBox(height: 4),
        Text(
          '$amountStr Kč',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: cs.onPrimaryContainer,
          ),
        ),
        Text(
          '$count ${_pluralPayment(count)}',
          style: TextStyle(
              fontSize: 12, color: cs.onPrimaryContainer.withValues(alpha: 0.7)),
        ),
      ],
    );
  }

  String _pluralPayment(int n) {
    if (n == 1) return 'platba';
    if (n >= 2 && n <= 4) return 'platby';
    return 'plateb';
  }
}

// ── Seznam transakcí ─────────────────────────────────────────────────────────

class _TransactionList extends StatelessWidget {
  final List<PaymentTransaction> transactions;
  const _TransactionList({required this.transactions});

  @override
  Widget build(BuildContext context) {
    final items = _buildItems();
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is String) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text(
              item,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade500,
                letterSpacing: 0.5,
              ),
            ),
          );
        }
        return _TransactionTile(transaction: item as PaymentTransaction);
      },
    );
  }

  List<Object> _buildItems() {
    final result = <Object>[];
    String? lastLabel;
    for (final t in transactions) {
      final label = _dayLabel(t.createdAt);
      if (label != lastLabel) {
        result.add(label);
        lastLabel = label;
      }
      result.add(t);
    }
    return result;
  }

  String _dayLabel(DateTime dt) {
    final now = DateTime.now();
    if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
      return 'DNES';
    }
    final yesterday = now.subtract(const Duration(days: 1));
    if (dt.year == yesterday.year &&
        dt.month == yesterday.month &&
        dt.day == yesterday.day) {
      return 'VČERA';
    }
    return '${dt.day}. ${dt.month}. ${dt.year}';
  }
}

class _TransactionTile extends StatelessWidget {
  final PaymentTransaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final t = transaction;
    final time =
        '${t.createdAt.hour.toString().padLeft(2, '0')}:${t.createdAt.minute.toString().padLeft(2, '0')}';
    final amountStr =
        '${t.amount.toStringAsFixed(2).replaceAll('.', ',')} Kč';

    final parts = <String>[
      t.profileName,
      if (t.items.isNotEmpty)
        t.items.map((i) => '${i.name} ×${i.quantity}').join(', '),
      if (t.createdBy != null && t.createdBy!.isNotEmpty) t.createdBy!,
    ];
    final subtitle = parts.join(' · ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: SizedBox(
        width: 44,
        child: Text(
          time,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          textAlign: TextAlign.center,
        ),
      ),
      title: Text(
        amountStr,
        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
