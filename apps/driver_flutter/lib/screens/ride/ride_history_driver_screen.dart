import 'package:flutter/material.dart';
import '../../design/astride_theme.dart';
import '../../state/driver_controller.dart';

class RideHistoryDriverScreen extends StatelessWidget {
  const RideHistoryDriverScreen({super.key, required this.controller});
  final DriverController controller;

  @override
  Widget build(BuildContext context) {
    const rides = <(String, String, String)>[
      ('Station', 'Hospital', '₹25'),
      ('Bus Stand', 'Court', '₹40'),
      ('Market', 'Rail Gate', '₹30'),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(controller.t('myRides'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _Summary(value: '6', label: controller.t('today'))),
              const SizedBox(width: 10),
              Expanded(child: _Summary(value: '₹685', label: controller.t('earnings'))),
            ],
          ),
          const SizedBox(height: 18),
          for (final ride in rides)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: const CircleAvatar(
                    backgroundColor: Color(0x1422C55E),
                    child: Icon(Icons.route, color: AstrideColors.green),
                  ),
                  title: Text('${ride.$1} → ${ride.$2}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text(controller.t('completed')),
                  trailing: Text(
                    ride.$3,
                    style: const TextStyle(fontWeight: FontWeight.w800, color: AstrideColors.navy),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AstrideColors.navy)),
              Text(label, style: const TextStyle(color: AstrideColors.muted)),
            ],
          ),
        ),
      );
}
