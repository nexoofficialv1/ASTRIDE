import 'package:flutter/material.dart';
import '../state/passenger_controller.dart';
import 'astride_home_screen.dart';
import 'booking_screen.dart';
import 'ride_history_screen.dart';
import 'profile_screen.dart';

class PassengerShell extends StatefulWidget {
  const PassengerShell({super.key, required this.controller});
  final PassengerController controller;
  @override
  State<PassengerShell> createState() => _PassengerShellState();
}

class _PassengerShellState extends State<PassengerShell> {
  int index = 0;
  void openBooking() => Navigator.push(context, MaterialPageRoute(builder: (_) => BookingScreen(controller: widget.controller)));

  @override
  Widget build(BuildContext context) {
    final pages = [
      AstrideHomeScreen(t: widget.controller.t, onBook: openBooking),
      RideHistoryScreen(controller: widget.controller),
      ProfileScreen(controller: widget.controller),
    ];
    return Scaffold(
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home_rounded), label: widget.controller.t('home')),
          NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long_rounded), label: widget.controller.t('rides')),
          NavigationDestination(icon: const Icon(Icons.person_outline_rounded), selectedIcon: const Icon(Icons.person_rounded), label: widget.controller.t('profile')),
        ],
      ),
    );
  }
}
