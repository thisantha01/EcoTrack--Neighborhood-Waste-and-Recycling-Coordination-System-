import 'package:flutter/material.dart';

import '../../../config/app_routes.dart';

/// Shared navigation for driver tabs. Embedded dashboard pages provide a
/// callback; standalone driver pages return to the dashboard at the chosen tab.
class DriverBottomNavigationBar extends StatelessWidget {
  const DriverBottomNavigationBar({
    super.key,
    required this.selectedIndex,
    this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;

  static const destinations = [
    NavigationDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: 'Dashboard',
    ),
    NavigationDestination(
      icon: Icon(Icons.alt_route_outlined),
      selectedIcon: Icon(Icons.alt_route),
      label: "Today's Route",
    ),
    NavigationDestination(
      icon: Icon(Icons.add_circle_outline),
      selectedIcon: Icon(Icons.add_circle),
      label: 'Schedule',
    ),
    NavigationDestination(
      icon: Icon(Icons.scale_outlined),
      selectedIcon: Icon(Icons.scale),
      label: 'Weigh-in',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  void _select(BuildContext context, int index) {
    if (onDestinationSelected != null) {
      onDestinationSelected!(index);
      return;
    }
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.driverDashboard,
      (_) => false,
      arguments: index,
    );
  }

  @override
  Widget build(BuildContext context) => NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) => _select(context, index),
        indicatorColor: const Color(0xFFE8F5E9),
        destinations: destinations,
      );
}
