// lib/features/rates/screens/rates_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_services.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_widgets.dart';

final _ratesCurrencyProvider = StateProvider<String>((ref) => 'USD');
final _ratesAmountProvider = StateProvider<double>((ref) => 100);

final ratesProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final from = ref.watch(_ratesCurrencyProvider);
  return ExchangeApiService().getRates(from: from);
});

final countriesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final res = await ExchangeApiService().getCountries();
  return (res['countries'] as List).cast<Map<String, dynamic>>();
});

class RatesScreen extends ConsumerWidget {
  const RatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final baseCurrency = ref.watch(_ratesCurrencyProvider);
    final amount = ref.watch(_ratesAmountProvider);
    final ratesAsync = ref.watch(ratesProvider);
    final countriesAsync = ref.watch(countriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exchange Rates'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () {
            ref.invalidate(ratesProvider);
          }),
        ],
      ),
      body: Column(
        children: [
          // Calculator header
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.primaryDark]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Quick Calculator', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
              const SizedBox(height: 10),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: baseCurrency,
                    dropdownColor: AppColors.primaryDark,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                    underline: const SizedBox(),
                    items: ['USD','GBP','EUR','CAD','AUD']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => ref.read(_ratesCurrencyProvider.notifier).state = v!,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: TextEditingController(text: amount.toString()),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.15),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    onChanged: (v) => ref.read(_ratesAmountProvider.notifier).state = double.tryParse(v) ?? 0,
                  ),
                ),
              ]),
            ]),
          ),

          Expanded(
            child: countriesAsync.when(
              loading: () => const AppLoader(),
              error: (e, _) => AppErrorWidget(message: e.toString()),
              data: (countries) => ratesAsync.when(
                loading: () => const AppLoader(),
                error: (e, _) => AppErrorWidget(message: e.toString()),
                data: (ratesData) {
                  final rates = ratesData['rates'] as Map<String, dynamic>? ?? {};
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: countries.length,
                    itemBuilder: (_, i) {
                      final c = countries[i];
                      final currency = c['currency'] as String;
                      final rate = (rates[currency] as num?)?.toDouble();
                      if (rate == null) return const SizedBox.shrink();

                      return AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          Text(c['flag'] ?? '', style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(c['name'] as String, style: AppTextStyles.label),
                            Text(currency, style: AppTextStyles.caption),
                          ])),
                          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                            Text(rate.toStringAsFixed(4), style: AppTextStyles.h4),
                            Text(
                              '${(amount * rate).toStringAsFixed(2)} $currency',
                              style: const TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ]),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
