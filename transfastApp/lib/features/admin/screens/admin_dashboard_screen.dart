// lib/features/admin/screens/admin_dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_widgets.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final res = await AdminApiService().getDashboard();
  return res['stats'] as Map<String, dynamic>;
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminStatsProvider),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140,
              pinned: true,
              backgroundColor: AppColors.primaryDark,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primaryDark, AppColors.primary]),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
                  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Admin Panel', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
                      Text('${user?.role?.toUpperCase() ?? 'ADMIN'} · ${user?.email ?? ''}',
                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11)),
                    ]),
                    GestureDetector(
                      onTap: () async { await ref.read(authStateProvider.notifier).logout(); context.go('/login'); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                        child: const Row(children: [
                          Icon(Icons.logout_rounded, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text('Logout', style: TextStyle(color: Colors.white, fontSize: 12)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: statsAsync.when(
                loading: () => SliverList(delegate: SliverChildListDelegate([const AppLoader()])),
                error: (e, _) => SliverList(delegate: SliverChildListDelegate([AppErrorWidget(message: e.toString())])),
                data: (stats) => SliverList(
                  delegate: SliverChildListDelegate([
                    GridView.count(
                      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.5, mainAxisSpacing: 12, crossAxisSpacing: 12,
                      children: [
                        _AdminStatCard(label: 'Total Users', value: '${stats['totalUsers'] ?? 0}', icon: Icons.people_rounded, color: AppColors.info),
                        _AdminStatCard(label: 'Transactions', value: '${stats['totalTransactions'] ?? 0}', icon: Icons.swap_horiz_rounded, color: AppColors.primary),
                        _AdminStatCard(label: 'Volume', value: '\$${(stats['totalVolume'] ?? 0).toStringAsFixed(0)}', icon: Icons.attach_money_rounded, color: AppColors.success),
                        _AdminStatCard(label: 'Pending KYC', value: '${stats['pendingKYC'] ?? 0}', icon: Icons.shield_outlined, color: AppColors.warning),
                        _AdminStatCard(label: "Today's TXNs", value: '${stats['todayTransactions'] ?? 0}', icon: Icons.today_rounded, color: const Color(0xFF8B5CF6)),
                        _AdminStatCard(label: 'Flagged', value: '${stats['flaggedTransactions'] ?? 0}', icon: Icons.flag_rounded, color: AppColors.error),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const SectionHeader(title: 'Quick Actions'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: AppButton(label: 'Manage Users', icon: Icons.people_rounded, height: 44, onPressed: () => context.go('/admin/users'))),
                      const SizedBox(width: 12),
                      Expanded(child: AppButton(label: 'Review KYC', icon: Icons.verified_user_rounded, height: 44, color: AppColors.warning, onPressed: () => context.go('/admin/kyc'))),
                    ]),
                  ]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminStatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _AdminStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Container(width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          Text(label, style: AppTextStyles.caption),
        ]),
      ]),
    );
  }
}

// ── Admin Users Screen ─────────────────────────────────────────────────────
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});
  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  final _searchCtrl = TextEditingController();

  @override void initState() { super.initState(); _load(); }

  Future<void> _load({String? search}) async {
    setState(() => _loading = true);
    try {
      final res = await AdminApiService().getUsers(search: search);
      setState(() => _users = (res['users'] as List).cast<Map<String, dynamic>>());
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Management'), bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search_rounded, size: 18),
              suffixIcon: IconButton(icon: const Icon(Icons.send_rounded, size: 18), onPressed: () => _load(search: _searchCtrl.text)),
            ),
            onSubmitted: (v) => _load(search: v),
          ),
        ),
      )),
      body: _loading ? const AppLoader() : _users.isEmpty
          ? const EmptyState(icon: Icons.people_outline_rounded, title: 'No users found')
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final isSuspended = u['isSuspended'] == true;
                  return AppCard(
                    child: Row(children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: AppColors.primaryLight,
                        child: Text('${u['firstName']?[0] ?? ''}${u['lastName']?[0] ?? ''}',
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${u['firstName']} ${u['lastName']}', style: AppTextStyles.label),
                        Text(u['email'] ?? '', style: AppTextStyles.caption),
                        Row(children: [
                          StatusBadge(status: u['kycStatus'] ?? 'pending'),
                          const SizedBox(width: 6),
                          if (isSuspended) const StatusBadge(status: 'suspended'),
                        ]),
                      ])),
                      IconButton(
                        icon: Icon(isSuspended ? Icons.lock_open_rounded : Icons.block_rounded,
                          color: isSuspended ? AppColors.success : AppColors.error, size: 20),
                        onPressed: () async {
                          try {
                            await AdminApiService().toggleUserStatus(u['_id'], isSuspended ? 'activate' : 'suspend');
                            _load();
                          } catch (_) {}
                        },
                      ),
                    ]),
                  );
                },
              ),
            ),
    );
  }
}

// ── Admin Transactions Screen ──────────────────────────────────────────────
class AdminTransactionsScreen extends ConsumerStatefulWidget {
  const AdminTransactionsScreen({super.key});
  @override
  ConsumerState<AdminTransactionsScreen> createState() => _AdminTransactionsScreenState();
}

