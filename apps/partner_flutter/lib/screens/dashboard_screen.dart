import 'package:flutter/material.dart';
import '../state/partner_controller.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.c});
  final PartnerController c;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    final d = c.dashboard ?? {};
    final scope = (d['scope'] ?? {}) as Map;
    final perf = (d['performance'] ?? {}) as Map;
    final e = c.earnings ?? {};
    final target = (d['monthlyTarget'] ?? 0).toDouble();
    final completed = (perf['completed'] ?? 0).toDouble();
    final progress = target <= 0 ? 0.0 : (completed / target).clamp(0.0, 1.0).toDouble();

    return RefreshIndicator(
      onRefresh: c.refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _Header(c: c),
          const SizedBox(height: 16),
          _RangeCard(c: c),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.35,
            children: [
              _MetricCard(s.t('totalDrivers'), '${scope['driverCount'] ?? 0}', Icons.groups_rounded, const Color(0xFF6D5DFB)),
              _MetricCard(s.t('onlineDrivers'), '${scope['onlineDrivers'] ?? 0}', Icons.wifi_tethering_rounded, const Color(0xFF22C55E)),
              _MetricCard(s.t('completed'), '${perf['completed'] ?? 0}', Icons.check_circle_rounded, const Color(0xFF0EA5E9)),
              _MetricCard(s.t('acceptance'), '${perf['acceptanceRate'] ?? 0}%', Icons.trending_up_rounded, const Color(0xFFF59E0B)),
            ],
          ),
          const SizedBox(height: 16),
          _EarningsHero(c: c, earnings: e),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.t('monthlyTarget'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                      Text('${completed.toInt()} / ${target.toInt()}'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(value: progress, minHeight: 10),
                  ),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toStringAsFixed(0)}% ${s.t('targetProgress')}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.t('performance'), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 12),
                  _row(s.t('requests'), perf['requests']),
                  _row(s.t('completed'), perf['completed']),
                  _row(s.t('rejected'), perf['rejected']),
                  _row(s.t('cancelled'), perf['cancelled']),
                  const Divider(height: 24),
                  _row(s.t('rejectionRate'), '${perf['rejectionRate'] ?? 0}%'),
                  _row(s.t('cancellationRate'), '${perf['cancellationRate'] ?? 0}%'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text(label), Text('${value ?? 0}', style: const TextStyle(fontWeight: FontWeight.w800))],
        ),
      );
}

class _Header extends StatelessWidget {
  const _Header({required this.c});
  final PartnerController c;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    final area = c.session?.role == 'AREA_PROMOTER';
    return Row(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.handshake_rounded),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${s.t('hello')}, ${c.session?.name ?? ''}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
              Text(area ? s.t('areaDashboard') : s.t('promoterDashboard')),
            ],
          ),
        ),
        IconButton(onPressed: c.refresh, icon: const Icon(Icons.refresh_rounded), tooltip: s.t('refresh')),
      ],
    );
  }
}

class _RangeCard extends StatelessWidget {
  const _RangeCard({required this.c});
  final PartnerController c;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final picked = await showDateRangePicker(
            context: context,
            firstDate: DateTime(2024),
            lastDate: DateTime.now(),
            initialDateRange: DateTimeRange(start: c.range.from, end: c.range.to),
          );
          if (picked != null) await c.setRange(picked.start, picked.end);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.calendar_month_rounded),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(s.t('dateRange')), Text(c.range.label, style: const TextStyle(fontWeight: FontWeight.w800))])),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(this.title, this.value, this.icon, this.color);
  final String title, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: color.withOpacity(.12), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color)),
              const Spacer(),
              Text(value, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
}

class _EarningsHero extends StatelessWidget {
  const _EarningsHero({required this.c, required this.earnings});
  final PartnerController c;
  final Map<String, dynamic> earnings;

  @override
  Widget build(BuildContext context) {
    final s = c.strings;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF0D1B3D), Color(0xFF4338CA)]),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.t('thisMonth'), style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text('₹${earnings['amount'] ?? 0}', style: Theme.of(context).textTheme.displaySmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _mini(s.t('withdrawable'), '₹${earnings['withdrawable'] ?? 0}')),
              Expanded(child: _mini(s.t('nextSettlement'), '${earnings['nextSettlementDate'] ?? '-'}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _mini(String label, String value) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)), const SizedBox(height: 3), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800))]);
}
