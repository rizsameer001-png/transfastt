// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final user = await ref.read(authStateProvider.notifier).login(
        _emailCtrl.text.trim(),
        _passCtrl.text,
      );
      if (mounted) context.go(user.isAdmin ? '/admin' : '/dashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              height: 260,
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.public_rounded, size: 38, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('TransFast', style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white, fontFamily: 'DMSans',
                    )),
                    const SizedBox(height: 6),
                    Text('Send money globally in minutes',
                      style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.75), fontFamily: 'DMSans'),
                    ),
                  ],
                ),
              ),
            ),

            // Form
            Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text('Welcome Back', style: AppTextStyles.h2),
                    const SizedBox(height: 4),
                    Text('Sign in to your account', style: AppTextStyles.bodySm),
                    const SizedBox(height: 28),

                    AppTextField(
                      label: 'Email Address',
                      hint: 'you@example.com',
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      prefix: const Icon(Icons.email_outlined, size: 20, color: AppColors.textHint),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AppTextField(
                      label: 'Password',
                      hint: '••••••••',
                      controller: _passCtrl,
                      obscureText: _obscurePass,
                      prefix: const Icon(Icons.lock_outline, size: 20, color: AppColors.textHint),
                      suffix: IconButton(
                        icon: Icon(
                          _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20, color: AppColors.textHint,
                        ),
                        onPressed: () => setState(() => _obscurePass = !_obscurePass),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot Password?'),
                      ),
                    ),
                    const SizedBox(height: 8),

                    AppButton(
                      label: 'Sign In',
                      onPressed: _login,
                      isLoading: isLoading,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: AppTextStyles.bodySm),
                        GestureDetector(
                          onTap: () => context.push('/register'),
                          child: const Text('Create Account',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                    // Demo credentials hint
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Demo Credentials', style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary,
                          )),
                          const SizedBox(height: 6),
                          _demoCredential('👤 User', 'john@example.com / User@12345'),
                          _demoCredential('🛡️ Admin', 'admin@transfast.com / Admin@123456'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoCredential(String role, String creds) {
    return Padding(
      padding: const EdgeInsets.only(top: 3),
      child: GestureDetector(
        onTap: () {
          final parts = creds.split(' / ');
          _emailCtrl.text = parts[0];
          _passCtrl.text = parts[1];
        },
        child: Text('$role: $creds', style: const TextStyle(
          fontSize: 11, color: AppColors.primary, fontFamily: 'DMSans',
        )),
      ),
    );
  }
}
