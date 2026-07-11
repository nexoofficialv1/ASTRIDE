import 'dart:async';
import 'package:flutter/material.dart';
import '../design/astride_theme.dart';
import '../services/live_service.dart';
import '../state/passenger_controller.dart';
import '../widgets/common/astride_map_canvas.dart';
import 'ride/ride_completed_screen.dart';

class RideStatusScreen extends StatefulWidget {
  const RideStatusScreen({super.key, required this.controller});
  final PassengerController controller;
  @override
  State<RideStatusScreen> createState() => _RideStatusScreenState();
}

class _RideStatusScreenState extends State<RideStatusScreen> {
  final live = LiveService();
  StreamSubscription<Map<String, dynamic>>? subscription;
  String status = 'SEARCHING';

  @override
  void initState() {
    super.initState();
    final id = widget.controller.activeBooking?['id']?.toString();
    if (id != null) {
      live.connect(id);
      subscription = live.events.listen((event) {
        if (!mounted) return;
        final next = (event['status'] ?? event['eventType'] ?? status).toString();
        setState(() => status = next);
        if (next == 'COMPLETED') _openCompleted();
      });
    }
  }

  @override
  void dispose() {
    subscription?.cancel();
    live.dispose();
    super.dispose();
  }

  bool get searching => status == 'SEARCHING';
  bool get inProgress => status == 'IN_PROGRESS' || status == 'RIDE_IN_PROGRESS';

  @override
  Widget build(BuildContext context) {
    final t = widget.controller.t;
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: AstrideMapCanvas(showRoute: !searching, showDrivers: true)),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  Row(children: [
                    Material(color: Colors.white, shape: const CircleBorder(), child: IconButton(onPressed: () => Navigator.maybePop(context), icon: const Icon(Icons.arrow_back_rounded))),
                    const Spacer(),
                    Material(color: Colors.white, shape: const StadiumBorder(), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9), child: Row(children: [const Icon(Icons.shield_rounded, color: AstrideColors.green), const SizedBox(width: 6), Text(t('safety.safeRide'))]))),
                  ]),
                  const Spacer(),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: searching ? _searchingCard(t) : _driverCard(t),
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
          SizedBox(width: 74, height: 74, child: Stack(alignment: Alignment.center, children: [const CircularProgressIndicator(strokeWidth: 5, color: AstrideColors.green), Container(width: 54, height: 54, decoration: const BoxDecoration(color: AstrideColors.navy, shape: BoxShape.circle), child: const Icon(Icons.electric_rickshaw_rounded, color: Colors.white))])),
          const SizedBox(height: 14),
          Text(t('ride.searchingNearby'), style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: AstrideColors.navy)),
          const SizedBox(height: 6),
          Text(t('ride.searchingBody'), textAlign: TextAlign.center, style: const TextStyle(color: AstrideColors.muted)),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _cancel, child: Text(t('cancelRide')))),
        ],
      );

  Widget _driverCard(String Function(String) t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const CircleAvatar(radius: 28, backgroundColor: Color(0x1422C55E), child: Icon(Icons.person_rounded, color: AstrideColors.green, size: 30)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(inProgress ? t('ride.inProgress') : t('driverArriving'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AstrideColors.navy)), const SizedBox(height: 3), const Text('Rahul Das • WB 41 T 2847'), const SizedBox(height: 3), const Row(children: [Icon(Icons.star_rounded, color: AstrideColors.orange, size: 17), Text(' 4.9  •  Trusted Driver', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))])])),
            IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.call_rounded)),
            const SizedBox(width: 6),
            IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline_rounded)),
          ]),
          const Divider(height: 26),
          Row(children: [
            _metric(Icons.schedule_rounded, inProgress ? '8 min' : '3 min', t('ride.eta')),
            _metric(Icons.route_rounded, inProgress ? '2.4 km' : '1.1 km', t('ride.distance')),
            _metric(Icons.payments_outlined, 'Cash / UPI', t('payment.title')),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.share_location_rounded), label: Text(t('safety.shareTrip')))),
            const SizedBox(width: 10),
            Expanded(child: FilledButton.icon(onPressed: () {}, icon: const Icon(Icons.sos_rounded), label: Text(t('safety.sos')))),
          ]),
        ],
      );

  Widget _metric(IconData icon, String value, String label) => Expanded(child: Column(children: [Icon(icon, color: AstrideColors.green), const SizedBox(height: 4), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AstrideColors.navy)), Text(label, style: const TextStyle(fontSize: 11, color: AstrideColors.muted))]));

  Future<void> _cancel() async {
    await widget.controller.cancel();
    if (mounted) Navigator.pop(context);
  }

  void _openCompleted() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => RideCompletedScreen(t: widget.controller.t, fare: 50, onDone: () => Navigator.pop(context))));
  }
}
