// lib/features/transfer/screens/send_money_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../../transactions/models/transaction_model.dart';

class SendMoneyScreen extends ConsumerStatefulWidget {
  const SendMoneyScreen({super.key});
  @override
  ConsumerState<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends ConsumerState<SendMoneyScreen> {
  int _step = 0;
  final _steps = ['Amount', 'Recipient', 'Payment', 'Review'];

  // Form data
  double _sendAmount = 100;
  String _sendCurrency = 'USD';
  String _receiveCountry = '';
  String _receiveCurrency = '';
  String _payoutMethod = 'bank_deposit';
  String _paymentMethod = 'debit_card';
  String _purpose = 'family_support';
  String _note = '';
  String _beneficiaryId = '';
  BeneficiaryModel? _selectedBeneficiary;

  Map<String, dynamic>? _quote;
  bool _loadingQuote = false;
  bool _submitting = false;
  List<Map<String, dynamic>> _countries = [];
  List<BeneficiaryModel> _beneficiaries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final [countriesRes, bensRes] = await Future.wait([
        ExchangeApiService().getCountries(),
        BeneficiaryApiService().getBeneficiaries(),
      ]);
      setState(() {
        _countries = (countriesRes['countries'] as List).cast<Map<String, dynamic>>();
        _beneficiaries = (bensRes['beneficiaries'] as List)
            .map((e) => BeneficiaryModel.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _fetchQuote() async {
    if (_receiveCurrency.isEmpty) return;
    setState(() => _loadingQuote = true);
    try {
      final res = await TransferApiService().getQuote(
        amount: _sendAmount,
        fromCurrency: _sendCurrency,
        toCurrency: _receiveCurrency,
        payoutMethod: _payoutMethod,
      );
      setState(() => _quote = res['quote']);
    } catch (_) {}
    setState(() => _loadingQuote = false);
  }

  Future<void> _submit() async {
    if (_beneficiaryId.isEmpty || _quote == null) return;
    setState(() => _submitting = true);
    try {
      final res = await TransferApiService().initiateTransfer({
        'beneficiaryId': _beneficiaryId,
        'sendAmount': _sendAmount,
        'sendCurrency': _sendCurrency,
        'receiveCurrency': _receiveCurrency,
        'exchangeRate': _quote!['exchangeRate'],
        'receiveAmount': _quote!['receiveAmount'],
        'payoutMethod': _payoutMethod,
        'paymentMethod': _paymentMethod,
        'transferPurpose': _purpose,
        'senderNote': _note.isEmpty ? null : _note,
      });
      final txnId = res['transaction']['_id'];
      if (mounted) context.go('/transactions/$txnId');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
    setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Money')),
      body: Column(
        children: [
          // Step indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: _steps.asMap().entries.map((entry) {
                final i = entry.key;
                final s = entry.value;
                final isDone = i < _step;
                final isCurrent = i == _step;
                return Expanded(child: Row(children: [
                  Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.success : isCurrent ? AppColors.primary : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Center(child: isDone
                          ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                          : Text('${i+1}', style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700,
                              color: isCurrent ? Colors.white : AppColors.textHint))),
                    ),
                    const SizedBox(height: 4),
                    Text(s, style: TextStyle(
                      fontSize: 10, fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: isCurrent ? AppColors.primary : AppColors.textHint,
                    )),
                  ]),
                  if (i < _steps.length - 1)
                    Expanded(child: Container(
                      height: 1.5, margin: const EdgeInsets.only(bottom: 20),
                      color: isDone ? AppColors.success : AppColors.border,
                    )),
                ]));
              }).toList(),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: [
                _buildStep0(),
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ][_step],
            ),
          ),
        ],
      ),
    );
  }

  // Step 0: Amount & country
  Widget _buildStep0() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('You\'re Sending', style: AppTextStyles.h3),
      const SizedBox(height: 20),

      // Amount input
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Amount', style: AppTextStyles.label),
        const SizedBox(height: 6),
        Row(children: [
          Container(
            width: 90,
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: AppColors.border),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _sendCurrency,
                isExpanded: true,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                items: ['USD','GBP','EUR','CAD','AUD']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600))))
                    .toList(),
                onChanged: (v) => setState(() => _sendCurrency = v!),
              ),
            ),
          ),
          Expanded(
            child: TextFormField(
              initialValue: _sendAmount.toString(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12), bottomRight: Radius.circular(12))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.border)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.only(
                  topRight: Radius.circular(12), bottomRight: Radius.circular(12)),
                  borderSide: BorderSide(color: AppColors.primary, width: 2)),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              onChanged: (v) => setState(() => _sendAmount = double.tryParse(v) ?? 0),
            ),
          ),
        ]),
      ]),

      const SizedBox(height: 16),

      // Country selector
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Send to Country', style: AppTextStyles.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _receiveCountry.isEmpty ? null : _receiveCountry,
          decoration: const InputDecoration(hintText: 'Select country'),
          items: _countries.map((c) => DropdownMenuItem(
            value: c['code'] as String,
            child: Text('${c['flag']} ${c['name']}'),
          )).toList(),
          onChanged: (v) {
            final country = _countries.firstWhere((c) => c['code'] == v, orElse: () => {});
            setState(() {
              _receiveCountry = v!;
              _receiveCurrency = country['currency'] ?? '';
            });
          },
        ),
      ]),

      const SizedBox(height: 16),

      // Payout method
      Text('Payout Method', style: AppTextStyles.label),
      const SizedBox(height: 8),
      ...[
        {'id':'bank_deposit','label':'Bank Deposit','icon':Icons.account_balance_rounded,'desc':'1-2 business days'},
        {'id':'mobile_wallet','label':'Mobile Wallet','icon':Icons.phone_android_rounded,'desc':'30 minutes'},
        {'id':'cash_pickup','label':'Cash Pickup','icon':Icons.location_on_rounded,'desc':'1-2 hours'},
      ].map((m) => GestureDetector(
        onTap: () => setState(() => _payoutMethod = m['id'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _payoutMethod == m['id'] ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _payoutMethod == m['id'] ? AppColors.primary : AppColors.border),
          ),
          child: Row(children: [
            Icon(m['icon'] as IconData, color: _payoutMethod == m['id'] ? AppColors.primary : AppColors.textHint, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['label'] as String, style: AppTextStyles.label.copyWith(
                color: _payoutMethod == m['id'] ? AppColors.primary : AppColors.textPrimary)),
              Text(m['desc'] as String, style: AppTextStyles.caption),
            ])),
            if (_payoutMethod == m['id'])
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
          ]),
        ),
      )),

      const SizedBox(height: 16),

      // Quote
      if (_loadingQuote)
        const Center(child: CircularProgressIndicator(color: AppColors.primary))
      else if (_quote != null)
        _quoteBox(),

      const SizedBox(height: 24),

      AppButton(
        label: _quote == null ? 'Get Quote' : 'Continue',
        onPressed: () {
          if (_receiveCountry.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a country')));
            return;
          }
          if (_quote == null) { _fetchQuote(); return; }
          setState(() => _step = 1);
        },
      ),
    ]);
  }

  Widget _quoteBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.06), AppColors.primaryLight]),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(children: [
        _qRow('Exchange Rate', '1 $_sendCurrency = ${_quote!['exchangeRate']} $_receiveCurrency'),
        _qRow('Transfer Fee', '\$${_quote!['transferFee']}'),
        _qRow('Total Deducted', '\$${_quote!['totalDeducted']}'),
        const Divider(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Recipient Gets', style: AppTextStyles.label),
          Text('${_quote!['receiveAmount']} $_receiveCurrency',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'DMSans')),
        ]),
        const SizedBox(height: 6),
        Text('⏱ ${_quote!['estimatedDelivery'] ?? 'Varies'}', style: AppTextStyles.caption),
      ]),
    );
  }

  Widget _qRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.bodySm),
      Text(value, style: AppTextStyles.label),
    ]),
  );

  // Step 1: Select beneficiary
  Widget _buildStep1() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Select Recipient', style: AppTextStyles.h3),
      const SizedBox(height: 4),
      Text('Choose who receives the money', style: AppTextStyles.bodySm),
      const SizedBox(height: 20),

      if (_beneficiaries.isEmpty)
        EmptyState(
          icon: Icons.group_add_rounded,
          title: 'No recipients yet',
          subtitle: 'Add a recipient first',
          actionLabel: 'Add Recipient',
          onAction: () => context.go('/beneficiaries'),
        )
      else
        ..._beneficiaries.map((b) => GestureDetector(
          onTap: () => setState(() { _beneficiaryId = b.id; _selectedBeneficiary = b; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _beneficiaryId == b.id ? AppColors.primaryLight : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _beneficiaryId == b.id ? AppColors.primary : AppColors.border),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(b.initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b.fullName, style: AppTextStyles.label),
                Text('${b.country} · ${b.payoutMethod.replaceAll('_',' ')} · ${b.currency}', style: AppTextStyles.caption),
              ])),
              if (_beneficiaryId == b.id)
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
            ]),
          ),
        )),

      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: AppButton(label: 'Back', onPressed: () => setState(() => _step = 0), isOutlined: true)),
        const SizedBox(width: 12),
        Expanded(child: AppButton(label: 'Continue', onPressed: () {
          if (_beneficiaryId.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a recipient')));
            return;
          }
          setState(() => _step = 2);
        })),
      ]),
    ]);
  }

  // Step 2: Payment method + purpose
  Widget _buildStep2() {
    final methods = [
      {'id':'debit_card','label':'Debit Card','icon':Icons.credit_card_rounded},
      {'id':'credit_card','label':'Credit Card','icon':Icons.credit_card_rounded},
      {'id':'bank_transfer','label':'Bank Transfer','icon':Icons.account_balance_rounded},
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Payment Details', style: AppTextStyles.h3),
      const SizedBox(height: 20),

      Text('How do you want to pay?', style: AppTextStyles.label),
      const SizedBox(height: 8),
      ...methods.map((m) => GestureDetector(
        onTap: () => setState(() => _paymentMethod = m['id'] as String),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _paymentMethod == m['id'] ? AppColors.primaryLight : AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _paymentMethod == m['id'] ? AppColors.primary : AppColors.border),
          ),
          child: Row(children: [
            Container(width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _paymentMethod == m['id'] ? AppColors.primary : AppColors.border, width: 2),
              ),
              child: _paymentMethod == m['id']
                  ? Container(margin: const EdgeInsets.all(3), decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
                  : null,
            ),
            const SizedBox(width: 12),
            Icon(m['icon'] as IconData, size: 18, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(m['label'] as String, style: AppTextStyles.body),
          ]),
        ),
      )),

      const SizedBox(height: 16),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Purpose of Transfer', style: AppTextStyles.label),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _purpose,
          decoration: const InputDecoration(),
          items: const [
            DropdownMenuItem(value: 'family_support', child: Text('Family Support')),
            DropdownMenuItem(value: 'education', child: Text('Education')),
            DropdownMenuItem(value: 'medical', child: Text('Medical')),
            DropdownMenuItem(value: 'business', child: Text('Business')),
            DropdownMenuItem(value: 'gift', child: Text('Gift')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (v) => setState(() => _purpose = v!),
        ),
      ]),

      const SizedBox(height: 16),
      AppTextField(
        label: 'Note (optional)',
        hint: 'Message to recipient...',
        initialValue: _note,
        maxLines: 2,
        maxLength: 200,
        onChanged: (v) => _note = v,
      ),

      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: AppButton(label: 'Back', onPressed: () => setState(() => _step = 1), isOutlined: true)),
        const SizedBox(width: 12),
        Expanded(child: AppButton(label: 'Review', onPressed: () => setState(() => _step = 3))),
      ]),
    ]);
  }

  // Step 3: Review
  Widget _buildStep3() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Review Transfer', style: AppTextStyles.h3),
      const SizedBox(height: 20),

      AppCard(
        child: Column(children: [
          _qRow('You Send', '\$${_sendAmount.toStringAsFixed(2)} $_sendCurrency'),
          _qRow('Transfer Fee', '\$${_quote?['transferFee'] ?? 0}'),
          _qRow('Total Deducted', '\$${_quote?['totalDeducted'] ?? 0}'),
          const Divider(height: 20),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Recipient Gets', style: AppTextStyles.h4),
            Text('${_quote?['receiveAmount'] ?? 0} $_receiveCurrency',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary, fontFamily: 'DMSans')),
          ]),
        ]),
      ),

      const SizedBox(height: 12),

      if (_selectedBeneficiary != null)
        AppCard(
          color: AppColors.primaryLight,
          child: Row(children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(_selectedBeneficiary!.initials, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_selectedBeneficiary!.fullName, style: AppTextStyles.label),
              Text('${_selectedBeneficiary!.country} · ${_payoutMethod.replaceAll('_', ' ')}', style: AppTextStyles.caption),
            ]),
          ]),
        ),

      const SizedBox(height: 12),

      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: AppColors.warning, size: 16),
          SizedBox(width: 8),
          Expanded(child: Text('Please verify all details before confirming.',
            style: TextStyle(fontSize: 12, color: AppColors.warning))),
        ]),
      ),

      const SizedBox(height: 24),
      Row(children: [
        Expanded(child: AppButton(label: 'Back', onPressed: () => setState(() => _step = 2), isOutlined: true)),
        const SizedBox(width: 12),
        Expanded(child: AppButton(
          label: 'Confirm & Send',
          icon: Icons.send_rounded,
          onPressed: _submit,
          isLoading: _submitting,
        )),
      ]),
    ]);
  }
}
