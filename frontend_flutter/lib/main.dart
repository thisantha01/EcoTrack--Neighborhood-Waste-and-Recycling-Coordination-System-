import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/manager_provider.dart';
import 'providers/driver_provider.dart';

// Splash Screen
import 'screens/splash/splash_screen.dart';

// Authentication Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';

// Role Dashboards
import 'screens/neighbour/neighbour_dashboard.dart';
import 'screens/restaurant/restaurant_dashboard.dart';
import 'screens/driver/driver_dashboard.dart';
import 'screens/recycling_manager/recycling_manager_dashboard.dart';

// Profile
import 'screens/profile/profile_screen.dart';

// Community
import 'screens/community/community_hub_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const WasteManagementApp());
}

class WasteManagementApp extends StatelessWidget {
  const WasteManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ManagerProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        title: 'EcoTrack',

        theme: ThemeData(
          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),

          scaffoldBackgroundColor: Colors.white,

          fontFamily: 'Roboto',

          appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,

            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 52),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        initialRoute: '/',

        routes: {
          // Splash
          '/': (context) => const SplashScreen(),

          // Authentication
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),

          // Role-Based Dashboards
          '/neighbour-dashboard': (context) => const NeighbourDashboard(),
          '/restaurant-dashboard': (context) => const RestaurantDashboard(),
          '/driver-dashboard': (context) => const DriverDashboard(),
          '/recycling-manager-dashboard': (context) =>
              const RecyclingManagerDashboard(),

          // Standalone routes
          '/profile': (context) => const ProfileScreen(),
          '/community': (context) => const CommunityHubScreen(),
        },
      ),
    );
  }
}
