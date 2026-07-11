import 'package:flutter/material.dart';
import '../design/astride_theme.dart';
import '../state/driver_controller.dart';

class NewRideRequestScreen extends StatelessWidget {
  const NewRideRequestScreen({super.key, required this.controller});
  final DriverController controller;

  @override
  Widget build(BuildContext context) {
    final r = controller.request ?? {
      'id': 'demo',
      'pickup': 'Kalna Railway Station',
      'destination': 'Kalna S.D. Hospital',
      'fare': 50,
      'distanceKm': 1.2,
      'paymentPreference': 'CASH_OR_UPI',
      'rideType': 'FULL_TOTO',
      'safeRide': true,
    };
    return Material(
      color: const Color(0xB0000000),
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(14),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 30)]),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(width: 48, height: 48, decoration: const BoxDecoration(color: AstrideColors.navy, shape: BoxShape.circle), child: const Icon(Icons.electric_rickshaw, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(controller.t('newRequest'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AstrideColors.navy)),
                  Text('${r['distanceKm']} km ${controller.t('away')} • ${controller.t('pickupEta')} 4 min', style: const TextStyle(color: AstrideColors.muted)),
                ])),
                Text('₹${r['fare']}', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w900, color: AstrideColors.green)),
              ]),
              const SizedBox(height: 18),
              _RouteRow(icon: Icons.radio_button_checked, color: AstrideColors.green, label: controller.t('pickup'), value: '${r['pickup']}'),
              _RouteRow(icon: Icons.location_on_rounded, color: AstrideColors.orange, label: controller.t('destination'), value: '${r['destination']}'),
              const Divider(height: 28),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _Tag(icon: Icons.payments_outlined, label: controller.t('cashOrUpi'), color: AstrideColors.orange),
                _Tag(icon: Icons.shield_outlined, label: controller.t('safeRide'), color: AstrideColors.green),
                _Tag(icon: Icons.electric_rickshaw, label: controller.t('fullToto'), color: AstrideColors.navy),
              ]),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: controller.rejectRequest, style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(54)), child: Text(controller.t('decline')))),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: FilledButton(onPressed: controller.acceptRequest, style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)), child: Text('${controller.t('accept')} • 15s'))),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.icon, required this.color, required this.label, required this.value});
  final IconData icon;
  final Color color;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 12, color: AstrideColors.muted)), Text(value, style: const TextStyle(fontWeight: FontWeight.w800))])),
      ]));
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), decoration: BoxDecoration(color: color.withOpacity(.08), borderRadius: BorderRadius.circular(12)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, size: 16, color: color), const SizedBox(width: 6), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: color))]));
}
