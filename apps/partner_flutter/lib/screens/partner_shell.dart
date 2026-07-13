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
    final pages = [
      DashboardScreen(c: widget.c),
      DriversScreen(c: widget.c),
      EarningsScreen(c: widget.c),
      ProfileScreen(c: widget.c),
    ];
    final titles = [
      s.t('dashboard'),
      s.t('drivers'),
      s.t('earnings'),
      s.t('profile'),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(titles[index]),
        actions: [
          IconButton(
            onPressed: widget.c.refresh,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
      ),
      floatingActionButton: widget.c.isPromoter
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => index = 1),
              icon: const Icon(Icons.person_add_alt_1_rounded),
              label: Text(
                widget.c.languageCode == 'bn'
                    ? 'ড্রাইভার যোগ করুন'
                    : widget.c.languageCode == 'hi'
                        ? 'ड्राइवर जोड़ें'
                        : 'Add Driver',
              ),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (v) => setState(() => index = v),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: s.t('dashboard'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.groups_outlined),
            selectedIcon: const Icon(Icons.groups_rounded),
            label: s.t('drivers'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: const Icon(Icons.account_balance_wallet_rounded),
            label: s.t('earnings'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.more_horiz_rounded),
            selectedIcon: const Icon(Icons.more_rounded),
            label: s.t('profile'),
          ),
        ],
      ),
    );
  }
}
