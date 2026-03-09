// lib/features/transactions/screens/transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/transaction_model.dart';

final _statusFilter = StateProvider<String>((ref) => '');
final _txnPageProvider = StateProvider<int>((ref) => 1);

final transactionsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final status = ref.watch(_statusFilter);
  final page = ref.watch(_txnPageProvider);
  return TransferApiService().getTransfers(page: page, limit: 10, status: status);
});

class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  static const _statuses = ['', 'pending', 'processing', 'sent', 'delivered', 'failed', 'cancelled'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txnsAsync = ref.watch(transactionsProvider);
    final statusFilter = ref.watch(_statusFilter);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions'), actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: () => ref.invalidate(transactionsProvider),
        ),
      ]),
      body: Column(
        children: [
          // Status filter chips
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: _statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final s = _statuses[i];
                final isActive = s == statusFilter;
                return GestureDetector(
                  onTap: () {
                    ref.read(_statusFilter.notifier).state = s;
                    ref.read(_txnPageProvider.notifier).state = 1;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                    ),
                    child: Text(
                      s.isEmpty ? 'All' : s[0].toUpperCase() + s.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          Expanded(
            child: txnsAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: 5,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, __) => const ShimmerCard(),
              ),
              error: (e, _) => AppErrorWidget(
                message: e.toString(),
                onRetry: () => ref.invalidate(transactionsProvider),
              ),
              data: (data) {
                final items = (data['transactions'] as List? ?? [])
                    .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
                    .toList();

                if (items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.receipt_long_rounded,
                    title: 'No transactions',
                    subtitle: 'Your transfers will appear here',
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(transactionsProvider),
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _TxnCard(txn: items[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TxnCard extends StatelessWidget {
  final TransactionModel txn;
  const _TxnCard({required this.txn});

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMM dd, yyyy').format(
      DateTime.tryParse(txn.createdAt) ?? DateTime.now(),
    );

    return AppCard(
      onTap: () => context.go('/transactions/${txn.id}'),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            color: AppColors.primaryLight,
            borderRadius: BorderRadius.circular(13),
          ),
          child: const Icon(Icons.send_rounded, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(txn.beneficiaryName, style: AppTextStyles.label),
          const SizedBox(height: 3),
          Text(txn.transactionId, style: AppTextStyles.caption),
          Text(dateStr, style: AppTextStyles.caption),
        ])),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('\$${txn.sendAmount.toStringAsFixed(0)} ${txn.sendCurrency}', style: AppTextStyles.h4),
          const SizedBox(height: 4),
          StatusBadge(status: txn.status),
          if (txn.isFlagged) ...[
            const SizedBox(height: 4),
            const StatusBadge(status: 'flagged'),
          ],
        ]),
      ]),
    );
  }
}
