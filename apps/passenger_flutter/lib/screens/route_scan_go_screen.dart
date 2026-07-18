import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../design/astride_theme.dart';
import '../services/api_client.dart';
import '../state/passenger_controller.dart';

class RouteScanGoScreen extends StatefulWidget {
  const RouteScanGoScreen({super.key, required this.controller});

  final PassengerController controller;

  @override
  State<RouteScanGoScreen> createState() => _RouteScanGoScreenState();
}

class _RouteScanGoScreenState extends State<RouteScanGoScreen> {
  bool _working = false;

  Future<void> _scan() async {
    final qr = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const _VehicleQrScanner()),
    );
    if (!mounted || qr == null || qr.isEmpty) return;
    await _perform(() => widget.controller.scanRouteVehicle(qr));
  }

  Future<void> _end() async {
    await _perform(widget.controller.endRouteRide);
  }

  Future<void> _perform(
    Future<Map<String, dynamic>> Function() action,
  ) async {
    if (_working) return;
    setState(() => _working = true);
    try {
      final result = await action();
      if (!mounted) return;
      final actionName = '${result['action'] ?? ''}';
      final fare = result['fare'] is Map
          ? (result['fare'] as Map).cast<String, dynamic>()
          : const <String, dynamic>{};
      final duplicateSuppressed = result['duplicateSuppressed'] == true;
      final message = duplicateSuppressed
          ? 'Duplicate scan ignored. Your current route ride remains unchanged.'
          : actionName == 'STARTED'
              ? 'Scan & Go ride started successfully.'
              : 'Ride completed. Fare ₹${fare['amount'] ?? '-'}.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      setState(() {});
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error.code ?? error.message))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The secure Scan & Go operation could not be completed. Please retry.')),
      );
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  String _friendlyError(String value) {
    const messages = <String, String>{
      'vehicle_not_nearby': 'Move closer to the ASTRIDE route vehicle and scan again.',
      'vehicle_stale_location': 'The vehicle location is not updating. Ask the Driver to keep the Driver App online.',
      'route_trip_not_active': 'This vehicle has not started its route trip yet.',
      'route_vehicle_full': 'This route vehicle is currently full.',
      'insufficient_wallet_balance_for_route_entry': 'Your ASTRIDE Ride Credit does not have the minimum route balance.',
      'passenger_active_on_other_route_vehicle': 'End your current route ride before boarding another vehicle.',
      'location_accuracy_too_low': 'Location accuracy is too low. Move to an open area and retry.',
      'route_scan_cooldown': 'The previous scan was just completed. Wait a few seconds before scanning again.',
      'route_travel_wrong_direction': 'This tap-out point is behind the boarding point for the active route direction.',
      'route_access_persistence_failed': 'The secure ride record could not be saved. Retry with the same screen when the service is ready.',
    };
    return messages[value] ?? 'The route operation was not accepted. Please retry or contact ASTRIDE support.';
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.controller.activeRouteRide;
    final services = widget.controller.routeServices;
    return Scaffold(
      appBar: AppBar(title: const Text('Route Scan & Go')),
      body: RefreshIndicator(
        onRefresh: widget.controller.refreshRouteAccess,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
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
                  const Icon(Icons.qr_code_scanner_rounded,
                      size: 38, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    active == null ? 'Board a route vehicle' : 'Route ride active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    active == null
                        ? 'Scan the QR inside an ASTRIDE route vehicle. Your fresh GPS and the vehicle GPS must match.'
                        : '${active['route']?['name'] ?? 'ASTRIDE Route'} • ${active['vehicle']?['vehicleRegistration'] ?? ''}',
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (active != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active journey',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 12),
                      _InfoRow('Boarded at', '${active['startStop']?['name'] ?? '-'}'),
                      _InfoRow('Direction', '${active['trip']?['direction'] ?? '-'}'),
                      _InfoRow('Vehicle', '${active['vehicle']?['vehicleRegistration'] ?? '-'}'),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: _working ? null : _end,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('End ride at current location'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _working ? null : _scan,
                          icon: const Icon(Icons.qr_code_scanner_rounded),
                          label: const Text('Scan the same vehicle QR to end'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _working ? null : _scan,
                  icon: const Icon(Icons.qr_code_scanner_rounded),
                  label: Text(_working ? 'Verifying…' : 'Scan vehicle QR'),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const Text('Active route services',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
            const SizedBox(height: 10),
            if (services.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text('No active ASTRIDE route vehicle is reporting service right now.'),
                ),
              )
            else
              ...services.map((item) {
                final route = item['route'] is Map ? item['route'] as Map : const {};
                final trip = item['trip'] is Map ? item['trip'] as Map : const {};
                final vehicle = item['vehicle'] is Map ? item['vehicle'] as Map : const {};
                final nfc = vehicle['nfcCapability'] is Map
                    ? vehicle['nfcCapability'] as Map
                    : const {};
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.alt_route_rounded)),
                    title: Text('${route['name'] ?? 'ASTRIDE Route'}'),
                    subtitle: Text(
                      '${vehicle['vehicleRegistration'] ?? '-'} • '
                      '${trip['direction'] ?? '-'} • '
                      '${trip['occupied'] ?? 0}/${trip['capacity'] ?? 0} seats\n'
                      'Scan & Go${nfc['tapGoReady'] == true ? ' + NFC Tap & Go' : ''}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }),
            const SizedBox(height: 20),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Security: a copied QR cannot start a ride from another location. ASTRIDE checks fresh Passenger GPS, fresh vehicle GPS, route assignment, capacity, Ride Credit hold and duplicate requests before accepting the scan.',
                  style: TextStyle(height: 1.45),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
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

class _VehicleQrScanner extends StatefulWidget {
  const _VehicleQrScanner();

  @override
  State<_VehicleQrScanner> createState() => _VehicleQrScannerState();
}

class _VehicleQrScannerState extends State<_VehicleQrScanner>
    with WidgetsBindingObserver {
  final MobileScannerController _scanner = MobileScannerController(
    autoStart: false,
    formats: const [BarcodeFormat.qrCode],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  StreamSubscription<BarcodeCapture>? _subscription;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _subscription = _scanner.barcodes.listen(_onCapture);
    unawaited(_scanner.start());
  }

  void _onCapture(BarcodeCapture capture) {
    if (_finished || capture.barcodes.isEmpty) return;
    final value = capture.barcodes.first.rawValue?.trim() ?? '';
    if (value.isEmpty || value.length > 2048) return;
    _finished = true;
    unawaited(_scanner.stop());
    Navigator.pop(context, value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_scanner.value.hasCameraPermission) return;
    if (state == AppLifecycleState.resumed) {
      _subscription ??= _scanner.barcodes.listen(_onCapture);
      unawaited(_scanner.start());
    } else if (state == AppLifecycleState.inactive) {
      unawaited(_subscription?.cancel());
      _subscription = null;
      unawaited(_scanner.stop());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_subscription?.cancel());
    unawaited(_scanner.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('Scan ASTRIDE vehicle QR'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(controller: _scanner, onDetect: (_) {}),
            Center(
              child: Container(
                width: 270,
                height: 270,
                decoration: BoxDecoration(
                  border: Border.all(color: AstrideColors.green, width: 4),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
            const Positioned(
              left: 24,
              right: 24,
              bottom: 44,
              child: Text(
                'Scan only the QR sticker fixed inside the ASTRIDE route vehicle.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
}
