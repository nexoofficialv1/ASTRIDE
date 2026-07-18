import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/passenger_controller.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key, required this.controller});
  final PassengerController controller;

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  late Future<Map<String, dynamic>> future;
  final code = TextEditingController();

  @override
  void initState() {
    super.initState();
    future = widget.controller.offers();
  }

  Future<void> refresh() async {
    setState(() => future = widget.controller.offers());
    await future;
  }

  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Offers & Promotions')),
        body: RefreshIndicator(
          onRefresh: refresh,
          child: FutureBuilder<Map<String, dynamic>>(
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
              final raw = snapshot.data ?? const {};
              final items = (raw['items'] ?? raw['offers'] ?? const []) as List;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Apply promo code',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AstrideColors.navy,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextField(
                            controller: code,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              hintText: 'Enter code',
                              prefixIcon: Icon(Icons.local_offer_outlined),
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton(
                            onPressed: () async {
                              try {
                                final result =
                                    await widget.controller.validateOffer(
                                  code.text,
                                );
                                if (!context.mounted) return;
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text('Offer available'),
                                    content: Text(
                                      '${result['message'] ?? result['discount'] ?? 'This offer can be applied to an eligible ride.'}',
                                    ),
                                    actions: [
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context),
                                        child: const Text('Done'),
                                      ),
                                    ],
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            },
                            child: const Text('Check offer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Available offers',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: AstrideColors.navy,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (snapshot.hasError)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: const Text('Offers could not be loaded. Please try again.'),
                      ),
                    )
                  else if (items.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.local_offer_outlined,
                              size: 48,
                              color: AstrideColors.muted,
                            ),
                            SizedBox(height: 10),
                            Text('No active offers right now'),
                          ],
                        ),
                      ),
                    )
                  else
                    for (final raw in items.whereType<Map>())
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(17),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(color: AstrideColors.border),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              backgroundColor: AstrideColors.successTint,
                              child: Icon(
                                Icons.local_offer_rounded,
                                color: AstrideColors.greenDark,
                              ),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${raw['name'] ?? raw['title'] ?? 'ASTRIDE Offer'}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: AstrideColors.navy,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${raw['description'] ?? raw['terms'] ?? ''}',
                                    style: const TextStyle(
                                      color: AstrideColors.muted,
                                    ),
                                  ),
                                  if (raw['code'] != null) ...[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Code: ${raw['code']}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: AstrideColors.greenDark,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                ],
              );
            },
          ),
        ),
      );
}
