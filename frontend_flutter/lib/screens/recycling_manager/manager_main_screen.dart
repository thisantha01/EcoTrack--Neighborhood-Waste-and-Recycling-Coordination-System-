import 'package:flutter/material.dart';
import 'recycling_manager_dashboard.dart';
import 'assign_route_screen.dart';

class ManagerMainScreen extends StatefulWidget {
  const ManagerMainScreen({Key? key}) : super(key: key);

  @override
  State<ManagerMainScreen> createState() => _ManagerMainScreenState();
}

class _ManagerMainScreenState extends State<ManagerMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    RecyclingManagerDashboard(),
    AssignRouteScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.green[700],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.alt_route_rounded),
            label: 'Assign Routes',
          ),
        ],
      ),
    );
  }
}