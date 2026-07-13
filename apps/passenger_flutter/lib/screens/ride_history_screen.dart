import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/passenger_controller.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key, required this.controller});
  final PassengerController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ride history')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: controller.api.getJson(
            '/v1/passengers/${controller.session!.userId}/bookings',
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    snapshot.error.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final items =
                ((snapshot.data?['items'] ?? const []) as List)
                    .whereType<Map>()
                    .toList();

            if (items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(28),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 62,
                        color: AstrideColors.muted,
                      ),
                      SizedBox(height: 14),
                      Text(
                        'No rides yet',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                          color: AstrideColors.navy,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Your completed and cancelled rides will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AstrideColors.muted),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index].cast<String, dynamic>();
                final destination = item['destination'] is Map
                    ? (item['destination'] as Map)
                    : const {};
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const CircleAvatar(
                          backgroundColor: AstrideColors.successTint,
                          child: Icon(
                            Icons.electric_rickshaw_rounded,
                            color: AstrideColors.greenDark,
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${destination['address'] ?? destination['name'] ?? 'Ride'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AstrideColors.navy,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text('${item['createdAt'] ?? ''}'),
                              const SizedBox(height: 8),
                              Text(
                                '${item['status'] ?? ''}',
                                style: const TextStyle(
                                  color: AstrideColors.greenDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (item['farePaise'] != null)
                          Text(
                            '₹${((num.tryParse('${item['farePaise']}') ?? 0) / 100).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AstrideColors.navy,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      );
}
