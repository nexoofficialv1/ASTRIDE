import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/driver_controller.dart';

class NewRideRequestScreen extends StatefulWidget {
  const NewRideRequestScreen({
    super.key,
    required this.controller,
  });

  final DriverController controller;

  @override
  State<NewRideRequestScreen> createState() =>
      _NewRideRequestScreenState();
}

class _NewRideRequestScreenState
    extends State<NewRideRequestScreen> {
  bool accepting = false;

  DriverController get c => widget.controller;

  String locationLabel(dynamic raw, String fallback) {
    if (raw is Map) {
      return '${raw['address'] ??
          raw['name'] ??
          raw['displayName'] ??
          fallback}';
    }
    final text = '$raw'.trim();
    return text.isEmpty || text == 'null' ? fallback : text;
  }

  String fare(dynamic raw) {
    final value = raw is Map
        ? raw['amount'] ?? raw['total'] ?? raw['fare']
        : raw;
    final number = num.tryParse('$value') ?? 0;
    return number.toStringAsFixed(number % 1 == 0 ? 0 : 2);
  }

  Future<void> accept() async {
    setState(() => accepting = true);

    try {
      await c.acceptRequest();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final request = c.request;
    if (request == null) return const SizedBox.shrink();

    final distance = num.tryParse(
          '${request['distanceToPickupKm'] ?? 0}',
        ) ??
        0;

    return Material(
      color: const Color(0xB0000000),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 30,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AstrideColors.navy,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.electric_rickshaw,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'New ride request',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AstrideColors.navy,
                            ),
                          ),
                          Text(
                            '${distance.toStringAsFixed(1)} km away',
                            style: const TextStyle(
                              color: AstrideColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₹${fare(request['fareEstimate'])}',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                        color: AstrideColors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _RouteRow(
                  icon: Icons.radio_button_checked,
                  color: AstrideColors.green,
                  label: 'Pickup',
                  value: locationLabel(
                    request['pickup'],
                    request['pickupAddress']?.toString() ??
                        'Pickup location',
                  ),
                ),
                _RouteRow(
                  icon: Icons.location_on_rounded,
                  color: AstrideColors.orange,
                  label: 'Destination',
                  value: locationLabel(
                    request['destination'],
                    request['destinationAddress']?.toString() ??
                        'Destination',
                  ),
                ),
                const Divider(height: 28),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(
                      icon: Icons.payments_outlined,
                      label:
                          '${request['paymentPreference'] ?? request['paymentMethod'] ?? 'Cash / UPI'}',
                      color: AstrideColors.orange,
                    ),
                    if (request['saferideEnabled'] == true)
                      const _Tag(
                        icon: Icons.shield_outlined,
                        label: 'SafeRide',
                        color: AstrideColors.green,
                      ),
                    _Tag(
                      icon: Icons.electric_rickshaw,
                      label: '${request['rideType'] ?? 'FULL_TOTO'}',
                      color: AstrideColors.navy,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            accepting ? null : c.rejectRequest,
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: accepting ? null : accept,
                        child: accepting
                            ? const SizedBox.square(
                                dimension: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Accept ride'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AstrideColors.muted,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      );
}
