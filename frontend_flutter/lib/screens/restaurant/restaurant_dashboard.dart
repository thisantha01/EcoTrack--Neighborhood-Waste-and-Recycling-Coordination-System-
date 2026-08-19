import 'package:flutter/material.dart';

class RestaurantDashboard extends StatelessWidget {
  const RestaurantDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Restaurant Owner Dashboard',
        ),
      ),
      body: const Center(
        child: Text(
          'Restaurant Owner Dashboard',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}