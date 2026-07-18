import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../services/api_client.dart';
import '../services/payment_gateway.dart';
import '../state/passenger_controller.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.controller});
  final PassengerController controller;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<List<Map<String, dynamic>>> future;
  final PaymentGateway paymentGateway = PaymentGateway();

  @override
  void initState() {
    super.initState();
    future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final wallet = await widget.controller.wallet();
    final transactions = await widget.controller.walletTransactions();
    return [
      ((wallet['wallet'] ?? wallet) as Map).cast<String, dynamic>(),
      ...((transactions['items'] ?? const []) as List)
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>()),
    ];
  }

  String money(dynamic paise) =>
      '₹${((num.tryParse('$paise') ?? 0) / 100).toStringAsFixed(2)}';

  Future<void> _refresh() async {
    setState(() => future = _load());
    await future;
  }

  @override
  void dispose() {
    paymentGateway.dispose();
    super.dispose();
  }

  Future<void> _recharge() async {
    final amount = TextEditingController();
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recharge ASTRIDE Ride Credit'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Credit is added only after trusted bank/UPI confirmation. A screenshot cannot create balance.'),
          const SizedBox(height: 12),
          TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Amount ₹')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Pay securely')),
        ],
      ),
    );
    if (accepted != true) return;
    final rupees = int.tryParse(amount.text.trim());
    if (rupees == null) return;
    try {
      await widget.controller.rechargeRideCredit(paymentGateway, rupees * 100);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Verified Ride Credit added successfully.')));
      await _refresh();
    } on ApiException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message)));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recharge could not be completed. Please retry safely.')));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('ASTRIDE Ride Credit')),
        body: RefreshIndicator(
          onRefresh: _refresh,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return ListView(
                  children: const [
                    SizedBox(height: 260),
                    Center(child: CircularProgressIndicator()),
                  ],
                );
              }
              if (snapshot.hasError) {
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    const SizedBox(height: 150),
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: AstrideColors.muted,
                    ),
                    const SizedBox(height: 18),
                    Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _refresh,
                      child: const Text('Try again'),
                    ),
                  ],
                );
              }

              final data = snapshot.data ?? const [];
              final wallet = data.isEmpty ? <String, dynamic>{} : data.first;
              final tx = data.skip(1).toList();

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          AstrideColors.navy,
                          AstrideColors.navySoft,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Available Ride Credit',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          money(wallet['availableBalancePaise'] ?? wallet['availablePaise']),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            Expanded(
                              child: _BalanceTile(
                                label: 'Total balance',
                                value: money(wallet['balancePaise']),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _BalanceTile(
                                label: 'Fare held',
                                value: money(wallet['heldBalancePaise']),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(onPressed: _recharge, icon: const Icon(Icons.add_card_rounded), label: const Text('Recharge Ride Credit')),
                  const SizedBox(height: 8),
                  const Text('Ride Credit is non-transferable, cannot be withdrawn as cash, and can be used only for ASTRIDE rides.', style: TextStyle(color: AstrideColors.muted)),
                  const SizedBox(height: 18),
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AstrideColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (tx.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 46,
                              color: AstrideColors.muted,
                            ),
                            SizedBox(height: 10),
                            Text('No wallet transactions yet'),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final item in tx)
                      Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                (num.tryParse('${item['amountPaise']}') ?? 0) >= 0
                                    ? AstrideColors.successTint
                                    : const Color(0xFFFFF0F0),
                            child: Icon(
                              (num.tryParse('${item['amountPaise']}') ?? 0) >= 0
                                  ? Icons.south_west_rounded
                                  : Icons.north_east_rounded,
                              color:
                                  (num.tryParse('${item['amountPaise']}') ?? 0) >=
                                          0
                                      ? AstrideColors.greenDark
                                      : AstrideColors.danger,
                            ),
                          ),
                          title: Text(
                            '${item['description'] ?? item['type'] ?? 'Transaction'}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          subtitle: Text('${item['createdAt'] ?? ''}'),
                          trailing: Text(
                            money(item['amountPaise']),
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AstrideColors.navy,
                            ),
                          ),
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      );
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}
