import 'package:flutter/material.dart';

class NeighbourDashboard extends StatelessWidget {
  const NeighbourDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Neighbour Dashboard'),
      ),
      body: const Center(
        child: Text(
          'Neighbour Dashboard',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}