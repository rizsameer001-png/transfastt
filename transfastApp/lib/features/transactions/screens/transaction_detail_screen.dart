// lib/features/transactions/screens/transaction_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';
import '../models/transaction_model.dart';

class TransactionDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const TransactionDetailScreen({super.key, required this.id});

  @override
  ConsumerState<TransactionDetailScreen> createState() => _TransactionDetailScreenState();
}

class _TransactionDetailScreenState extends ConsumerState<TransactionDetailScreen> {
  TransactionModel? _txn;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTxn();
  }

  Future<void> _loadTxn() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await TransferApiService().getTransferById(widget.id);
      setState(() => _txn = TransactionModel.fromJson(res['transaction']));
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _cancelTxn() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Transfer?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await TransferApiService().cancelTransfer(widget.id);
      _loadTxn();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transfer Details'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _loadTxn),
        ],
      ),
      body: _loading
          ? const AppLoader()
          : _error != null
          ? AppErrorWidget(message: _error!, onRetry: _loadTxn)
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    final txn = _txn!;
    final steps = ['pending', 'processing', 'sent', 'delivered'];
    final currentStepIdx = steps.indexOf(txn.status);
    final isFailed = ['failed', 'cancelled'].contains(txn.status);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Amount hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('You Sent', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                const SizedBox(height: 4),
                Text('\$${txn.sendAmount.toStringAsFixed(2)} ${txn.sendCurrency}',
                  style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800, fontFamily: 'DMSans')),
              ]),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('They Received', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12)),
                const SizedBox(height: 4),
                Text('${txn.receiveAmount.toStringAsFixed(0)} ${txn.receiveCurrency}',
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700, fontFamily: 'DMSans')),
              ]),
            ]),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('1 ${txn.sendCurrency} = ${txn.exchangeRate} ${txn.receiveCurrency}',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
                const SizedBox(width: 16),
                Text('Fee: \$${txn.transferFee}',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 12)),
              ]),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // TXN ID copy
        AppCard(
          child: Row(children: [
            const Icon(Icons.tag_rounded, size: 18, color: AppColors.textHint),
            const SizedBox(width: 8),
            Expanded(child: Text(txn.transactionId, style: AppTextStyles.bodySm)),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: txn.transactionId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Transaction ID copied'), duration: Duration(seconds: 1)),
                );
              },
              child: const Icon(Icons.copy_rounded, size: 16, color: AppColors.textHint),
            ),
          ]),
        ),

        const SizedBox(height: 16),

        // Status tracker or failed banner
        if (!isFailed) ...[
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Transfer Status', style: AppTextStyles.h4),
              const SizedBox(height: 20),
              Row(children: steps.asMap().entries.map((entry) {
                final i = entry.key;
                final step = entry.value;
                final isDone = i < currentStepIdx;
                final isCurrent = i == currentStepIdx;
                return Expanded(child: Row(children: [
                  Column(children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 30, height: 30,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.success : isCurrent ? AppColors.primary : AppColors.border,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDone ? Icons.check_rounded : isCurrent ? Icons.access_time_rounded : Icons.circle_outlined,
                        size: 14, color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(step[0].toUpperCase() + step.substring(1),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                        color: isCurrent ? AppColors.primary : AppColors.textHint,
                      )),
                  ]),
                  if (i < steps.length - 1)
                    Expanded(child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 20),
                      color: isDone ? AppColors.success : AppColors.border,
                    )),
                ]));
              }).toList()),
              if (txn.estimatedDelivery != null) ...[
                const SizedBox(height: 12),
                Text('Est. delivery: ${DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.tryParse(txn.estimatedDelivery!) ?? DateTime.now())}',
                  style: AppTextStyles.caption, textAlign: TextAlign.center),
              ],
            ]),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.error.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.cancel_rounded, color: AppColors.error),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Transfer ${txn.status.toUpperCase()}', style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700)),
                if (txn.flaggedReason != null) Text(txn.flaggedReason!, style: AppTextStyles.bodySm),
              ])),
            ]),
          ),
        ],

        if (txn.isFlagged) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.warning.withOpacity(0.3)),
            ),
            child: Row(children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 20),
              const SizedBox(width: 10),
              const Expanded(child: Text('This transaction is under security review', style: AppTextStyles.body)),
            ]),
          ),
        ],

        const SizedBox(height: 16),

        // Details
        AppCard(
          child: Column(children: [
            InfoRow(label: 'Recipient', value: txn.beneficiaryName),
            InfoRow(label: 'Destination', value: txn.receiveCountry),
            InfoRow(label: 'Payout Method', value: txn.payoutMethod.replaceAll('_', ' ').toUpperCase()),
            InfoRow(label: 'Payment Method', value: txn.paymentMethod.replaceAll('_', ' ').toUpperCase()),
            InfoRow(label: 'Purpose', value: txn.transferPurpose.replaceAll('_', ' ')),
            InfoRow(label: 'Transfer Fee', value: '\$${txn.transferFee}'),
            InfoRow(
              label: 'Date',
              value: DateFormat('MMM dd, yyyy hh:mm a').format(DateTime.tryParse(txn.createdAt) ?? DateTime.now()),
              isLast: true,
            ),
          ]),
        ),

        if (txn.senderNote != null) ...[
          const SizedBox(height: 12),
          AppCard(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Your Note', style: AppTextStyles.bodySm),
              const SizedBox(height: 4),
              Text(txn.senderNote!, style: AppTextStyles.body),
            ]),
          ),
        ],

        if (txn.status == 'pending') ...[
          const SizedBox(height: 20),
          AppButton(
            label: 'Cancel Transfer',
            onPressed: _cancelTxn,
            color: AppColors.error,
          ),
        ],
        const SizedBox(height: 16),
      ]),
    );
  }
}
