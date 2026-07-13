import 'package:flutter/material.dart';

import '../design/astride_theme.dart';
import '../state/passenger_controller.dart';
import 'astride_home_screen.dart';
import 'booking_screen.dart';
import 'profile_screen.dart';
import 'ride_history_screen.dart';

class PassengerShell extends StatefulWidget {
  const PassengerShell({super.key, required this.controller});
  final PassengerController controller;

  @override
  State<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends State<PassengerShell> {
  int index = 0;

  Future<void> _triggerSos(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Send emergency SOS?'),
        content: const Text(
          'Your live location and active ride details will be sent '
          'to the ASTRIDE Safety Team.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Send SOS'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final incident = await widget.controller.triggerSos();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'SOS sent. Incident ID: ${incident['id'] ?? '-'}',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    }
  }

  void openBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingScreen(controller: widget.controller),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      AstrideHomeScreen(
        t: widget.controller.t,
        onBook: openBooking,
        onSos: () => _triggerSos(context),
      ),
      RideHistoryScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Color(0x180B1D45),
              blurRadius: 20,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined),
              selectedIcon: const Icon(
                Icons.home_rounded,
                color: AstrideColors.greenDark,
              ),
              label: 'Home',
            ),
            NavigationDestination(
              icon: const Icon(Icons.receipt_long_outlined),
              selectedIcon: const Icon(
                Icons.receipt_long_rounded,
                color: AstrideColors.greenDark,
              ),
              label: 'Rides',
            ),
            NavigationDestination(
              icon: const Icon(Icons.person_outline_rounded),
              selectedIcon: const Icon(
                Icons.person_rounded,
                color: AstrideColors.greenDark,
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