class _AdminTransactionsScreenState extends ConsumerState<AdminTransactionsScreen> {
  List<Map<String, dynamic>> _txns = [];
  bool _loading = true, _flaggedOnly = false;
  String _statusFilter = '';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApiService().getTransactions(status: _statusFilter, flagged: _flaggedOnly);
      setState(() => _txns = (res['transactions'] as List).cast<Map<String, dynamic>>());
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: Icon(_flaggedOnly ? Icons.flag_rounded : Icons.flag_outlined, color: _flaggedOnly ? AppColors.error : null),
            onPressed: () { setState(() => _flaggedOnly = !_flaggedOnly); _load(); },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: ['','pending','processing','sent','delivered','failed'].map((s) {
              final active = s == _statusFilter;
              return GestureDetector(
                onTap: () { setState(() => _statusFilter = s); _load(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: active ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(s.isEmpty ? 'All' : s, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList()),
          ),
        ),
      ),
      body: _loading ? const AppLoader() : _txns.isEmpty
          ? const EmptyState(icon: Icons.receipt_long_rounded, title: 'No transactions')
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _txns.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final t = _txns[i];
                  final sender = t['sender'] as Map<String, dynamic>?;
                  final isFlagged = t['isFlagged'] == true;
                  return AppCard(
                    color: isFlagged ? AppColors.warning.withOpacity(0.05) : null,
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(t['transactionId']?.toString().substring(0, 16) ?? '', style: AppTextStyles.caption)),
                        StatusBadge(status: t['status'] ?? 'pending'),
                        if (isFlagged) ...[const SizedBox(width: 6), const StatusBadge(status: 'flagged')],
                      ]),
                      const SizedBox(height: 8),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${sender?['firstName']} ${sender?['lastName']}', style: AppTextStyles.label),
                        Text('\$${t['sendAmount']} ${t['sendCurrency']}', style: AppTextStyles.h4),
                      ]),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('→ ${t['receiveCountry']}', style: AppTextStyles.caption),
                        Text('${t['receiveAmount']} ${t['receiveCurrency']}', style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600)),
                      ]),
                      if (['pending','processing'].contains(t['status'])) ...[
                        const SizedBox(height: 8),
                        Row(children: [
                          Expanded(child: OutlinedButton(
                            onPressed: () async { await AdminApiService().updateTransactionStatus(t['_id'], 'delivered'); _load(); },
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success), minimumSize: const Size(0, 32)),
                            child: const Text('Mark Delivered', style: TextStyle(fontSize: 12)),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton(
                            onPressed: () async { await AdminApiService().updateTransactionStatus(t['_id'], 'failed', note: 'Rejected'); _load(); },
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), minimumSize: const Size(0, 32)),
                            child: const Text('Reject', style: TextStyle(fontSize: 12)),
                          )),
                        ]),
                      ],
                    ]),
                  );
                },
              ),
            ),
    );
  }
}

// ── Admin KYC Screen ───────────────────────────────────────────────────────
class AdminKycScreen extends ConsumerStatefulWidget {
  const AdminKycScreen({super.key});
  @override
  ConsumerState<AdminKycScreen> createState() => _AdminKycScreenState();
}

class _AdminKycScreenState extends ConsumerState<AdminKycScreen> {
  List<Map<String, dynamic>> _kycList = [];
  bool _loading = true;
  String _statusFilter = 'under_review';

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await AdminApiService().getKycList(status: _statusFilter);
      setState(() => _kycList = (res['kycList'] as List).cast<Map<String, dynamic>>());
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('KYC Review'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(children: ['under_review','approved','rejected'].map((s) {
              final active = s == _statusFilter;
              return GestureDetector(
                onTap: () { setState(() => _statusFilter = s); _load(); },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  decoration: BoxDecoration(
                    color: active ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: active ? AppColors.primary : AppColors.border),
                  ),
                  child: Text(s.replaceAll('_', ' '), style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textSecondary)),
                ),
              );
            }).toList()),
          ),
        ),
      ),
      body: _loading ? const AppLoader() : _kycList.isEmpty
          ? const EmptyState(icon: Icons.shield_outlined, title: 'No KYC submissions')
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _kycList.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, i) {
                  final k = _kycList[i];
                  final user = k['user'] as Map<String, dynamic>?;
                  final isPending = k['status'] == 'under_review';
                  return AppCard(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        CircleAvatar(
                          radius: 18, backgroundColor: AppColors.primaryLight,
                          child: Text('${user?['firstName']?[0] ?? ''}${user?['lastName']?[0] ?? ''}',
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 12)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${user?['firstName']} ${user?['lastName']}', style: AppTextStyles.label),
                          Text(user?['email'] ?? '', style: AppTextStyles.caption),
                        ])),
                        StatusBadge(status: k['status'] ?? ''),
                      ]),
                      const SizedBox(height: 8),
                      Row(children: [
                        Text('ID: ${(k['idType'] ?? '').toString().replaceAll('_', ' ')}', style: AppTextStyles.caption),
                        const SizedBox(width: 12),
                        Text('Funds: ${k['sourceOfFunds'] ?? ''}', style: AppTextStyles.caption),
                      ]),
                      if (isPending) ...[
                        const SizedBox(height: 10),
                        Row(children: [
                          Expanded(child: OutlinedButton(
                            onPressed: () async { await AdminApiService().reviewKyc(k['_id'], 'approve'); _load(); },
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.success, side: const BorderSide(color: AppColors.success), minimumSize: const Size(0, 32)),
                            child: const Text('Approve', style: TextStyle(fontSize: 12)),
                          )),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton(
                            onPressed: () async { await AdminApiService().reviewKyc(k['_id'], 'reject', reason: 'Documents unclear'); _load(); },
                            style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: const BorderSide(color: AppColors.error), minimumSize: const Size(0, 32)),
                            child: const Text('Reject', style: TextStyle(fontSize: 12)),
                          )),
                        ]),
                      ],
                    ]),
                  );
                },
              ),
            ),
    );
  }
}
