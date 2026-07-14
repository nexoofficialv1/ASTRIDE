import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/astride_theme.dart';
import '../services/live_service.dart';
import '../services/payment_gateway.dart';
import '../state/passenger_controller.dart';
import '../widgets/common/astride_map_canvas.dart';
import 'ride/ride_completed_screen.dart';

class RideStatusScreen extends StatefulWidget {
  const RideStatusScreen({
    super.key,
    required this.controller,
  });

  final PassengerController controller;

  @override
  State<RideStatusScreen> createState() =>
      _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen> {
  final live = LiveService();
  final paymentGateway = PaymentGateway();
  StreamSubscription<Map<String, dynamic>>? subscription;
  Timer? dispatchPoller;

  String status = 'SEARCHING';
  int nearbyCount = 0;
  double searchRadiusKm = 0;
  List<LatLng> nearbyDriverPoints = const [];
  Map<String, dynamic>? assignedDriver;

  @override
  void initState() {
    super.initState();
    status =
        '${widget.controller.activeBooking?['status'] ?? 'SEARCHING'}';
    final id = widget.controller.activeBooking?['id']?.toString();
    if (id != null && id.isNotEmpty) {
      final token = widget.controller.session?.token;
      if (token != null && token.isNotEmpty) {
        live.connect(id, token);
      }
      subscription = live.events.listen((event) {
        if (!mounted) return;
        final rawBooking = event['booking'];
        if (rawBooking is Map) {
          final booking = rawBooking.cast<String, dynamic>();
          widget.controller.resumeBooking(booking);
          final next = '${booking['status'] ?? status}';
          setState(() => status = next);
          if (next == 'COMPLETED') _openCompleted();
          return;
        }
        unawaited(_refreshDispatch());
      });
    }
    _refreshDispatch();
    dispatchPoller = Timer.periodic(
      const Duration(seconds: 2),
      (_) => unawaited(_refreshDispatch()),
    );
  }

  @override
  void dispose() {
    subscription?.cancel();
    dispatchPoller?.cancel();
    live.dispose();
    paymentGateway.dispose();
    super.dispose();
  }

  bool get paymentPending => status == 'PAYMENT_PENDING';

  bool get searching => status == 'SEARCHING';

  bool get inProgress =>
      status == 'IN_PROGRESS' ||
      status == 'RIDE_IN_PROGRESS';

  @override
  Widget build(BuildContext context) {
    final t = widget.controller.t;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: AstrideMapCanvas(
              center:
                  _pickupPoint ?? const LatLng(23.2196, 88.3628),
              pickup: _pickupPoint,
              showRoute: !searching,
              showDrivers: true,
              driverPoints: nearbyDriverPoints,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(
                    children: [
                      Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: () =>
                              Navigator.maybePop(context),
                          icon:
                              const Icon(Icons.arrow_back_rounded),
                        ),
                      ),
                      const Spacer(),
                      Material(
                        color: Colors.white,
                        shape: const StadiumBorder(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 9,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.shield_rounded,
                                color: AstrideColors.green,
                              ),
                              const SizedBox(width: 6),
                              Text(t('safety.safeRide')),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: searching
                          ? _searchingCard(t)
                          : _driverCard(t),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _searchingCard(String Function(String) t) => Column(
        children: [
          SizedBox(
            width: 74,
            height: 74,
            child: Stack(
              alignment: Alignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 5,
                  color: AstrideColors.green,
                ),
                Container(
                  width: 54,
                  height: 54,
                  decoration: const BoxDecoration(
                    color: AstrideColors.navy,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.electric_rickshaw_rounded,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            t('ride.searchingNearby'),
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: AstrideColors.navy,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t('ride.searchingBody'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AstrideColors.muted),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: nearbyCount > 0
                  ? const Color(0x1422C55E)
                  : const Color(0x14F59E0B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              nearbyCount > 0
                  ? '$nearbyCount eligible free driver(s) within '
                      '${searchRadiusKm.toStringAsFixed(0)} km'
                  : 'No free verified driver within '
                      '${searchRadiusKm.toStringAsFixed(0)} km yet. '
                      'ASTRIDE Admin can also assign an eligible driver.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AstrideColors.navy,
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _cancel,
              child: Text(t('cancelRide')),
            ),
          ),
        ],
      );

  Widget _driverCard(String Function(String) t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Color(0x1422C55E),
                child: Icon(
                  Icons.person_rounded,
                  color: AstrideColors.green,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      inProgress
                          ? t('ride.inProgress')
                          : t('driverArriving'),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AstrideColors.navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${assignedDriver?['fullName'] ?? 'Assigned Driver'}'
                      ' • '
                      '${assignedDriver?['vehicle']?['number'] ?? 'Vehicle details pending'}',
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          color: AstrideColors.orange,
                          size: 17,
                        ),
                        Text(
                          ' ${assignedDriver?['rating'] ?? 5}'
                          '  •  Trusted Driver',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: _callDriver,
                icon: const Icon(Icons.call_rounded),
              ),
              const SizedBox(width: 6),
              IconButton.filledTonal(
                onPressed: _messageDriver,
                icon: const Icon(
                  Icons.chat_bubble_outline_rounded,
                ),
              ),
            ],
          ),
          const Divider(height: 26),
          Row(
            children: [
              _metric(
                Icons.schedule_rounded,
                inProgress ? 'In progress' : 'Driver assigned',
                t('ride.eta'),
              ),
              _metric(
                Icons.route_rounded,
                _distanceLabel,
                t('ride.distance'),
              ),
              _metric(
                Icons.payments_outlined,
                '${widget.controller.activeBooking?['paymentPreference'] ?? widget.controller.activeBooking?['paymentMethod'] ?? 'Cash / UPI'}',
                t('payment.title'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (paymentPending) ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _payPendingUpi,
                icon: const Icon(Icons.account_balance_wallet_outlined),
                label: const Text('Pay by UPI to search for a Driver'),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareTrip,
                  icon: const Icon(Icons.share_location_rounded),
                  label: Text(t('safety.shareTrip')),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _sendSos,
                  icon: const Icon(Icons.sos_rounded),
                  label: Text(t('safety.sos')),
                ),
              ),
            ],
          ),
        ],
      );

  Widget _metric(
    IconData icon,
    String value,
    String label,
  ) =>
      Expanded(
        child: Column(
          children: [
            Icon(icon, color: AstrideColors.green),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AstrideColors.navy,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AstrideColors.muted,
              ),
            ),
          ],
        ),
      );

  String get _distanceLabel {
    final value = double.tryParse(
      '${widget.controller.activeBooking?['distanceKm'] ?? ''}',
    );
    return value == null ? '-' : '${value.toStringAsFixed(1)} km';
  }

  LatLng? get _pickupPoint {
    final pickup = widget.controller.activeBooking?['pickup'];
    if (pickup is! Map) return null;
    final lat = double.tryParse('${pickup['lat']}');
    final lng = double.tryParse('${pickup['lng']}');
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  }

  Future<void> _callDriver() async {
    await _launchContact(
      scheme: 'tel',
      value: '${assignedDriver?['mobile'] ?? ''}',
    );
  }

  Future<void> _messageDriver() async {
    final bookingId =
        '${widget.controller.activeBooking?['id'] ?? ''}';
    await _launchContact(
      scheme: 'sms',
      value: '${assignedDriver?['mobile'] ?? ''}',
      body: 'ASTRIDE ride $bookingId: I am contacting you '
          'regarding my pickup.',
    );
  }

  Future<void> _launchContact({
    required String scheme,
    required String value,
    String? body,
  }) async {
    final clean = value.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.isEmpty) {
      _toast('Contact number is not available yet.');
      return;
    }
    final uri = Uri(
      scheme: scheme,
      path: clean,
      queryParameters:
          body == null ? null : <String, String>{'body': body},
    );
    if (!await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    )) {
      _toast('Unable to open the phone application.');
    }
  }

  Future<void> _shareTrip() async {
    final booking = widget.controller.activeBooking ?? {};
    final pickup = booking['pickupAddress'] ??
        _pointText(booking['pickup']) ??
        'Pickup';
    final destination = booking['destinationAddress'] ??
        _pointText(booking['destination']) ??
        'Destination';
    await Share.share(
      'ASTRIDE SafeRide\n'
      'Ride ID: ${booking['id'] ?? '-'}\n'
      'Status: $status\n'
      'Pickup: $pickup\n'
      'Destination: $destination',
    );
  }

  String? _pointText(dynamic value) {
    if (value is! Map) return null;
    final lat = value['lat'];
    final lng = value['lng'];
    if (lat == null || lng == null) return null;
    return '$lat, $lng';
  }

  Future<void> _sendSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send emergency SOS?'),
        content: const Text(
          'Your live location, ride ID and assigned Driver '
          'will be sent to the ASTRIDE Safety Team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final incident = await widget.controller.triggerSos(
        bookingId:
            widget.controller.activeBooking?['id']?.toString(),
      );
      _toast(
        'SOS sent. Incident ID: ${incident['id'] ?? '-'}',
      );
    } catch (error) {
      _toast('$error');
    }
  }

  Future<void> _refreshDispatch() async {
    try {
      final activeResponse = await widget.controller.api.getJson(
        '/v1/passenger/active-booking',
      );
      final active = activeResponse['booking'];
      if (!mounted) return;

      if (active is! Map) {
        return;
      }

      final booking = active.cast<String, dynamic>();
      final bookingId = '${booking['id'] ?? ''}';
      if (bookingId.isEmpty) return;

      widget.controller.resumeBooking(booking);

      final response = await widget.controller.api.getJson(
        '/v1/bookings/$bookingId/dispatch-status',
      );
      final synchronized = response['booking'];
      final markers = response['nearbyDrivers'];

      if (!mounted || synchronized is! Map) return;
      final current =
          synchronized.cast<String, dynamic>();

      setState(() {
        status = '${current['status'] ?? status}';
        widget.controller.resumeBooking(current);
        nearbyCount =
            int.tryParse('${response['nearbyCount'] ?? 0}') ?? 0;
        searchRadiusKm =
            double.tryParse('${response['searchRadiusKm'] ?? 0}') ??
                0;
        nearbyDriverPoints = markers is List
            ? markers
                .whereType<Map>()
                .map((item) {
                  final lat = double.tryParse('${item['lat']}');
                  final lng = double.tryParse('${item['lng']}');
                  return lat == null || lng == null
                      ? null
                      : LatLng(lat, lng);
                })
                .whereType<LatLng>()
                .toList()
            : const [];
        assignedDriver = response['assignedDriver'] is Map
            ? (response['assignedDriver'] as Map)
                .cast<String, dynamic>()
            : null;

        final assignedLocation = assignedDriver?['location'];
        if (!searching && assignedLocation is Map) {
          final lat =
              double.tryParse('${assignedLocation['lat']}');
          final lng =
              double.tryParse('${assignedLocation['lng']}');
          if (lat != null && lng != null) {
            nearbyDriverPoints = [LatLng(lat, lng)];
          }
        }
      });

      if (status == 'COMPLETED') {
        _openCompleted();
      }
    } catch (_) {
      // The two-second synchronization loop retries automatically.
    }
  }

  Future<void> _payPendingUpi() async {
    try {
      await widget.controller.payPendingUpi(paymentGateway);
      if (!mounted) return;
      await _refreshDispatch();
    } catch (error) {
      _toast('$error');
    }
  }

  Future<void> _cancel() async {
    try {
      await widget.controller.cancel();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      _toast('$error');
    }
  }

  num get _completedFare {
    final booking = widget.controller.activeBooking ?? const <String, dynamic>{};
    final fare = booking['fareEstimate'] is Map
        ? booking['fareEstimate'] as Map
        : const <String, dynamic>{};
    final paise = num.tryParse('${booking['finalFarePaise'] ?? fare['totalPaise'] ?? ''}');
    if (paise != null && paise > 0) return paise / 100;
    return num.tryParse(
          '${booking['finalFare'] ?? fare['amount'] ?? fare['total'] ?? booking['fare'] ?? 0}',
        ) ??
        0;
  }

  void _openCompleted() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RideCompletedScreen(
          t: widget.controller.t,
          fare: _completedFare,
          paymentMethod: '${widget.controller.activeBooking?['paymentPreference'] ?? widget.controller.activeBooking?['paymentMethod'] ?? 'CASH'}',
          onDone: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
