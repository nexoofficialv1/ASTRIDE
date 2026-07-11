import 'package:flutter/material.dart';
import '../state/partner_controller.dart';

// Withdrawal opens only after monthly settlement.
class EarningsScreen extends StatelessWidget {
  const EarningsScreen({super.key, required this.c});
  final PartnerController c;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    final e = c.earnings ?? {};
    final amount = (e['amount'] ?? 0).toDouble();
    final withdrawable = (e['withdrawable'] ?? 0).toDouble();
    final pending = (e['pending'] ?? (amount - withdrawable)).toDouble();
    final items = (e['items'] ?? []) as List;

    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0D1B3D), Color(0xFF6D5DFB)]), borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.t('currentEarnings'), style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text('₹$amount', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
                const SizedBox(height: 18),
                Row(children: [Expanded(child: _mini(s.t('withdrawable'), '₹$withdrawable')), Expanded(child: _mini(s.t('pending'), '₹$pending'))]),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(children: [const Icon(Icons.calendar_month_rounded), const SizedBox(width: 10), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.t('nextSettlement')), Text('${e['nextSettlementDate'] ?? '-'}', style: const TextStyle(fontWeight: FontWeight.w900))]))]),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: withdrawable > 0 && !c.busy
                        ? () async {
                            await c.withdraw(withdrawable);
                            if (context.mounted && c.error == null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('bankTransfer'))));
                          }
                        : null,
                    icon: const Icon(Icons.account_balance_rounded),
                    label: Text(s.t('transferBank')),
                  ),
                  if (withdrawable <= 0) Padding(padding: const EdgeInsets.only(top: 10), child: Text(s.t('withdrawLocked'), textAlign: TextAlign.center)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(s.t('transactions'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 8),
          if (items.isEmpty) const Card(child: Padding(padding: EdgeInsets.all(24), child: Center(child: Text('—')))),
          ...items.map((raw) {
            final a = (raw as Map).cast<String, dynamic>();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const CircleAvatar(child: Icon(Icons.currency_rupee_rounded)),
                title: Text((a['type'] ?? s.t('commission')).toString()),
                subtitle: Text((a['status'] ?? s.t('pending')).toString()),
                trailing: Text('₹${a['amount'] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w900)),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)), const SizedBox(height: 3), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16))]);
}
