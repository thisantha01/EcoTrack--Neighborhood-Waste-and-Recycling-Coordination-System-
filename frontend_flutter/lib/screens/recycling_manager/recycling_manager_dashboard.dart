import 'package:flutter/material.dart';

class RecyclingManagerDashboard
    extends StatelessWidget {
  const RecyclingManagerDashboard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recycling Manager Dashboard',
        ),
      ),
      body: const Center(
        child: Text(
          'Recycling Center Manager Dashboard',
          style: TextStyle(fontSize: 22),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}