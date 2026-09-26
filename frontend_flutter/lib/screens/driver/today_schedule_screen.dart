import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/driver_provider.dart';
import 'pickup_detail_screen.dart';
import 'widgets/driver_bottom_navigation.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key, this.showBottomNavigationBar = true});
  final bool showBottomNavigationBar;

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = context.read<DriverProvider>();
    await Future.wait([
      provider.fetchTodaySchedule(),
      provider.fetchAssignedRoutes(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final stops = <Map<String, dynamic>>[];
    for (final route in provider.assignedRoutes) {
      final routeStops = (route['routeStops'] as List?) ?? const [];
      final legacyStops = (route['stops'] as List?) ?? const [];
      final rawStops = routeStops.isNotEmpty ? routeStops : legacyStops;
      for (var index = 0; index < rawStops.length; index++) {
        final raw = rawStops[index];
        if (raw is! Map) continue;
        stops.add({
          ...Map<String, dynamic>.from(raw),
          'routeId': route['_id']?.toString() ?? '',
          'routeName': route['routeName']?.toString() ?? 'Collection route',
          'stopIndex': index,
        });
      }
    }
    final doneCount = stops.where((s) => s['status'] == 'collected').length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8F6),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text("Today's schedule",
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey.shade700,
          indicatorColor: const Color(0xFF2E7D32),
          tabs: const [
            Tab(text: 'Route stops'),
            Tab(text: 'Other pickups'),
          ],
        ),
      ),
      body: provider.isScheduleLoading || provider.isRoutesLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: TabBarView(
                controller: _tabs,
                children: [
                  _routeStops(stops, doneCount),
                  _directPickups(provider),
                ],
              ),
            ),
      bottomNavigationBar: widget.showBottomNavigationBar
          ? const DriverBottomNavigation(selectedIndex: 1)
          : null,
    );
  }

  Widget _routeStops(List<Map<String, dynamic>> stops, int doneCount) {
    if (stops.isEmpty) {
      return _empty('No route stops assigned today.');
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('$doneCount of ${stops.length} stops collected',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('${stops.length - doneCount} left',
                    style: const TextStyle(color: Color(0xFF52615A))),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final stop in stops) _routeStopCard(stop),
      ],
    );
  }

  Widget _routeStopCard(Map<String, dynamic> stop) {
    final status = (stop['status']?.toString() ?? 'pending').toLowerCase();
    final isCollected = status == 'collected';
    final isSkipped = status == 'skipped';
    final address = stop['address']?.toString().trim();
    final routeName = stop['routeName']?.toString() ?? 'Collection route';
    final request = stop['collectionRequestId'];
    final wasteType = request is Map
        ? request['wasteType']?.toString()
        : stop['wasteType']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(routeName,
                style: const TextStyle(
                    color: Color(0xFF52615A), fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(address == null || address.isEmpty ? 'Address not provided' : address,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            if (wasteType != null && wasteType.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Collect: ${_friendly(wasteType)}'),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    isCollected ? 'Collected' : isSkipped ? 'Skipped' : 'Not collected yet',
                    style: TextStyle(
                      color: isCollected
                          ? const Color(0xFF2E7D32)
                          : isSkipped
                              ? Colors.orange.shade800
                              : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!isCollected)
                  FilledButton.icon(
                    onPressed: () => _setStopStatus(stop, 'collected'),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Collected'),
                  ),
                if (!isCollected && !isSkipped) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _setStopStatus(stop, 'skipped'),
                    child: const Text('Skip'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setStopStatus(Map<String, dynamic> stop, String status) async {
    final ok = await context.read<DriverProvider>().updateRouteStopStatus(
          routeId: stop['routeId']?.toString() ?? '',
          stopId: stop['_id']?.toString(),
          stopIndex: stop['stopIndex'] as int?,
          status: status,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? 'Stop updated.' : 'Could not update this stop. Try again.'),
    ));
  }

  Widget _directPickups(DriverProvider provider) {
    final pickups = provider.scheduleList;
    if (pickups.isEmpty) return _empty('No other pickups assigned today.');
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: pickups.length,
      itemBuilder: (context, index) {
        final pickup = pickups[index];
        final complete = pickup.status == 'completed';
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(pickup.address,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${_friendly(pickup.wasteType)} · ${pickup.weightKg.toStringAsFixed(1)} kg\n${complete ? 'Collected' : 'Pickup to do'}'),
            ),
            isThreeLine: true,
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PickupDetailScreen(pickup: pickup)),
            ),
          ),
        );
      },
    );
  }

  Widget _empty(String message) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 120),
          const Icon(Icons.event_available_outlined,
              size: 54, color: Color(0xFF789080)),
          const SizedBox(height: 12),
          Center(child: Text(message, textAlign: TextAlign.center)),
        ],
      );

  String _friendly(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
