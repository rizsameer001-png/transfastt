// lib/core/utils/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/dashboard/screens/main_shell.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/transfer/screens/send_money_screen.dart';
import '../../features/transactions/screens/transactions_screen.dart';
import '../../features/transactions/screens/transaction_detail_screen.dart';
import '../../features/beneficiaries/screens/beneficiaries_screen.dart';
import '../../features/kyc/screens/kyc_screen.dart';
import '../../features/rates/screens/rates_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/admin/screens/admin_shell.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/screens/admin_users_screen.dart';
import '../../features/admin/screens/admin_transactions_screen.dart';
import '../../features/admin/screens/admin_kyc_screen.dart' as admin_kyc;

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isInitializing = authState.isInitializing;
      final isLoggedIn = authState.user != null;
      final isAdmin = authState.user?.isAdmin ?? false;
      final location = state.uri.toString();

      if (isInitializing) return '/splash';

      final publicRoutes = [
        '/login',
        '/register',
        '/forgot-password',
        '/splash'
      ];
      final isPublic = publicRoutes.any((r) => location.startsWith(r));

      if (!isLoggedIn && !isPublic) return '/login';
      if (isLoggedIn && isPublic && location != '/splash') {
        return isAdmin ? '/admin' : '/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordScreen()),

      // User shell
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
              path: '/dashboard', builder: (_, __) => const DashboardScreen()),
          GoRoute(
              path: '/send-money', builder: (_, __) => const SendMoneyScreen()),
          GoRoute(
              path: '/transactions',
              builder: (_, __) => const TransactionsScreen()),
          GoRoute(
            path: '/transactions/:id',
            builder: (_, state) =>
                TransactionDetailScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(
              path: '/beneficiaries',
              builder: (_, __) => const BeneficiariesScreen()),
          GoRoute(path: '/kyc', builder: (_, __) => const KycScreen()),
          GoRoute(path: '/rates', builder: (_, __) => const RatesScreen()),
          GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
        ],
      ),

      // Admin shell
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
              path: '/admin', builder: (_, __) => const AdminDashboardScreen()),
          GoRoute(
              path: '/admin/users',
              builder: (_, __) => const AdminUsersScreen()),
          GoRoute(
              path: '/admin/transactions',
              builder: (_, __) => const AdminTransactionsScreen()),
          GoRoute(
              path: '/admin/kyc',
              builder: (_, __) => const admin_kyc.AdminKycScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});
