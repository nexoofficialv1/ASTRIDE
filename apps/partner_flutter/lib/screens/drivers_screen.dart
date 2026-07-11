import 'package:flutter/material.dart';
import '../models/partner_models.dart';
import '../state/partner_controller.dart';
import 'driver_detail_screen.dart';

// Actions: Encourage | Performance warning | Training reminder
class DriversScreen extends StatelessWidget {
  const DriversScreen({super.key, required this.c});
  final PartnerController c;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    final items = c.visibleDrivers;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: c.setDriverQuery,
            decoration: InputDecoration(prefixIcon: const Icon(Icons.search_rounded), hintText: s.t('searchDriver'), suffixIcon: const Icon(Icons.tune_rounded)),
          ),
        ),
        SizedBox(
          height: 52,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            scrollDirection: Axis.horizontal,
            children: [
              _chip(c, 'ALL', s.t('all')),
              _chip(c, 'ONLINE', s.t('online')),
              _chip(c, 'ATTENTION', s.t('needsAttention')),
              _chip(c, 'TOP', s.t('topPerformers')),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(children: [Text(c.range.label, style: const TextStyle(fontWeight: FontWeight.w700)), const Spacer(), Text('${items.length} ${s.t('drivers')}')]),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.person_search_rounded, size: 56), const SizedBox(height: 10), Text(s.t('noDrivers'))]))
              : RefreshIndicator(
                  onRefresh: c.refresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => _DriverCard(c: c, driver: items[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _chip(PartnerController c, String value, String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ChoiceChip(label: Text(label), selected: c.driverFilter == value, onSelected: (_) => c.setDriverFilter(value)),
      );
}

class _DriverCard extends StatelessWidget {
  const _DriverCard({required this.c, required this.driver});
  final PartnerController c;
  final DriverPerformance driver;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DriverDetailScreen(c: c, driver: driver))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(radius: 25, child: Text(driver.name.isEmpty ? 'D' : driver.name[0].toUpperCase())),
                      Positioned(right: 0, bottom: 0, child: Container(width: 13, height: 13, decoration: BoxDecoration(color: driver.online ? const Color(0xFF22C55E) : Colors.grey, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(driver.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)), Text('${driver.vehicle} • ${driver.online ? s.t('online') : s.t('offline')}')])),
                  if (driver.needsAttention) const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _stat('${driver.completed}', s.t('completed'))),
                  Expanded(child: _stat('${driver.acceptance.toStringAsFixed(0)}%', s.t('acceptance'))),
                  Expanded(child: _stat('${driver.rejected}', s.t('rejected'))),
                  Expanded(child: _stat('${driver.cancelled}', s.t('cancelled'))),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: (driver.acceptance / 100).clamp(0.0, 1.0).toDouble(), minHeight: 7, borderRadius: BorderRadius.circular(8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) => Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900)), Text(label, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis)]);
}
