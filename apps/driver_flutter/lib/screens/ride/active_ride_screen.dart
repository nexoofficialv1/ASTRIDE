import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';
import '../../widgets/provider_map.dart';
import '../secure_chat_screen.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({
    super.key,
    required this.controller,
    required this.onBack,
  });

  final DriverController controller;
  final VoidCallback onBack;

  @override
  State<ActiveRideScreen> createState() =>
      _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final otp = TextEditingController();
  Timer? ticker;

  @override
  void initState() {
    super.initState();
    ticker = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    ticker?.cancel();
    otp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final ride = c.activeRide ?? {};
    final status = '${ride['status'] ?? 'DRIVER_ASSIGNED'}';

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: ProviderMap(
              provider: 'GOOGLE',
              center: _rideCenter(ride),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Spacer(),
                  _StatusBadge(
                    label: c.t(_statusKey(status)),
                  ),
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 24,
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 25,
                            backgroundColor:
                                Color(0x140D1B3D),
                            child: Icon(
                              Icons.person,
                              color: AstrideColors.navy,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${ride['passengerName'] ?? c.t('passenger')}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const Text(
                                  'ASTRIDE Passenger • SafeRide',
                                  style: TextStyle(
                                    color: AstrideColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton.filledTonal(
                            onPressed: _callPassenger,
                            icon: const Icon(Icons.call),
                          ),
                          const SizedBox(width: 6),
                          IconButton.filledTonal(
                            onPressed: _messagePassenger,
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      _Route(
                        label: c.t('pickup'),
                        value: _locationText(
                          ride['pickupAddress'],
                          ride['pickup'],
                          'Pickup location',
                        ),
                        icon: Icons.radio_button_checked,
                        color: AstrideColors.green,
                      ),
                      _Route(
                        label: c.t('destination'),
                        value: _locationText(
                          ride['destinationAddress'],
                          ride['destination'],
                          'Destination',
                        ),
                        icon: Icons.location_on,
                        color: AstrideColors.orange,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              label: c.t('payment'),
                              value:
                                  '${ride['paymentPreference'] ?? ride['paymentMethod'] ?? c.t('cashOrUpi')}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InfoCard(
                              label: c.t('fare'),
                              value: _fareText(ride),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _InfoCard(
                              label: c.t('distance'),
                              value: _distanceText(ride),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (status == 'DRIVER_ASSIGNED')
                        FilledButton.icon(
                          onPressed: () => _changeStatus(
                            'DRIVER_ARRIVING',
                          ),
                          icon: const Icon(
                            Icons.navigation_rounded,
                          ),
                          label: const Text(
                            'Start navigation to pickup',
                          ),
                        )
                      else if (status == 'DRIVER_ARRIVING')
                        FilledButton.icon(
                          onPressed: () => _changeStatus(
                            'DRIVER_ARRIVED',
                          ),
                          icon: const Icon(
                            Icons.location_on_outlined,
                          ),
                          label: Text(c.t('arrivedAtPickup')),
                        )
                      else if (status == 'DRIVER_ARRIVED') ...[
                        _WaitingTimer(
                          elapsed: _waitingElapsed(ride),
                          freeSeconds: 180,
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: otp,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          decoration: InputDecoration(
                            labelText: c.t('passengerOtp'),
                            prefixIcon: const Icon(
                              Icons.password_rounded,
                            ),
                            counterText: '',
                          ),
                        ),
                        const SizedBox(height: 10),
                        FilledButton(
                          onPressed: () => _changeStatus(
                            'IN_PROGRESS',
                            otp: otp.text,
                          ),
                          child: Text(c.t('startRide')),
                        ),
                      ] else
                        FilledButton.icon(
                          onPressed: () =>
                              _changeStatus('COMPLETED'),
                          icon: const Icon(Icons.flag_outlined),
                          label: Text(c.t('completeRide')),
                        ),
                      const SizedBox(height: 8),
                      if (const {
                        'DRIVER_ASSIGNED',
                        'DRIVER_ARRIVING',
                        'DRIVER_ARRIVED',
                      }.contains(status))
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed:
                                c.busy ? null : _cancelRide,
                            icon: const Icon(
                              Icons.cancel_outlined,
                              color: AstrideColors.danger,
                            ),
                            label: const Text(
                              'Cancel this ride',
                            ),
                          ),
                        ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _sendSos,
                        icon: const Icon(
                          Icons.sos_outlined,
                          color: AstrideColors.danger,
                        ),
                        label: Text(c.t('emergencySos')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeStatus(
    String status, {
    String? otp,
  }) async {
    try {
      await widget.controller.updateRideStatus(
        status,
        otp: otp,
      );
    } catch (error) {
      _toast('$error');
    }
  }

  Future<void> _callPassenger() async {
    final bookingId = '${widget.controller.activeRide?['id'] ?? ''}';
    if (bookingId.isEmpty) return;
    try {
      await widget.controller.api.postJson(
        '/v1/communications/bookings/$bookingId/call-sessions',
        {'mode': 'IN_APP_RELAY'},
      );
      _toast('Secure call request sent without exposing phone numbers.');
    } catch (error) {
      _toast('$error');
    }
  }

  Future<void> _messagePassenger() async {
    final bookingId = '${widget.controller.activeRide?['id'] ?? ''}';
    final actorId = widget.controller.session?.userId ?? '';
    if (bookingId.isEmpty || actorId.isEmpty) {
      _toast('Secure chat is not available yet.');
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SecureChatScreen(
          api: widget.controller.api,
          bookingId: bookingId,
          actorType: 'driver',
          actorId: actorId,
          peerLabel: 'Passenger',
        ),
      ),
    );
  }

  Future<void> _sendSos() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send emergency SOS?'),
        content: const Text(
          'Your live location and current ride details will '
          'be sent to the ASTRIDE Safety Team.',
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
            widget.controller.activeRide?['id']?.toString(),
      );
      _toast(
        'SOS sent. Incident ID: ${incident['id'] ?? '-'}',
      );
    } catch (error) {
      _toast('$error');
    }
  }

  LatLng _rideCenter(Map<dynamic, dynamic> ride) {
    final pickup = ride['pickup'];
    if (pickup is Map) {
      final lat = double.tryParse('${pickup['lat']}');
      final lng = double.tryParse('${pickup['lng']}');
      if (lat != null && lng != null) {
        return LatLng(lat, lng);
      }
    }
    return const LatLng(23.2194, 88.3629);
  }

  Duration _waitingElapsed(Map<dynamic, dynamic> ride) {
    final start = DateTime.tryParse(
      '${ride['waitingStartedAt'] ?? ride['arrivedAt'] ?? ride['updatedAt'] ?? ''}',
    );
    if (start == null) return Duration.zero;
    final elapsed = DateTime.now().toUtc().difference(
          start.toUtc(),
        );
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  String _locationText(
    dynamic address,
    dynamic point,
    String fallback,
  ) {
    final text = '$address'.trim();
    if (address != null &&
        text.isNotEmpty &&
        text != 'null') {
      return text;
    }
    if (point is Map &&
        point['lat'] != null &&
        point['lng'] != null) {
      return '${point['lat']}, ${point['lng']}';
    }
    return fallback;
  }

  String _fareText(Map<dynamic, dynamic> ride) {
    final amount = num.tryParse(
      '${ride['fareEstimate']?['amount'] ?? ride['fareEstimate']?['total'] ?? ride['fare'] ?? 0}',
    );
    return '₹${(amount ?? 0).toStringAsFixed(0)}';
  }

  String _distanceText(Map<dynamic, dynamic> ride) {
    final distance =
        double.tryParse('${ride['distanceKm'] ?? ''}');
    return distance == null
        ? '-'
        : '${distance.toStringAsFixed(1)} km';
  }

  Future<void> _cancelRide() async {
    const reasons = <String>[
      'Vehicle problem',
      'Personal emergency',
      'Passenger not reachable',
      'Pickup location is incorrect',
      'Unsafe situation',
      'Other',
    ];
    String selected = reasons.first;
    final details = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Cancel assigned ride?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'The Passenger will return to Driver search. '
                'This cancellation will be recorded.',
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: selected,
                decoration: const InputDecoration(
                  labelText: 'Cancellation reason',
                ),
                items: reasons
                    .map(
                      (reason) => DropdownMenuItem(
                        value: reason,
                        child: Text(reason),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(
                      () => selected = value,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: details,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Additional details (optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Keep ride'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Confirm cancellation'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      details.dispose();
      return;
    }

    final note = details.text.trim();
    final reason =
        note.isEmpty ? selected : '$selected: $note';
    details.dispose();

    try {
      await widget.controller.cancelActiveRide(reason);
      // DriverShell rebuilds this tab as Ride History.
      // Do not pop the root application route.
    } catch (error) {
      _toast('$error');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static String _statusKey(String status) {
    switch (status) {
      case 'DRIVER_ASSIGNED':
      case 'DRIVER_ARRIVING':
        return 'navigateToPickup';
      case 'DRIVER_ARRIVED':
        return 'waitingForPassenger';
      case 'IN_PROGRESS':
        return 'rideInProgress';
      default:
        return 'activeRide';
    }
  }
}

class _WaitingTimer extends StatelessWidget {
  const _WaitingTimer({
    required this.elapsed,
    required this.freeSeconds,
  });

  final Duration elapsed;
  final int freeSeconds;

  @override
  Widget build(BuildContext context) {
    final elapsedSeconds = elapsed.inSeconds;
    final freeRemaining =
        (freeSeconds - elapsedSeconds).clamp(0, freeSeconds);
    final paidSeconds =
        (elapsedSeconds - freeSeconds).clamp(0, 86400);
    final free = freeRemaining > 0;
    final shown = free ? freeRemaining : paidSeconds;

    String two(int value) => value.toString().padLeft(2, '0');
    final timerText =
        '${two(shown ~/ 60)}:${two(shown % 60)}';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: free
            ? const Color(0xFFFFF7E8)
            : const Color(0x14EF4444),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: free
                ? AstrideColors.orange
                : AstrideColors.danger,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              free
                  ? 'Free waiting $timerText'
                  : 'Chargeable waiting +$timerText',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            free
                ? 'Charge starts after 03:00'
                : 'Waiting charge active',
            style: const TextStyle(
              fontSize: 11,
              color: AstrideColors.muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 12,
            ),
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      );
}

class _Route extends StatelessWidget {
  const _Route({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7FB),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AstrideColors.muted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}
