// lib/features/dashboard/screens/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../shared/widgets/app_widgets.dart';

final recentTransactionsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final res = await TransferApiService().getTransfers(limit: 5);
  final list = res['transactions'] as List? ?? [];
  return list.cast<Map<String, dynamic>>();
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final txnsAsync = ref.watch(recentTransactionsProvider);
    final fmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(recentTransactionsProvider),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary, AppColors.primaryDark],
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Good ${_greeting()},', style: TextStyle(
                                color: Colors.white.withOpacity(0.75), fontSize: 13,
                              )),
                              Text(user?.firstName ?? '', style: const TextStyle(
                                color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700, fontFamily: 'DMSans',
                              )),
                            ]),
                            Row(children: [
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                  width: 42, height: 42,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                                ),
                              ),
                              const SizedBox(width: 10),
                              GestureDetector(
                                onTap: () => context.go('/profile'),
                                child: CircleAvatar(
                                  radius: 21,
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                  child: user?.avatar != null
                            ? ClipOval(child: CachedNetworkImage(imageUrl: user!.avatar!, width: 42, height: 42, fit: BoxFit.cover))
                            : Text(user?.initials ?? 'U',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                ),
                              ),
                            ]),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Stats row
                        Row(children: [
                          _statChip(Icons.send_rounded, 'Transfers', '${user?.totalTransfers ?? 0}'),
                          const SizedBox(width: 12),
                          _statChip(Icons.trending_up_rounded, 'Total Sent', fmt.format(user?.totalAmountSent ?? 0)),
                          const SizedBox(width: 12),
                          _statChip(Icons.verified_user_outlined, 'KYC', user?.kycStatus.toUpperCase() ?? 'PENDING'),
                        ]),

                        // KYC banner
                        if (!(user?.isKycApproved ?? false)) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: () => context.go('/kyc'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.accent.withOpacity(0.4)),
                              ),
                              child: Row(children: [
                                const Icon(Icons.shield_outlined, color: AppColors.accent, size: 18),
                                const SizedBox(width: 10),
                                const Expanded(child: Text('Complete KYC to start sending money',
                                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                                const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 18),
                              ]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Quick actions
                  const SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 12),
                  Row(children: [
                    _quickAction(context, Icons.send_rounded, 'Send Money', AppColors.primary, '/send-money'),
                    const SizedBox(width: 12),
                    _quickAction(context, Icons.person_add_rounded, 'Add Recipient', const Color(0xFF3B82F6), '/beneficiaries'),
                    const SizedBox(width: 12),
                    _quickAction(context, Icons.trending_up_rounded, 'FX Rates', AppColors.accent, '/rates'),
                    const SizedBox(width: 12),
                    _quickAction(context, Icons.receipt_long_rounded, 'History', AppColors.success, '/transactions'),
                  ]),

                  const SizedBox(height: 28),

                  // Recent transfers
                  SectionHeader(
                    title: 'Recent Transfers',
                    actionLabel: 'See All',
                    onAction: () => context.go('/transactions'),
                  ),
                  const SizedBox(height: 12),

                  txnsAsync.when(
                    loading: () => Column(children: List.generate(3, (_) => const ShimmerCard())),
                    error: (e, _) => AppErrorWidget(message: e.toString()),
                    data: (txns) => txns.isEmpty
                        ? EmptyState(
                            icon: Icons.send_rounded,
                            title: 'No transfers yet',
                            subtitle: 'Your recent transfers will appear here',
                            actionLabel: (user?.isKycApproved ?? false) ? 'Send Money' : null,
                            onAction: () => context.go('/send-money'),
                          )
                        : Column(
                            children: txns.map((t) => _TransactionTile(txn: t)).toList(),
                          ),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10)),
        ]),
      ),
    );
  }

  Widget _quickAction(BuildContext context, IconData icon, String label, Color color, String route) {
    return Expanded(
      child: GestureDetector(
        onTap: () => context.go(route),
        child: Column(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ]),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    return 'evening';
  }
}

class _TransactionTile extends StatelessWidget {
  final Map<String, dynamic> txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final beneficiary = txn['beneficiary'] as Map<String, dynamic>?;
    final name = '${beneficiary?['firstName'] ?? ''} ${beneficiary?['lastName'] ?? ''}'.trim();
    final status = txn['status'] as String? ?? 'pending';
    final amount = (txn['sendAmount'] as num?)?.toDouble() ?? 0;
    final currency = txn['sendCurrency'] ?? 'USD';
    final receiveAmount = (txn['receiveAmount'] as num?)?.toDouble() ?? 0;
    final receiveCurrency = txn['receiveCurrency'] ?? '';

    return GestureDetector(
      onTap: () => context.go('/transactions/${txn['_id']}'),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.send_rounded, size: 20, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name.isEmpty ? 'Unknown' : name, style: AppTextStyles.label),
            const SizedBox(height: 3),
            Text(txn['transactionId'] ?? '', style: AppTextStyles.caption),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('\$${amount.toStringAsFixed(0)} $currency',
              style: AppTextStyles.label),
            const SizedBox(height: 3),
            StatusBadge(status: status),
          ]),
        ]),
      ),
    );
  }
}
