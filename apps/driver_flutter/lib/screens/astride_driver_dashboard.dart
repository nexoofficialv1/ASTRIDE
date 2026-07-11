import 'package:flutter/material.dart';
import '../design/astride_theme.dart';
import '../state/driver_controller.dart';
import '../widgets/brand/astride_wordmark.dart';

class AstrideDriverDashboard extends StatelessWidget {
  const AstrideDriverDashboard({super.key, required this.controller});
  final DriverController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refreshDriver,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Row(children: [
                  const AstrideWordmark(compact: true),
                  const Spacer(),
                  _SignalPill(icon: Icons.gps_fixed, label: controller.t('gpsReady'), active: true),
                  const SizedBox(width: 8),
                  _SignalPill(icon: Icons.wifi, label: controller.t('networkGood'), active: true),
                ]),
                const SizedBox(height: 18),
                _OnlineHero(controller: controller),
                const SizedBox(height: 16),
                _StatsGrid(controller: controller),
                const SizedBox(height: 20),
                _SectionTitle(controller.t('performanceToday')),
                const SizedBox(height: 10),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _ProgressLine(label: controller.t('acceptanceRate'), value: 0.86, trailing: '86%'),
                      const SizedBox(height: 14),
                      _ProgressLine(label: controller.t('completionRate'), value: 0.93, trailing: '93%'),
                      const SizedBox(height: 14),
                      _ProgressLine(label: controller.t('onTimePickup'), value: 0.90, trailing: '90%'),
                    ]),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(controller.t('quickActions')),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _Action(icon: Icons.account_balance_wallet_outlined, label: controller.t('wallet')),
                    _Action(icon: Icons.analytics_outlined, label: controller.t('performance')),
                    _Action(icon: Icons.support_agent_outlined, label: controller.t('support')),
                    _Action(icon: Icons.receipt_long_outlined, label: controller.t('statements')),
                    _Action(icon: Icons.verified_user_outlined, label: controller.t('documents')),
                    _Action(icon: Icons.sos_outlined, label: controller.t('safety'), danger: true),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(controller.t('recentRide')),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1422C55E),
                      child: Icon(Icons.route_rounded, color: AstrideColors.green),
                    ),
                    title: const Text('Kalna Station → Hospital', style: TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${controller.t('completed')} • ${controller.t('cash')}'),
                    trailing: const Text('₹50', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AstrideColors.navy)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}

class _OnlineHero extends StatelessWidget {
  const _OnlineHero({required this.controller});
  final DriverController controller;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AstrideColors.navy, Color(0xFF17396F)]),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [BoxShadow(color: Color(0x240D1B3D), blurRadius: 22, offset: Offset(0, 10))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(controller.t(controller.online ? 'youAreOnline' : 'youAreOffline'), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                const SizedBox(height: 5),
                Text(controller.t(controller.online ? 'nearbyRequestsWillAppear' : 'goOnlineInstruction'), style: const TextStyle(color: Colors.white70, height: 1.35)),
              ]),
            ),
            Switch(value: controller.online, onChanged: controller.setOnline),
          ]),
          const SizedBox(height: 20),
          Text(controller.t('todayEarnings'), style: const TextStyle(color: Colors.white70)),
          Text('₹${controller.todayEarnings.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 38, fontWeight: FontWeight.w900)),
          const SizedBox(height: 16),
          Row(children: [
            _HeroMetric(value: '6', label: controller.t('rides')),
            _HeroMetric(value: '42 km', label: controller.t('distance')),
            _HeroMetric(value: '4.9 ★', label: controller.t('rating')),
          ]),
        ]),
      );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.controller});
  final DriverController controller;
  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: _StatCard(icon: Icons.schedule, value: '6h 20m', label: controller.t('onlineHours'))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.close_rounded, value: '1', label: controller.t('rejectedRides'))),
        const SizedBox(width: 10),
        Expanded(child: _StatCard(icon: Icons.cancel_outlined, value: '0', label: controller.t('cancelledRides'))),
      ]);
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.value, required this.label});
  final String value, label;
  @override
  Widget build(BuildContext context) => Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ]));
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value, label;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10), child: Column(children: [
        Icon(icon, color: AstrideColors.green),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w900, color: AstrideColors.navy)),
        Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, color: AstrideColors.muted)),
      ])));
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({required this.label, required this.value, required this.trailing});
  final String label, trailing;
  final double value;
  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))), Text(trailing, style: const TextStyle(fontWeight: FontWeight.w900, color: AstrideColors.green))]),
        const SizedBox(height: 7),
        LinearProgressIndicator(value: value, minHeight: 7, borderRadius: BorderRadius.circular(20)),
      ]);
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({required this.icon, required this.label, required this.active});
  final IconData icon;
  final String label;
  final bool active;
  @override
  Widget build(BuildContext context) => Tooltip(message: label, child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: active ? const Color(0x1422C55E) : const Color(0x14EF4444), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 18, color: active ? AstrideColors.green : AstrideColors.danger)));
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: AstrideColors.navy));
}

class _Action extends StatelessWidget {
  const _Action({required this.icon, required this.label, this.danger = false});
  final IconData icon;
  final String label;
  final bool danger;
  @override
  Widget build(BuildContext context) => Card(child: InkWell(borderRadius: BorderRadius.circular(18), onTap: () {}, child: Padding(padding: const EdgeInsets.all(12), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: danger ? AstrideColors.danger : AstrideColors.green),
        const SizedBox(height: 8),
        Text(label, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
      ])));
}
