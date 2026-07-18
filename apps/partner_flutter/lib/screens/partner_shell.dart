import 'package:flutter/material.dart';

import '../state/partner_controller.dart';
import '../widgets/brand/astride_wordmark.dart';
import 'partner_dashboard_screen.dart';
import 'partner_drivers_screen.dart';
import 'partner_earnings_screen.dart';
import 'partner_profile_screen.dart';

class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key, required this.controller});
  final PartnerController controller;

  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      PartnerDashboardScreen(controller: widget.controller),
      PartnerDriversScreen(controller: widget.controller),
      PartnerEarningsScreen(controller: widget.controller),
      PartnerProfileScreen(controller: widget.controller),
    ];
    const titles = ['Dashboard', 'Drivers', 'Earnings', 'Profile'];
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [const AstrideWordmark(compact: true), const Spacer(), Text(titles[index], style: const TextStyle(fontSize: 16))]),
        actions: [IconButton(onPressed: widget.controller.busy ? null : widget.controller.refreshAll, icon: const Icon(Icons.refresh))],
      ),
      body: Column(children: [
        if (widget.controller.error != null)
          MaterialBanner(
            content: const Text('Partner data could not be loaded. Please retry.'),
            actions: [TextButton(onPressed: widget.controller.refreshAll, child: const Text('Retry'))],
          ),
        Expanded(child: IndexedStack(index: index, children: pages)),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), selectedIcon: Icon(Icons.groups), label: 'Drivers'),
          NavigationDestination(icon: Icon(Icons.currency_rupee_outlined), selectedIcon: Icon(Icons.currency_rupee), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
