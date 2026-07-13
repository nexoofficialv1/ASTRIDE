import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/passenger_controller.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.controller});
  final PassengerController controller;

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  late Future<List<Map<String, dynamic>>> future;

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
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Wallet')),
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
                          'Available balance',
                          style: TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          money(wallet['availablePaise']),
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
                                label: 'Promo',
                                value: money(wallet['promoPaise']),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _BalanceTile(
                                label: 'Pending',
                                value: money(wallet['pendingPaise']),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
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
