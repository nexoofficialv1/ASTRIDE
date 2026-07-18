import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../services/api_client.dart';
import '../state/driver_controller.dart';

class RouteServiceScreen extends StatefulWidget {
  const RouteServiceScreen({super.key, required this.controller});
  final DriverController controller;

  @override
  State<RouteServiceScreen> createState() => _RouteServiceScreenState();
}

class _RouteServiceScreenState extends State<RouteServiceScreen> {
  String _direction = 'UP';

  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) setState(() {});
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message.replaceAll('_', ' '))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The secure route operation could not be completed. Please retry.')),
      );
    }
  }

  Future<void> _tapCard() async {
    try {
      final result = await widget.controller.tapPrepaidCard();
      if (!mounted) return;
      final fare = result['fare'] is Map ? result['fare'] as Map : const {};
      final action = '${result['action'] ?? ''}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(action == 'STARTED'
              ? 'Card ride started.'
              : 'Card ride completed. Fare ₹${fare['amount'] ?? '-'}.'),
        ),
      );
      setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The card transaction could not be completed. No fare was charged.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final vehicle = c.routeVehicle;
    final route = c.routeInfo;
    final trip = c.routeTrip;
    return Scaffold(
      appBar: AppBar(title: const Text('Route Service')),
      body: RefreshIndicator(
        onRefresh: c.refreshRouteService,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (vehicle == null)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(
                    'No route vehicle has been assigned to this Driver. Admin must assign a verified route and vehicle first.',
                    style: TextStyle(height: 1.45),
                  ),
                ),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AstrideColors.navy, Color(0xFF17396F)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ASTRIDE ROUTE SERVICE',
                        style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text('${route?['name'] ?? 'Assigned route'}',
                        style: const TextStyle(color: Colors.white, fontSize: 23, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Text('${vehicle['vehicleRegistration'] ?? '-'} • Capacity ${vehicle['capacity'] ?? '-'}',
                        style: const TextStyle(color: Colors.white70)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Chip(label: Text('QR SCAN & GO')),
                        Chip(
                          avatar: Icon(c.nfcAvailable ? Icons.nfc : Icons.nfc_outlined, size: 18),
                          label: Text(c.cardTapGoReady
                              ? 'NFC TAP & GO READY'
                              : (c.nfcAvailable
                                  ? 'NFC DETECTED • SECURE READER PENDING'
                                  : 'NFC UNAVAILABLE')),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              if (trip == null) ...[
                DropdownButtonFormField<String>(
                  initialValue: _direction,
                  decoration: const InputDecoration(labelText: 'Route direction'),
                  items: const [
                    DropdownMenuItem(value: 'UP', child: Text('UP')),
                    DropdownMenuItem(value: 'DOWN', child: Text('DOWN')),
                  ],
                  onChanged: (value) => setState(() => _direction = value ?? 'UP'),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: c.routeServiceBusy
                        ? null
                        : () => _run(() => c.startRouteTrip(_direction)),
                    icon: const Icon(Icons.play_circle_outline_rounded),
                    label: const Text('Start route trip'),
                  ),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _Line('Trip status', '${trip['status'] ?? '-'}'),
                        _Line('Direction', '${trip['direction'] ?? '-'}'),
                        _Line('Digital passengers', '${c.routePassengers.length}/${trip['capacity'] ?? '-'}'),
                        _Line('Started', '${trip['startedAt'] ?? '-'}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (c.nfcAvailable && c.cardTapGoReady)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: c.routeServiceBusy ? null : _tapCard,
                      icon: const Icon(Icons.nfc_rounded),
                      label: const Text('Tap ASTRIDE prepaid card'),
                    ),
                  )
                else
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        c.nfcAvailable
                            ? 'NFC hardware is detected, but physical-card Tap & Go remains disabled until ASTRIDE verifies the secure DESFire reader/authentication profile. App passengers can use vehicle QR Scan & Go.'
                            : 'This phone has no active NFC. App passengers can still use vehicle QR Scan & Go.',
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: c.routeServiceBusy || c.routePassengers.isNotEmpty
                        ? null
                        : () => _run(c.endRouteTrip),
                    icon: const Icon(Icons.stop_circle_outlined),
                    label: Text(c.routePassengers.isNotEmpty
                        ? 'Passengers must tap/scan out first'
                        : 'End route trip'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              const Text('Onboard digital passengers',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 10),
              if (c.routePassengers.isEmpty)
                const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('No active digital passenger.')))
              else
                ...c.routePassengers.map((ride) => Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(ride['cardId'] != null ? Icons.nfc : Icons.qr_code_rounded),
                        ),
                        title: Text(ride['cardId'] != null ? 'Prepaid Card Rider' : 'App Scan & Go Rider'),
                        subtitle: Text('Boarded: ${ride['startStop']?['name'] ?? '-'}\nRide: ${ride['id'] ?? '-'}'),
                        isThreeLine: true,
                      ),
                    )),
              const SizedBox(height: 18),
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'The Driver cannot set fares or debit balances. The server validates route assignment, fresh location, capacity, card/Passenger active-trip lock, idempotency and settlement.',
                    style: TextStyle(height: 1.45),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(color: AstrideColors.muted))),
            Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w800))),
          ],
        ),
      );
}
