// lib/features/admin/screens/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  static const _tabs = [
    _Tab(icon: Icons.dashboard_rounded, label: 'Dashboard', path: '/admin'),
    _Tab(icon: Icons.people_rounded, label: 'Users', path: '/admin/users'),
    _Tab(icon: Icons.swap_horiz_rounded, label: 'Transfers', path: '/admin/transactions'),
    _Tab(icon: Icons.verified_user_rounded, label: 'KYC', path: '/admin/kyc'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.toString();
    int currentIndex = 0;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path) && (i == 0 ? location == '/admin' : true)) {
        currentIndex = i;
        if (i > 0) break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_tabs[i].path),
        items: _tabs.map((t) => BottomNavigationBarItem(
          icon: Icon(t.icon), label: t.label,
        )).toList(),
      ),
    );
  }
}

class _Tab {
  final IconData icon;
  final String label;
  final String path;
  const _Tab({required this.icon, required this.label, required this.path});
}
