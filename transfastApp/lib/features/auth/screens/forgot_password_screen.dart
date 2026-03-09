// lib/features/auth/screens/forgot_password_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  bool _sent = false;

  Future<void> _submit() async {
    if (_emailCtrl.text.isEmpty) return;
    setState(() => _loading = true);
    try {
      await AuthApiService().forgotPassword(_emailCtrl.text.trim());
      setState(() => _sent = true);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent ? _sentState() : _formState(),
      ),
    );
  }

  Widget _sentState() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
        child: const Icon(Icons.mark_email_read_outlined, size: 40, color: AppColors.success),
      ),
      const SizedBox(height: 24),
      Text('Email Sent!', style: AppTextStyles.h2),
      const SizedBox(height: 8),
      Text('Check your inbox for reset instructions', style: AppTextStyles.bodySm, textAlign: TextAlign.center),
      const SizedBox(height: 32),
      AppButton(label: 'Back to Login', onPressed: () => context.go('/login'), width: 200),
    ]),
  );

  Widget _formState() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 16),
    Text('Forgot Password?', style: AppTextStyles.h2),
    const SizedBox(height: 8),
    Text("Enter your email and we'll send reset instructions.", style: AppTextStyles.bodySm),
    const SizedBox(height: 32),
    AppTextField(
      label: 'Email Address',
      hint: 'you@example.com',
      controller: _emailCtrl,
      keyboardType: TextInputType.emailAddress,
    ),
    const SizedBox(height: 24),
    AppButton(label: 'Send Reset Email', onPressed: _submit, isLoading: _loading),
  ]);
}
