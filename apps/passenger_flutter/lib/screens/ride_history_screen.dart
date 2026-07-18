import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/passenger_controller.dart';
import 'ride_status_screen.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({
    super.key,
    required this.controller,
  });

  final PassengerController controller;

  static const activeStatuses = {
    'SEARCHING',
    'DRIVER_ASSIGNED',
    'DRIVER_ARRIVING',
    'DRIVER_ARRIVED',
    'OTP_VERIFIED',
    'IN_PROGRESS',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Ride history')),
        body: FutureBuilder<Map<String, dynamic>>(
          future: controller.api.getJson(
            '/v1/passengers/${controller.session!.userId}/bookings',
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState !=
                ConnectionState.done) {
              return const Center(
                child: CircularProgressIndicator(),
              );
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
                    .map((item) => item.cast<String, dynamic>())
                    .toList();

            if (items.isEmpty) {
              return const Center(
                child: Text('No rides yet'),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final status = '${item['status'] ?? ''}';
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => _showDetails(context, item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const CircleAvatar(
                            backgroundColor:
                                AstrideColors.successTint,
                            child: Icon(
                              Icons.electric_rickshaw_rounded,
                              color: AstrideColors.greenDark,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _destination(item),
                                  maxLines: 2,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: AstrideColors.navy,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(_formatDate(item['createdAt'])),
                                const SizedBox(height: 8),
                                Text(
                                  status.replaceAll('_', ' '),
                                  style: TextStyle(
                                    color: activeStatuses
                                            .contains(status)
                                        ? AstrideColors.orange
                                        : AstrideColors.greenDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Tap to view ride details',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AstrideColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AstrideColors.muted,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      );

  void _showDetails(
    BuildContext context,
    Map<String, dynamic> item,
  ) {
    final status = '${item['status'] ?? ''}';
    final active = activeStatuses.contains(status);
    final farePaise = num.tryParse('${item['farePaise']}');
    final fareAmount = farePaise != null
        ? farePaise / 100
        : num.tryParse(
              '${item['fareEstimate']?['amount'] ?? item['fareEstimate']?['total'] ?? 0}',
            ) ??
            0;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor:
                          AstrideColors.successTint,
                      child: Icon(
                        Icons.route_rounded,
                        color: AstrideColors.greenDark,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Ride details',
                        style: Theme.of(sheetContext)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pop(sheetContext),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _Detail(
                  label: 'Status',
                  value: status.replaceAll('_', ' '),
                ),
                _Detail(
                  label: 'Ride ID',
                  value: '${item['id'] ?? '-'}',
                ),
                _Detail(
                  label: 'Pickup',
                  value: _pickup(item),
                ),
                _Detail(
                  label: 'Destination',
                  value: _destination(item),
                ),
                _Detail(
                  label: 'Ride type',
                  value: '${item['rideType'] ?? '-'}',
                ),
                _Detail(
                  label: 'Payment',
                  value:
                      '${item['paymentPreference'] ?? item['paymentMethod'] ?? '-'}',
                ),
                _Detail(
                  label: 'Fare',
                  value: '₹${fareAmount.toStringAsFixed(2)}',
                ),
                _Detail(
                  label: 'Booked at',
                  value: _formatDate(item['createdAt']),
                ),
                if (item['driverId'] != null)
                  _Detail(
                    label: 'Driver ID',
                    value: '${item['driverId']}',
                  ),
                if (item['cancellationReason'] != null)
                  _Detail(
                    label: 'Cancellation reason',
                    value: '${item['cancellationReason']}',
                  ),
                if (active) ...[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        controller.resumeBooking(item);
                        Navigator.pop(sheetContext);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RideStatusScreen(
                              controller: controller,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.navigation_rounded),
                      label: const Text('Open live ride'),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _pickup(Map<String, dynamic> item) =>
      _locationText(
        item['pickupAddress'],
        item['pickup'],
        'Pickup not named',
      );

  static String _destination(Map<String, dynamic> item) =>
      _locationText(
        item['destinationAddress'],
        item['destination'],
        'Destination not named',
      );

  static String _locationText(
    dynamic address,
    dynamic point,
    String fallback,
  ) {
    final named = '$address'.trim();
    if (address != null &&
        named.isNotEmpty &&
        named != 'null') {
      return named;
    }
    if (point is Map) {
      final lat = point['lat'];
      final lng = point['lng'];
      if (lat != null && lng != null) {
        return '$lat, $lng';
      }
    }
    return fallback;
  }

  static String _formatDate(dynamic value) {
    final date = DateTime.tryParse('$value')?.toLocal();
    if (date == null) return '$value';
    String two(int number) => number.toString().padLeft(2, '0');
    return '${two(date.day)}-${two(date.month)}-${date.year} '
        '${two(date.hour)}:${two(date.minute)}';
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 115,
              child: Text(
                label,
                style: const TextStyle(
                  color: AstrideColors.muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(
                  color: AstrideColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
}
