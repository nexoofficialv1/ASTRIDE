import 'package:flutter/material.dart';
import '../state/driver_controller.dart';
import 'astride_driver_dashboard.dart';
import 'ride/active_ride_screen.dart';
import 'ride/ride_history_driver_screen.dart';
import 'earnings/driver_earnings_screen.dart';
import 'driver_profile_screen.dart';
import 'performance/driver_performance_screen.dart';
import 'new_ride_request_screen.dart';
import 'tools/driver_tools_screen.dart';

class DriverShell extends StatefulWidget {
  const DriverShell({super.key, required this.controller});
  final DriverController controller;
  @override State<DriverShell> createState() => _DriverShellState();
}
class _DriverShellState extends State<DriverShell> {
  int index = 0;
  String? lastRideId;

  @override
  void initState() {
    super.initState();
    lastRideId = widget.controller.activeRide?['id']?.toString();
    widget.controller.addListener(_syncAssignedRide);
  }

  void _syncAssignedRide() {
    final rideId =
        widget.controller.activeRide?['id']?.toString();
    if (!mounted) return;
    if (rideId != null && rideId != lastRideId) {
      lastRideId = rideId;
      setState(() => index = 1);
    } else if (rideId == null) {
      lastRideId = null;
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncAssignedRide);
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final c = widget.controller;
    final pages = [
      AstrideDriverDashboard(
        controller: c,
        onNavigate: (value) => setState(() => index = value),
        onSupport: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverSupportScreen(controller: c),
          ),
        ),
        onDocuments: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverDocumentsScreen(controller: c),
          ),
        ),
        onSafety: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverSafetyScreen(controller: c),
          ),
        ),
      ),
      c.activeRide == null ? RideHistoryDriverScreen(controller:c) : ActiveRideScreen(controller:c),
      DriverEarningsScreen(controller:c),
      DriverPerformanceScreen(controller:c),
      DriverProfileScreen(controller:c),
    ];
    return Scaffold(
      body: Stack(children:[
        IndexedStack(index:index,children:pages),
        if(c.request!=null) Positioned.fill(child:NewRideRequestScreen(controller:c)),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex:index,
        onDestinationSelected:(v)=>setState(()=>index=v),
        destinations:[
          NavigationDestination(icon:const Icon(Icons.home_outlined),selectedIcon:const Icon(Icons.home),label:c.t('home')),
          NavigationDestination(icon:const Icon(Icons.route_outlined),selectedIcon:const Icon(Icons.route),label:c.t('rides')),
          NavigationDestination(icon:const Icon(Icons.account_balance_wallet_outlined),selectedIcon:const Icon(Icons.account_balance_wallet),label:c.t('earnings')),
          NavigationDestination(icon:const Icon(Icons.analytics_outlined),selectedIcon:const Icon(Icons.analytics),label:c.t('performance')),
          NavigationDestination(icon:const Icon(Icons.person_outline),selectedIcon:const Icon(Icons.person),label:c.t('profile')),
        ],
      ),
    );
  }
}
