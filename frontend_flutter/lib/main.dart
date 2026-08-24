import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const WasteManagementApp(),
  );
}

class WasteManagementApp extends StatelessWidget {
  const WasteManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,

        title: 'Waste Management App',

        theme: ThemeData(
          useMaterial3: true,

          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.green,
          ),

          scaffoldBackgroundColor: Colors.white,

          appBarTheme: const AppBarTheme(
            centerTitle: true,
          ),

          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.grey,
              ),
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Colors.green,
                width: 2,
              ),
            ),
          ),

          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(
                double.infinity,
                52,
              ),

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Application starts from Splash Screen
        initialRoute: '/',

        routes: {
          // -----------------------------
          // Splash
          // -----------------------------
          '/': (context) => const SplashScreen(),

          // -----------------------------
          // Authentication
          // -----------------------------
          '/login': (context) => const LoginScreen(),

          '/register': (context) => const RegisterScreen(),

          '/forgot-password': (context) =>
              const ForgotPasswordScreen(),

          // -----------------------------
          // Role-Based Dashboards
          // -----------------------------
          '/neighbour-dashboard': (context) =>
              const NeighbourDashboard(),

          '/restaurant-dashboard': (context) =>
              const RestaurantDashboard(),

          '/driver-dashboard': (context) =>
              const DriverDashboard(),

          '/recycling-manager-dashboard': (context) =>
              const RecyclingManagerDashboard(),
        },
      ),
    );
  }
}
