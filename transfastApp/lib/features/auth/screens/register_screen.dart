// lib/features/auth/screens/register_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

const _countries = [
  'United States','United Kingdom','Canada','Australia','Germany',
  'France','UAE','Saudi Arabia','Qatar','Kuwait','Singapore',
  'Malaysia','India','Pakistan','Bangladesh','Philippines','Other',
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedCountry = '';
  bool _obscurePass = true;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCountry.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your country'), backgroundColor: AppColors.error),
      );
      return;
    }
    try {
      await ref.read(authStateProvider.notifier).register({
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'password': _passCtrl.text,
        'country': _selectedCountry,
      });
      if (mounted) context.go('/dashboard');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authStateProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Join TransFast', style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Text('Fill in your details to get started', style: AppTextStyles.bodySm),
              const SizedBox(height: 28),

              Row(children: [
                Expanded(child: AppTextField(
                  label: 'First Name',
                  hint: 'John',
                  controller: _firstNameCtrl,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                )),
                const SizedBox(width: 12),
                Expanded(child: AppTextField(
                  label: 'Last Name',
                  hint: 'Smith',
                  controller: _lastNameCtrl,
                  validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null,
                )),
              ]),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Email Address',
                hint: 'john@example.com',
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Email required';
                  if (!v!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Phone Number',
                hint: '+1 234 567 8901',
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                validator: (v) => (v?.isEmpty ?? true) ? 'Phone required' : null,
              ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Country of Residence', style: AppTextStyles.label),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: _selectedCountry.isEmpty ? null : _selectedCountry,
                    decoration: const InputDecoration(hintText: 'Select country'),
                    items: _countries.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _selectedCountry = v ?? ''),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              AppTextField(
                label: 'Password',
                hint: 'Min. 8 characters',
                controller: _passCtrl,
                obscureText: _obscurePass,
                suffix: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20, color: AppColors.textHint),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
                validator: (v) {
                  if (v?.isEmpty ?? true) return 'Password required';
                  if (v!.length < 8) return 'Min. 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 28),

              AppButton(label: 'Create Account', onPressed: _register, isLoading: isLoading),
              const SizedBox(height: 20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('Already have an account? ', style: AppTextStyles.bodySm),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text('Sign In',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
