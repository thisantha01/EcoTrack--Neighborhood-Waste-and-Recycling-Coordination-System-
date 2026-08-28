import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/pickup_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/driver_provider.dart';
import 'today_schedule_screen.dart';
import 'widgets/driver_header.dart';
import 'widgets/metric_summary_card.dart';
import 'widgets/next_pickup_card.dart';
import 'widgets/route_progress_card.dart';

import '../profile/profile_screen.dart'; 

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Define the pages for the bottom navigation
    final List<Widget> pages = [
      const _DriverHome(),
      const TodayScheduleScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        // Using a green tint to match the driver theme, similar to the manager's purple tint
        indicatorColor: const Color(0xFFE8F5E9), 
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFF2E7D32)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.schedule_outlined),
            selectedIcon: Icon(Icons.schedule, color: Color(0xFF2E7D32)),
            label: 'Schedule',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF2E7D32)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// Extracted the original dashboard content into its own widget to house the AppBar
class _DriverHome extends StatefulWidget {
  const _DriverHome();

  @override
  State<_DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<_DriverHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DriverProvider>().fetchDashboardData(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();
    final driverName = context.watch<AuthProvider>().user?.name ?? 'Driver';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      // --- ADDED HEADER (AppBar) WITH LOGOUT ---
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('EcoTrack',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Logout')),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/login', (r) => false);
                }
              }
            },
          ),
        ],
      ),
      // --- ORIGINAL BODY CONTENT (Unchanged) ---
      body: driverProvider.isDashboardLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
            )
          : RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: () =>
                  context.read<DriverProvider>().fetchDashboardData(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DriverHeader(
                      driverName: driverName,
                      isAvailable: driverProvider.isAvailable,
                      onToggleAvailability: _toggleAvailability,
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: MetricSummaryCard(
                              iconWidget: const Icon(
                                Icons.local_shipping_outlined,
                                color: Color(0xFF2E7D32),
                                size: 22,
                              ),
                              title: "Today's Pickups",
                              count: driverProvider.totalPickups,
                              onTap: _openSchedule,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricSummaryCard(
                              iconWidget: _metricIcon(Icons.check),
                              title: 'Completed',
                              count: driverProvider.completedPickups,
                              onTap: _openSchedule,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: MetricSummaryCard(
                              iconWidget: _metricIcon(Icons.access_time_filled),
                              title: 'Remaining',
                              count: driverProvider.remainingPickups,
                              onTap: _openSchedule,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: RouteProgressCard(
                        completedStops: driverProvider.completedPickups,
                        totalStops: driverProvider.totalPickups,
                        onViewRoute: _openSchedule,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: NextPickupCard(
                        pickup: driverProvider.nextPickup,
                        onViewPickup: _showPickupDetails,
                        onStartPickup: _updatePickup,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _metricIcon(IconData icon) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Color(0xFF2E7D32),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: Colors.white, size: 15),
    );
  }

  void _openSchedule() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TodayScheduleScreen()),
    );
  }

  Future<void> _toggleAvailability() async {
    final updated = await context.read<DriverProvider>().toggleAvailability();
    if (!updated && mounted) {
      _showMessage('Could not update availability. Please try again.');
    }
  }

  Future<void> _updatePickup(PickupModel pickup) async {
    final provider = context.read<DriverProvider>();
    final updated = pickup.status == 'accepted'
        ? await provider.completePickup(pickup.id)
        : await provider.startPickup(pickup.id);
    if (!updated && mounted) {
      _showMessage('Could not update the pickup. Please try again.');
    }
  }

  void _showPickupDetails(PickupModel pickup) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pickup ${pickup.pickupNumber}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Customer: ${pickup.customerName}'),
            Text('Address: ${pickup.address}'),
            Text('Waste: ${pickup.wasteType} (${pickup.weightKg} kg)'),
            Text('Scheduled: ${pickup.scheduledTime}'),
            if (pickup.notes?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text('Notes: ${pickup.notes}'),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(sheetContext),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}