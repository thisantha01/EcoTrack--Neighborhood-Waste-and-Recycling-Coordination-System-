import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../driver/driver_dashboard.dart';
import '../neighbour/neighbour_dashboard.dart';
import '../recycling_manager/recycling_manager_dashboard.dart';
import '../restaurant/restaurant_dashboard.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() =>
      _SplashScreenState();
}

class _SplashScreenState
    extends State<SplashScreen> {

  @override
  void initState() {
    super.initState();

    _checkAuthentication();
  }

  Future<void> _checkAuthentication() async {
    // Give the splash screen a little time to display.
    await Future.delayed(
      const Duration(seconds: 2),
    );

    if (!mounted) return;

    final authProvider =
        context.read<AuthProvider>();

    await authProvider.checkAuthentication();

    if (!mounted) return;

    if (authProvider.isLoggedIn &&
        authProvider.user != null) {

      _navigateBasedOnRole(
        authProvider.user!.role,
      );

    } else {

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
      );
    }
  }

  void _navigateBasedOnRole(String role) {

    switch (role.toLowerCase()) {

      case 'neighbour':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const NeighbourDashboard(),
          ),
        );
        break;

      case 'restaurant_owner':
      case 'restaurant owner':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const RestaurantDashboard(),
          ),
        );
        break;

      case 'driver':
      case 'garbage_collection_driver':
      case 'garbage collection driver':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const DriverDashboard(),
          ),
        );
        break;

      case 'recycling_manager':
      case 'recycling center manager':
      case 'recycling_center_manager':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const RecyclingManagerDashboard(),
          ),
        );
        break;

      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                const LoginScreen(),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [

            // App icon/logo
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(25),
                color: Colors.green,
              ),
              child: const Icon(
                Icons.recycling,
                size: 65,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Waste Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Together for a Cleaner Community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 40),

            const CircularProgressIndicator(),

          ],
        ),
      ),
    );
  }
}