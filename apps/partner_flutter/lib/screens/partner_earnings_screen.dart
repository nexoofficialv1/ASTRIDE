import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../services/api_client.dart';
import '../state/partner_controller.dart';

class PartnerEarningsScreen extends StatelessWidget {
  const PartnerEarningsScreen({super.key, required this.controller});
  final PartnerController controller;

  Future<void> withdraw(BuildContext context) async {
    final amount = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdrawal request'),
        content: TextField(controller: amount, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount ₹')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Request')),
        ],
      ),
    );
    if (ok != true) return;
    final value = double.tryParse(amount.text);
    if (value == null || value <= 0) return;
    try {
      await controller.requestWithdrawal(value);
    } on ApiException catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = controller.earnings['items'] is List ? controller.earnings['items'] as List : const [];
    return RefreshIndicator(
      onRefresh: controller.refreshAll,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Total commission', style: TextStyle(color: AstrideColors.muted)),
          Text('₹${controller.earnings['amount'] ?? 0}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AstrideColors.navy)),
          const SizedBox(height: 12),
          Text('Withdrawable ₹${controller.earnings['withdrawable'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700, color: AstrideColors.greenDark)),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => withdraw(context), icon: const Icon(Icons.account_balance_wallet_outlined), label: const Text('Request withdrawal')),
        ]))),
        const SizedBox(height: 16),
        const Text('Earning entries', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No earning entry yet'))),
        ...items.whereType<Map>().map((raw) {
          final item = raw.cast<String, dynamic>();
          return Card(child: ListTile(
            title: Text('₹${item['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w800)),
            subtitle: Text('${item['type'] ?? 'COMMISSION'} • ${item['status'] ?? ''}'),
            trailing: Text((item['month'] ?? '').toString()),
          ));
        }),
        const SizedBox(height: 16),
        const Text('Withdrawal requests', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        if (controller.withdrawals.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('No withdrawal request'))),
        ...controller.withdrawals.map((item) => Card(child: ListTile(
          title: Text('₹${item['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w800)),
          subtitle: Text((item['status'] ?? '').toString()),
        ))),
      ]),
    );
  }
}
