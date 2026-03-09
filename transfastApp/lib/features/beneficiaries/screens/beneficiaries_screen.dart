// lib/features/beneficiaries/screens/beneficiaries_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../transactions/models/transaction_model.dart';

class BeneficiariesScreen extends ConsumerStatefulWidget {
  const BeneficiariesScreen({super.key});
  @override
  ConsumerState<BeneficiariesScreen> createState() => _BeneficiariesScreenState();
}

class _BeneficiariesScreenState extends ConsumerState<BeneficiariesScreen> {
  List<BeneficiaryModel> _beneficiaries = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await BeneficiaryApiService().getBeneficiaries();
      setState(() => _beneficiaries = (res['beneficiaries'] as List)
          .map((e) => BeneficiaryModel.fromJson(e as Map<String, dynamic>)).toList());
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _delete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove Recipient?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove')),
        ],
      ),
    );
    if (ok != true) return;
    try { await BeneficiaryApiService().deleteBeneficiary(id); _load(); } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recipients'), actions: [
        IconButton(icon: const Icon(Icons.add_rounded), onPressed: () => _showAddModal(context)),
      ]),
      body: _loading
          ? const AppLoader()
          : _beneficiaries.isEmpty
          ? EmptyState(
              icon: Icons.group_rounded,
              title: 'No recipients yet',
              subtitle: 'Add recipients to start sending money',
              actionLabel: 'Add Recipient',
              onAction: () => _showAddModal(context),
            )
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _beneficiaries.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _BeneficiaryCard(
                  b: _beneficiaries[i],
                  onDelete: () => _delete(_beneficiaries[i].id),
                ),
              ),
            ),
    );
  }

  void _showAddModal(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddBeneficiarySheet(onSaved: _load),
    );
  }
}

class _BeneficiaryCard extends StatelessWidget {
  final BeneficiaryModel b;
  final VoidCallback onDelete;
  const _BeneficiaryCard({required this.b, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryLight,
          child: Text(b.initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.fullName, style: AppTextStyles.label),
          Text('${b.country} · ${b.currency}', style: AppTextStyles.caption),
          Text(b.payoutMethod.replaceAll('_', ' '), style: AppTextStyles.caption),
        ])),
        IconButton(
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
          onPressed: onDelete,
        ),
      ]),
    );
  }
}

class _AddBeneficiarySheet extends StatefulWidget {
  final VoidCallback onSaved;
  const _AddBeneficiarySheet({required this.onSaved});

  @override
  State<_AddBeneficiarySheet> createState() => _AddBeneficiarySheetState();
}

class _AddBeneficiarySheetState extends State<_AddBeneficiarySheet> {
  final _formKey = GlobalKey<FormState>();
  final _fn = TextEditingController(), _ln = TextEditingController();
  final _country = TextEditingController(), _currency = TextEditingController();
  final _phone = TextEditingController(), _bankName = TextEditingController();
  final _accountNo = TextEditingController();
  String _payoutMethod = 'bank_deposit';
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Add Recipient', style: AppTextStyles.h3),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: AppTextField(label: 'First Name', hint: 'John', controller: _fn, validator: (v) => v!.isEmpty ? 'Required' : null)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Last Name', hint: 'Smith', controller: _ln, validator: (v) => v!.isEmpty ? 'Required' : null)),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: AppTextField(label: 'Country Code', hint: 'PK', controller: _country, validator: (v) => v!.isEmpty ? 'Required' : null)),
              const SizedBox(width: 12),
              Expanded(child: AppTextField(label: 'Currency', hint: 'PKR', controller: _currency, validator: (v) => v!.isEmpty ? 'Required' : null)),
            ]),
            const SizedBox(height: 12),
            AppTextField(label: 'Phone', hint: '+92300...', controller: _phone),
            const SizedBox(height: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Payout Method', style: AppTextStyles.label),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _payoutMethod,
                decoration: const InputDecoration(),
                items: const [
                  DropdownMenuItem(value: 'bank_deposit', child: Text('Bank Deposit')),
                  DropdownMenuItem(value: 'mobile_wallet', child: Text('Mobile Wallet')),
                  DropdownMenuItem(value: 'cash_pickup', child: Text('Cash Pickup')),
                ],
                onChanged: (v) => setState(() => _payoutMethod = v!),
              ),
            ]),
            if (_payoutMethod == 'bank_deposit') ...[
              const SizedBox(height: 12),
              AppTextField(label: 'Bank Name', hint: 'HBL Bank', controller: _bankName),
              const SizedBox(height: 12),
              AppTextField(label: 'Account Number', hint: '0123...', controller: _accountNo),
            ],
            const SizedBox(height: 24),
            AppButton(
              label: 'Save Recipient',
              isLoading: _saving,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                setState(() => _saving = true);
                try {
                  await BeneficiaryApiService().addBeneficiary({
                    'firstName': _fn.text.trim(), 'lastName': _ln.text.trim(),
                    'country': _country.text.trim().toUpperCase(),
                    'currency': _currency.text.trim().toUpperCase(),
                    'phone': _phone.text.trim(),
                    'payoutMethod': _payoutMethod,
                    if (_payoutMethod == 'bank_deposit') 'bankDetails': {
                      'bankName': _bankName.text.trim(),
                      'accountNumber': _accountNo.text.trim(),
                    },
                  });
                  widget.onSaved();
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
                }
                setState(() => _saving = false);
              },
            ),
          ]),
        ),
      ),
    );
  }
}
