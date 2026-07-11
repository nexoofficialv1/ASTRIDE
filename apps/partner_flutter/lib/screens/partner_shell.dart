import 'package:flutter/material.dart';
import '../state/partner_controller.dart';
import 'dashboard_screen.dart';
import 'drivers_screen.dart';
import 'earnings_screen.dart';
import 'profile_screen.dart';

class PartnerShell extends StatefulWidget {
  const PartnerShell({super.key, required this.c});
  final PartnerController c;
  @override
  State<PartnerShell> createState() => _PartnerShellState();
}

class _PartnerShellState extends State<PartnerShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final s = widget.c.strings;
    final pages = [DashboardScreen(c: widget.c), DriversScreen(c: widget.c), EarningsScreen(c: widget.c), ProfileScreen(c: widget.c)];
    return Scaffold(
      appBar: AppBar(title: Text(s.t('app')), centerTitle: false),
      body: AnimatedSwitcher(duration: const Duration(milliseconds: 220), child: KeyedSubtree(key: ValueKey(index), child: pages[index])),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.dashboard_outlined), selectedIcon: const Icon(Icons.dashboard_rounded), label: s.t('dashboard')),
          NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups_rounded), label: s.t('drivers')),
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet_rounded), label: s.t('earnings')),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: s.t('profile')),
        ],
      ),
    );
  }
}
