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

class DriverDashboard extends StatefulWidget {
  const DriverDashboard({super.key});

  @override
  State<DriverDashboard> createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
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
      body: SafeArea(
        child: driverProvider.isDashboardLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
              )
            : RefreshIndicator(
                color: const Color(0xFF2E7D32),
                onRefresh: () => context.read<DriverProvider>().fetchDashboardData(),
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
