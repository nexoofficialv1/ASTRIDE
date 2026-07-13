import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/driver_controller.dart';
import '../widgets/brand/astride_wordmark.dart';

class AstrideDriverDashboard extends StatelessWidget {
  const AstrideDriverDashboard({
    super.key,
    required this.controller,
    required this.onNavigate,
    required this.onSupport,
    required this.onDocuments,
    required this.onSafety,
  });

  final DriverController controller;
  final ValueChanged<int> onNavigate;
  final VoidCallback onSupport;
  final VoidCallback onDocuments;
  final VoidCallback onSafety;

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF5F7FB),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: controller.refreshDriver,
            child: ListView(
              padding:
                  const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                Row(
                  children: [
                    const AstrideWordmark(compact: true),
                    const Spacer(),
                    _SignalPill(
                      icon: Icons.gps_fixed,
                      label: controller.t('gpsReady'),
                      active: true,
                    ),
                    const SizedBox(width: 8),
                    _SignalPill(
                      icon: Icons.wifi,
                      label: controller.t('networkGood'),
                      active: true,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _OnlineHero(controller: controller),
                const SizedBox(height: 16),
                _StatsGrid(controller: controller),
                const SizedBox(height: 20),
                _SectionTitle(
                  controller.t('performanceToday'),
                ),
                const SizedBox(height: 10),
                Card(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () => onNavigate(3),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _ProgressLine(
                            label: 'Acceptance rate',
                            value: .86,
                            trailing: '86%',
                          ),
                          SizedBox(height: 14),
                          _ProgressLine(
                            label: 'Completion rate',
                            value: .93,
                            trailing: '93%',
                          ),
                          SizedBox(height: 14),
                          _ProgressLine(
                            label: 'On-time pickup',
                            value: .90,
                            trailing: '90%',
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _SectionTitle(controller.t('quickActions')),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics:
                      const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _Action(
                      icon:
                          Icons.account_balance_wallet_outlined,
                      label: controller.t('wallet'),
                      onTap: () => onNavigate(2),
                    ),
                    _Action(
                      icon: Icons.analytics_outlined,
                      label: controller.t('performance'),
                      onTap: () => onNavigate(3),
                    ),
                    _Action(
                      icon: Icons.support_agent_outlined,
                      label: controller.t('support'),
                      onTap: onSupport,
                    ),
                    _Action(
                      icon: Icons.receipt_long_outlined,
                      label: controller.t('statements'),
                      onTap: () => onNavigate(2),
                    ),
                    _Action(
                      icon: Icons.verified_user_outlined,
                      label: controller.t('documents'),
                      onTap: onDocuments,
                    ),
                    _Action(
                      icon: Icons.sos_outlined,
                      label: controller.t('safety'),
                      danger: true,
                      onTap: onSafety,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _SectionTitle(controller.t('recentRide')),
                const SizedBox(height: 10),
                Card(
                  child: ListTile(
                    onTap: () => onNavigate(1),
                    contentPadding: const EdgeInsets.all(16),
                    leading: const CircleAvatar(
                      backgroundColor: Color(0x1422C55E),
                      child: Icon(
                        Icons.route_rounded,
                        color: AstrideColors.green,
                      ),
                    ),
                    title: const Text(
                      'View ride history',
                      style:
                          TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: const Text(
                      'Completed, cancelled and active rides',
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  static Widget _stat(
    IconData icon,
    String value,
    String label,
  ) =>
      Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 15,
              horizontal: 8,
            ),
            child: Column(
              children: [
                Icon(icon, color: AstrideColors.green),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AstrideColors.navy,
                  ),
                ),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AstrideColors.muted,
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
          gradient: const LinearGradient(
            colors: [
              AstrideColors.navy,
              Color(0xFF17396F),
            ],
          ),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    controller.t(
                      controller.online
                          ? 'youAreOnline'
                          : 'youAreOffline',
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Switch(
                  value: controller.online,
                  onChanged: (value) async {
                    try {
                      await controller.setOnline(value);
                    } catch (error) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        SnackBar(
                          content: Text(
                            '$error'.replaceFirst(
                              'Bad state: ',
                              '',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Today earnings',
              style: TextStyle(color: Colors.white70),
            ),
            Text(
              '₹${controller.todayEarnings.toStringAsFixed(0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 38,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.controller});

  final DriverController controller;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          AstrideDriverDashboard._stat(
            Icons.account_balance_wallet_outlined,
            '₹${controller.walletBalance.toStringAsFixed(0)}',
            'Wallet',
          ),
          const SizedBox(width: 10),
          AstrideDriverDashboard._stat(
            Icons.cancel_outlined,
            '${controller.profile['cancelledRides'] ?? 0}',
            'Cancelled',
          ),
          const SizedBox(width: 10),
          AstrideDriverDashboard._stat(
            Icons.star_outline_rounded,
            '${controller.profile['rating'] ?? 5}',
            'Rating',
          ),
        ],
      );
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine({
    required this.label,
    required this.value,
    required this.trailing,
  });

  final String label;
  final String trailing;
  final double value;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                trailing,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AstrideColors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          LinearProgressIndicator(
            value: value,
            minHeight: 7,
            borderRadius: BorderRadius.circular(20),
          ),
        ],
      );
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({
    required this.icon,
    required this.label,
    required this.active,
  });

  final IconData icon;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: active
                ? const Color(0x1422C55E)
                : const Color(0x14EF4444),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 18,
            color: active
                ? AstrideColors.green
                : AstrideColors.danger,
          ),
        ),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.w900,
          color: AstrideColors.navy,
        ),
      );
}

class _Action extends StatelessWidget {
  const _Action({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: danger
                      ? AstrideColors.danger
                      : AstrideColors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
