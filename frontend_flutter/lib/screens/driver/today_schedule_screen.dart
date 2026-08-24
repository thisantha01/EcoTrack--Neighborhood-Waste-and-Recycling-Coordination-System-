import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/pickup_model.dart';
import '../../providers/driver_provider.dart';
import 'widgets/schedule_timeline_item.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => context.read<DriverProvider>().fetchTodaySchedule(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF0F2E1D)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Today's Schedule", style: TextStyle(color: Color(0xFF0F2E1D), fontWeight: FontWeight.bold, fontSize: 20)),
        centerTitle: true,
      ),
      body: driverProvider.isScheduleLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: () => context.read<DriverProvider>().fetchTodaySchedule(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_formattedToday(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F2E1D))),
                  ),
                  Expanded(child: _buildSchedule(driverProvider)),
                ],
              ),
            ),
    );
  }

  Widget _buildSchedule(DriverProvider provider) {
    if (provider.scheduleList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.event_available_outlined, size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text('No pickups scheduled for today', textAlign: TextAlign.center, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(provider.errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
          ],
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: provider.scheduleList.length,
      itemBuilder: (context, index) {
        final pickup = provider.scheduleList[index];
        return ScheduleTimelineItem(
          pickup: pickup,
          isLast: index == provider.scheduleList.length - 1,
          onTap: () => _showPickupDetails(pickup),
        );
      },
    );
  }

  String _formattedToday() {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
    final today = DateTime.now();
    return '${weekdays[today.weekday - 1]}, ${today.day} ${months[today.month - 1]}';
  }

  void _showPickupDetails(PickupModel pickup) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pickup ${pickup.pickupNumber}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('Customer: ${pickup.customerName}'),
            Text('Address: ${pickup.address}'),
            Text('Scheduled: ${pickup.scheduledTime}'),
            const SizedBox(height: 16),
            if (pickup.status != 'completed')
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    final provider = context.read<DriverProvider>();
                    final updated = pickup.status == 'accepted'
                        ? await provider.completePickup(pickup.id)
                        : await provider.startPickup(pickup.id);
                    if (!mounted) return;
                    Navigator.pop(sheetContext);
                    if (!updated) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not update the pickup. Please try again.')));
                    }
                  },
                  child: Text(pickup.status == 'accepted' ? 'Complete Pickup' : 'Start Pickup'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
