import 'package:flutter/material.dart';
import '../../services/storage_service.dart';

class RecyclingManagerDashboard extends StatelessWidget {
  const RecyclingManagerDashboard({
    super.key,
  });

  Future<void> _logout(BuildContext context) async {
    // Remove saved authentication token
    await StorageService.clearToken();

    // Go back to login screen
    if (context.mounted) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recycling Manager Dashboard',
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _showLogoutConfirmation(context);
            },
          ),
        ],
      ),

      body: const Center(
        child: Text(
          'Recycling Center Manager Dashboard',
          style: TextStyle(
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Logout',
          ),

          content: const Text(
            'Are you sure you want to logout?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _logout(context);
              },
              child: const Text(
                'Logout',
              ),
            ),
          ],
        );
      },
    );
  }
}