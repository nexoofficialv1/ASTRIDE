import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';

class DriverPerformanceScreen extends StatelessWidget {
  const DriverPerformanceScreen({super.key, required this.controller});
  final DriverController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(controller.t('performance'))),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Row(children: [
            Expanded(child: _Score(value: '86%', label: controller.t('acceptanceRate'), icon: Icons.check_circle_outline)),
            const SizedBox(width: 10),
            Expanded(child: _Score(value: '4%', label: controller.t('cancellationRate'), icon: Icons.cancel_outlined)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _Score(value: '90%', label: controller.t('onTimePickup'), icon: Icons.schedule)),
            const SizedBox(width: 10),
            Expanded(child: _Score(value: '4.9', label: controller.t('rating'), icon: Icons.star_outline)),
          ]),
          const SizedBox(height: 20),
          Text(controller.t('promoterCoaching'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AstrideColors.navy)),
          const SizedBox(height: 10),
          Card(child: ListTile(contentPadding: const EdgeInsets.all(16), leading: const CircleAvatar(backgroundColor: Color(0x1422C55E), child: Icon(Icons.thumb_up_alt_outlined, color: AstrideColors.green)), title: Text(controller.t('goodPerformance'), style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(controller.t('keepAcceptingRides')))),
          const SizedBox(height: 18),
          Text(controller.t('weeklyTrend'), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AstrideColors.navy)),
          const SizedBox(height: 10),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: SizedBox(height: 150, child: Row(crossAxisAlignment: CrossAxisAlignment.end, mainAxisAlignment: MainAxisAlignment.spaceAround, children: [30, 55, 48, 78, 65, 92, 80].map((h) => Container(width: 18, height: h.toDouble(), decoration: BoxDecoration(color: AstrideColors.green, borderRadius: BorderRadius.circular(8)))).toList())))),
        ]),
      );
}
class _Score extends StatelessWidget {
  const _Score({required this.value, required this.label, required this.icon});
  final String value, label;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [Icon(icon, color: AstrideColors.green), const SizedBox(height: 8), Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AstrideColors.navy)), Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: AstrideColors.muted))])));
}
