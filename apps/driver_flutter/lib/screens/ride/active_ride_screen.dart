import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';
import '../../widgets/provider_map.dart';

class ActiveRideScreen extends StatefulWidget {
  const ActiveRideScreen({super.key, required this.controller});
  final DriverController controller;
  @override
  State<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends State<ActiveRideScreen> {
  final otp = TextEditingController();
  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final ride = c.activeRide ?? {};
    final status = '${ride['status'] ?? 'DRIVER_ASSIGNED'}';
    return Scaffold(
      body: Stack(children: [
        const Positioned.fill(child: ProviderMap(provider: 'GOOGLE', center: LatLng(23.2194, 88.3629))),
        SafeArea(child: Padding(padding: const EdgeInsets.all(14), child: Row(children: [
          IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.arrow_back)),
          const Spacer(),
          _StatusBadge(label: c.t(_statusKey(status))),
        ]))),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30)), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 24)]),
            child: SafeArea(top: false, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(width: 42, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(10))),
              const SizedBox(height: 14),
              Row(children: [
                const CircleAvatar(radius: 25, backgroundColor: Color(0x140D1B3D), child: Icon(Icons.person, color: AstrideColors.navy)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${ride['passengerName'] ?? c.t('passenger')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const Text('4.8 ★ • SafeRide', style: TextStyle(color: AstrideColors.muted))])),
                IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.call)),
                const SizedBox(width: 6),
                IconButton.filledTonal(onPressed: () {}, icon: const Icon(Icons.chat_bubble_outline)),
              ]),
              const SizedBox(height: 14),
              _Route(label: c.t('pickup'), value: '${ride['pickup'] ?? 'Kalna Railway Station'}', icon: Icons.radio_button_checked, color: AstrideColors.green),
              _Route(label: c.t('destination'), value: '${ride['destination'] ?? 'Kalna S.D. Hospital'}', icon: Icons.location_on, color: AstrideColors.orange),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _InfoCard(label: c.t('payment'), value: c.t('cashOrUpi'))),
                const SizedBox(width: 10),
                Expanded(child: _InfoCard(label: c.t('fare'), value: '₹${ride['fare'] ?? 50}')),
                const SizedBox(width: 10),
                Expanded(child: _InfoCard(label: c.t('distance'), value: '${ride['distanceKm'] ?? 3.2} km')),
              ]),
              const SizedBox(height: 14),
              if (status == 'DRIVER_ASSIGNED') ...[
                FilledButton.icon(
                  onPressed: () => c.updateRideStatus('DRIVER_ARRIVING'),
                  icon: const Icon(Icons.navigation_rounded),
                  label: const Text('Start navigation to pickup'),
                ),
              ] else if (status == 'DRIVER_ARRIVING') ...[
                FilledButton.icon(
                  onPressed: () => c.updateRideStatus('DRIVER_ARRIVED'),
                  icon: const Icon(Icons.location_on_outlined),
                  label: Text(c.t('arrivedAtPickup')),
                ),
              ] else if (status == 'DRIVER_ARRIVED') ...[
                Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: const Color(0xFFFFF7E8), borderRadius: BorderRadius.circular(16)), child: Row(children: [const Icon(Icons.timer_outlined, color: AstrideColors.orange), const SizedBox(width: 10), Expanded(child: Text('${c.t('freeWaiting')} 03:00', style: const TextStyle(fontWeight: FontWeight.w800))), Text(c.t('waitingChargeAfter'), style: const TextStyle(fontSize: 11, color: AstrideColors.muted))])),
                const SizedBox(height: 12),
                TextField(controller: otp, keyboardType: TextInputType.number, maxLength: 4, decoration: InputDecoration(labelText: c.t('passengerOtp'), prefixIcon: const Icon(Icons.password_rounded), counterText: '')),
                const SizedBox(height: 10),
                FilledButton(onPressed: () => c.updateRideStatus('IN_PROGRESS', otp: otp.text), child: Text(c.t('startRide'))),
              ] else ...[
                FilledButton.icon(onPressed: () => c.updateRideStatus('COMPLETED'), icon: const Icon(Icons.flag_outlined), label: Text(c.t('completeRide'))),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(onPressed: () {}, icon: const Icon(Icons.sos_outlined, color: AstrideColors.danger), label: Text(c.t('emergencySos'))),
            ]))),
          ),
        ),
      ]),
    );
  }

  static String _statusKey(String status) {
    switch (status) {
      case 'DRIVER_ASSIGNED': return 'navigateToPickup';
      case 'DRIVER_ARRIVING': return 'navigateToPickup';
      case 'DRIVER_ARRIVED': return 'waitingForPassenger';
      case 'IN_PROGRESS': return 'rideInProgress';
      default: return 'activeRide';
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 12)]), child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900, color: AstrideColors.navy)));
}
class _Route extends StatelessWidget {
  const _Route({required this.label, required this.value, required this.icon, required this.color});
  final String label, value;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(children: [Icon(icon, color: color), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: AstrideColors.muted)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))]))]));
}
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: const Color(0xFFF5F7FB), borderRadius: BorderRadius.circular(14)), child: Column(children: [Text(label, style: const TextStyle(fontSize: 11, color: AstrideColors.muted)), const SizedBox(height: 4), Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, color: AstrideColors.navy))]));
}
