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
      AstrideHomeScreen(t: widget.controller.t, onBook: openBooking),
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
