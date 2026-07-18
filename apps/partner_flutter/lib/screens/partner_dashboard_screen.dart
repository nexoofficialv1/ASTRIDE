import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/partner_controller.dart';

class PartnerDashboardScreen extends StatelessWidget {
  const PartnerDashboardScreen({super.key, required this.controller});
  final PartnerController controller;

  @override
  Widget build(BuildContext context) {
    final scope = _map(controller.dashboard['scope']);
    final performance = _map(controller.dashboard['performance']);
    final actor = _map(controller.dashboard['actor']);
    final earning = _map(controller.dashboard['earnings']);
    return RefreshIndicator(
      onRefresh: controller.refreshAll,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Text(
            'Welcome, ${(actor['name'] ?? controller.partner['name'] ?? 'Partner')}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AstrideColors.navy),
          ),
          const SizedBox(height: 4),
          Text(
            _roleLabel((actor['role'] ?? controller.partner['role']).toString()),
            style: const TextStyle(color: AstrideColors.muted),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _metric('Drivers', scope['driverCount'] ?? 0, Icons.groups_2_outlined),
              _metric('Online', scope['onlineDrivers'] ?? 0, Icons.online_prediction),
              _metric('Completed', performance['completed'] ?? 0, Icons.check_circle_outline),
              _metric('Acceptance', '${performance['acceptanceRate'] ?? 0}%', Icons.trending_up),
            ],
          ),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Performance summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 14),
                  _row('Ride requests', performance['requests'] ?? 0),
                  _row('Accepted', performance['accepted'] ?? 0),
                  _row('Rejected', performance['rejected'] ?? 0),
                  _row('Cancelled', performance['cancelled'] ?? 0),
                  _row('Rejection rate', '${performance['rejectionRate'] ?? 0}%'),
                  _row('Cancellation rate', '${performance['cancellationRate'] ?? 0}%'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Commission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  Text('₹${earning['amount'] ?? 0}', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: AstrideColors.greenDark)),
                  const SizedBox(height: 4),
                  Text('Withdrawable: ₹${earning['withdrawable'] ?? 0}', style: const TextStyle(color: AstrideColors.muted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _metric(String label, Object value, IconData icon) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, color: AstrideColors.greenDark),
            const SizedBox(height: 8),
            Text('$value', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AstrideColors.navy)),
            Text(label, style: const TextStyle(color: AstrideColors.muted)),
          ]),
        ),
      );

  static Widget _row(String label, Object value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label), Text('$value', style: const TextStyle(fontWeight: FontWeight.w800))]),
      );

  static Map<String, dynamic> _map(dynamic value) => value is Map ? value.cast<String, dynamic>() : {};
  static String _roleLabel(String role) => role == 'AREA_PROMOTER' ? 'Area Promoter' : 'Promoter';
}
