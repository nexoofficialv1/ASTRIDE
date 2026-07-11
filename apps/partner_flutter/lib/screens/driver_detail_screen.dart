import 'package:flutter/material.dart';
import '../models/partner_models.dart';
import '../state/partner_controller.dart';

class DriverDetailScreen extends StatelessWidget {
  const DriverDetailScreen({super.key, required this.c, required this.driver});
  final PartnerController c;
  final DriverPerformance driver;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.t('driverDetails'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  CircleAvatar(radius: 38, child: Text(driver.name.isEmpty ? 'D' : driver.name[0].toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900))),
                  const SizedBox(height: 10),
                  Text(driver.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                  Text('${s.t('vehicle')}: ${driver.vehicle}'),
                  const SizedBox(height: 8),
                  Chip(avatar: Icon(driver.online ? Icons.circle : Icons.circle_outlined, size: 14, color: driver.online ? Colors.green : Colors.grey), label: Text(driver.online ? s.t('online') : s.t('offline'))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.7,
            children: [
              _metric(s.t('rideRequests'), '${driver.requests}'),
              _metric(s.t('completedRides'), '${driver.completed}'),
              _metric(s.t('acceptanceRate'), '${driver.acceptance.toStringAsFixed(1)}%'),
              _metric(s.t('cancellationRate'), '${driver.cancellationRate.toStringAsFixed(1)}%'),
              _metric(s.t('rating'), driver.rating.toStringAsFixed(1)),
              _metric(s.t('onlineHours'), driver.onlineHours.toStringAsFixed(1)),
              _metric(s.t('lateArrivals'), '${driver.lateArrivals}'),
              _metric(s.t('lastOnline'), driver.lastOnline),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: () => _coach(context, 'ENCOURAGE'), icon: const Icon(Icons.thumb_up_alt_rounded), label: Text(s.t('encourage'))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => _coach(context, 'WARNING'), icon: const Icon(Icons.warning_amber_rounded), label: Text(s.t('warning'))),
          const SizedBox(height: 10),
          OutlinedButton.icon(onPressed: () => _coach(context, 'TRAINING'), icon: const Icon(Icons.school_rounded), label: Text(s.t('training'))),
          const SizedBox(height: 10),
          TextButton.icon(onPressed: () {}, icon: const Icon(Icons.report_gmailerrorred_rounded), label: Text(s.t('reportAdmin'))),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) => Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), Text(label, maxLines: 1, overflow: TextOverflow.ellipsis)])));

  Future<void> _coach(BuildContext context, String type) async {
    final s = c.strings;
    final ctl = TextEditingController(text: type == 'ENCOURAGE' ? 'Keep up the good work.' : 'Please improve ride acceptance and reduce cancellations.');
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.t('coachDriver')),
        content: TextField(controller: ctl, maxLines: 4, decoration: InputDecoration(labelText: s.t('message'))),
        actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: Text(s.t('cancel'))), FilledButton(onPressed: () => Navigator.pop(context, true), child: Text(s.t('send')))],
      ),
    );
    if (ok == true) {
      await c.coach(driver.id, type, ctl.text.trim());
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.t('message'))));
    }
  }
}
