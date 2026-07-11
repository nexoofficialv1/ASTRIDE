import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';

class DriverEarningsScreen extends StatelessWidget {
  const DriverEarningsScreen({super.key, required this.controller});
  final DriverController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(controller.t('earnings'))),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: AstrideColors.navy, borderRadius: BorderRadius.circular(24)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(controller.t('availableBalance'), style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 5),
                  Text(
                    '₹${controller.walletBalance.toStringAsFixed(0)}',
                    style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 18),
                  FilledButton(onPressed: () => _settle(context), child: Text(controller.t('requestSettlement'))),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(controller.t('earningsOverview'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AstrideColors.navy)),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  _EarningRow(controller.t('grossEarnings'), '₹750'),
                  const Divider(height: 1),
                  _EarningRow(controller.t('commission'), '− ₹65'),
                  const Divider(height: 1),
                  _EarningRow(controller.t('netEarnings'), '₹685', bold: true),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(controller.t('recentTransactions'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: AstrideColors.navy)),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.add_circle, color: AstrideColors.green),
                    title: Text(controller.t('rideEarning')),
                    subtitle: const Text('Station → Hospital'),
                    trailing: const Text('+₹25', style: TextStyle(fontWeight: FontWeight.w800, color: AstrideColors.green)),
                  ),
                  ListTile(
                    leading: const Icon(Icons.remove_circle_outline, color: AstrideColors.orange),
                    title: Text(controller.t('platformCommission')),
                    subtitle: Text(controller.t('today')),
                    trailing: const Text('−₹65', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  void _settle(BuildContext context) {
    final amount = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(sheetContext).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(controller.t('requestSettlement'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            TextField(controller: amount, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: controller.t('amount'))),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () async {
                await controller.requestSettlement(double.tryParse(amount.text) ?? 0);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              child: Text(controller.t('submit')),
            ),
          ],
        ),
      ),
    );
  }
}

class _EarningRow extends StatelessWidget {
  const _EarningRow(this.label, this.value, {this.bold = false});
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600, color: bold ? AstrideColors.navy : null)),
          ],
        ),
      );
}
