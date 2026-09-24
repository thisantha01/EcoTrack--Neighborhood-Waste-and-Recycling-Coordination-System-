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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<DriverProvider>();
      await provider.fetchDashboardData();
      await provider.fetchAssignedRoutes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();
    final driverName = context.watch<AuthProvider>().user?.name ?? 'Driver';

    int totalStopsCount = driverProvider.totalPickups;
    int completedStopsCount = driverProvider.completedPickups;

    for (final r in driverProvider.assignedRoutes) {
      final stops =
          (r['routeStops'] as List?) ?? (r['stops'] as List?) ?? const [];
      totalStopsCount += stops.length;
      completedStopsCount += stops
          .where((s) =>
              s is Map && (s['status']?.toString() ?? '') == 'collected')
          .length;
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      // --- ADDED HEADER (AppBar) WITH LOGOUT ---
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text(
          'EcoTrack',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );
              if (confirmed == true && context.mounted) {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                    (r) => false,
                  );
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
                        completedStops: completedStopsCount,
                        totalStops: totalStopsCount,
                        onViewRoute: _openSchedule,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _AssignedRoutesCard(
                        routes: driverProvider.assignedRoutes,
                        isLoading: driverProvider.isRoutesLoading,
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const TodayScheduleScreen()));
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

class _AssignedRoutesCard extends StatelessWidget {
  final List<Map<String, dynamic>> routes;
  final bool isLoading;

  const _AssignedRoutesCard({required this.routes, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Assigned Fixed Routes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D2818),
                  ),
                ),
                Text(
                  '${routes.length} ${routes.length == 1 ? 'Route' : 'Routes'}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: CircularProgressIndicator(color: Color(0xFF2E7D32)),
                ),
              )
            else if (routes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.alt_route, size: 36, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'No fixed routes assigned yet.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...routes.map((route) {
                final stops = (route['routeStops'] as List?) ??
                    (route['stops'] as List?) ??
                    const [];
                final totalStops = stops.length;
                int collectedCount = 0;
                int collectedSpecial = 0;
                int specialCount = 0;
                int normalCount = 0;

                for (final s in stops) {
                  if (s is Map) {
                    final isSpecial = s['collectionRequestId'] != null &&
                        s['collectionRequestId'].toString().isNotEmpty;
                    if (isSpecial) {
                      specialCount++;
                    } else {
                      normalCount++;
                    }
                    if ((s['status']?.toString() ?? '').toLowerCase() ==
                        'collected') {
                      collectedCount++;
                      if (isSpecial) collectedSpecial++;
                    }
                  }
                }

                const dayNames = [
                  'Monday',
                  'Tuesday',
                  'Wednesday',
                  'Thursday',
                  'Friday',
                  'Saturday',
                  'Sunday'
                ];
                final todayName = dayNames[DateTime.now().weekday - 1];
                final isSpecialDay =
                    todayName == 'Tuesday' || todayName == 'Thursday';

                final int effectiveTotal =
                    isSpecialDay ? specialCount : totalStops;
                final int effectiveCollected =
                    isSpecialDay ? collectedSpecial : collectedCount;
                final pct = effectiveTotal > 0
                    ? (effectiveCollected / effectiveTotal)
                    : 0.0;
                final routeName = route['routeName']?.toString() ?? 'Route';
                final zone = route['zone']?.toString() ?? 'Assigned area';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FBF9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2EBE5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isSpecialDay
                                  ? const Color(0xFFFFF8E1)
                                  : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              isSpecialDay ? Icons.stars_rounded : Icons.alt_route,
                              color: isSpecialDay
                                  ? const Color(0xFFE65100)
                                  : const Color(0xFF2E7D32),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  routeName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Color(0xFF0D2818),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isSpecialDay
                                      ? '$zone • $specialCount special request pickups'
                                      : '$zone • $totalStops stops ($normalCount bins${specialCount > 0 ? ', $specialCount special' : ''})',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              route['status']?.toString() ?? 'Active',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Progress bar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isSpecialDay
                                ? 'Special Pickups Progress'
                                : 'Collection Progress',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$effectiveCollected / $effectiveTotal (${(pct * 100).toInt()}%)',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2E7D32)),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: Icon(
                                  isSpecialDay
                                      ? Icons.stars_rounded
                                      : Icons.format_list_numbered,
                                  size: 15),
                              label: Text(
                                isSpecialDay
                                    ? 'Special Sequence ($effectiveCollected/$effectiveTotal)'
                                    : 'Stops Sequence ($effectiveCollected/$effectiveTotal)',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF2E7D32),
                                side: const BorderSide(
                                    color: Color(0xFF2E7D32)),
                                backgroundColor: const Color(0xFFE8F5E9)
                                    .withValues(alpha: 0.3),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: () {
                                _showDriverRouteStopsSheet(context, route);
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.schedule, size: 15),
                            label: const Text(
                              'Schedule',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TodayScheduleScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _showDriverRouteStopsSheet(
      BuildContext context, Map<String, dynamic> initialRoute) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bottomSheetContext) {
        String filter = 'all'; // 'all', 'special_only', 'normal_only'
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final driverProvider = ctx.watch<DriverProvider>();
            final routeId = initialRoute['_id']?.toString() ?? '';
            final liveRoute = driverProvider.assignedRoutes.firstWhere(
              (r) => r['_id']?.toString() == routeId,
              orElse: () => initialRoute,
            );

            final rawStops = ((liveRoute['routeStops'] as List?) ??
                    (liveRoute['stops'] as List?) ??
                    const [])
                .whereType<Map>()
                .toList();

            final totalStops = rawStops.length;
            int specialCount = 0;
            int normalCount = 0;
            int collectedCount = 0;
            int collectedSpecial = 0;
            int collectedNormal = 0;

            for (final s in rawStops) {
              final isSpecial = s['collectionRequestId'] != null &&
                  s['collectionRequestId'].toString().isNotEmpty;
              final isDone =
                  (s['status']?.toString() ?? '').toLowerCase() == 'collected';
              if (isSpecial) {
                specialCount++;
                if (isDone) collectedSpecial++;
              } else {
                normalCount++;
                if (isDone) collectedNormal++;
              }
              if (isDone) collectedCount++;
            }

            const dayNames = [
              'Monday',
              'Tuesday',
              'Wednesday',
              'Thursday',
              'Friday',
              'Saturday',
              'Sunday'
            ];
            final todayName = dayNames[DateTime.now().weekday - 1];
            final isSpecialDay =
                todayName == 'Tuesday' || todayName == 'Thursday';

            final visibleStopsWithIndex = <MapEntry<int, Map>>[];
            for (int i = 0; i < rawStops.length; i++) {
              final s = rawStops[i];
              final isSpecial = s['collectionRequestId'] != null &&
                  s['collectionRequestId'].toString().isNotEmpty;
              if (isSpecialDay) {
                if (!isSpecial) continue;
              } else {
                if (filter == 'special_only' && !isSpecial) continue;
                if (filter == 'normal_only' && isSpecial) continue;
              }
              visibleStopsWithIndex.add(MapEntry(i, s));
            }

            final displayTotal = isSpecialDay
                ? specialCount
                : (filter == 'special_only'
                    ? specialCount
                    : (filter == 'normal_only' ? normalCount : totalStops));
            final displayCollected = isSpecialDay
                ? collectedSpecial
                : (filter == 'special_only'
                    ? collectedSpecial
                    : (filter == 'normal_only'
                        ? collectedNormal
                        : collectedCount));
            final progressValue =
                displayTotal > 0 ? (displayCollected / displayTotal) : 0.0;

            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.85,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (scrollContext, scrollController) {
                return Column(
                  children: [
                    // Drag handle
                    Container(
                      margin: const EdgeInsets.only(top: 10, bottom: 6),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Sheet Header
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  liveRoute['routeName']?.toString() ??
                                      'Route Stops Sequence',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F2E1D),
                                  ),
                                ),
                                Text(
                                  isSpecialDay
                                      ? 'Special Pickups Sequence ($specialCount stops • ${liveRoute['zone'] ?? ''})'
                                      : 'Stops Sequence ($totalStops stops • ${liveRoute['zone'] ?? ''})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(bottomSheetContext),
                          ),
                        ],
                      ),
                    ),

                    // Progress Banner
                    Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                isSpecialDay
                                    ? 'Special Requests: $collectedSpecial / $specialCount'
                                    : (filter == 'special_only'
                                        ? 'Special Requests: $collectedSpecial / $specialCount'
                                        : filter == 'normal_only'
                                            ? 'Regular Bins: $collectedNormal / $normalCount'
                                            : 'Today\'s Progress: $collectedCount / $totalStops Stops'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                '${(progressValue * 100).toInt()}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progressValue,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF2E7D32),
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (isSpecialDay) ...[
                      Container(
                        margin: const EdgeInsets.fromLTRB(16, 4, 16, 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: const Color(0xFFFFB74D)
                                  .withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded,
                                color: Color(0xFFE65100), size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Special Requests Collection Day: Regular roadside bins are excluded ($normalCount bins hidden). Showing only on-demand resident pickups ($specialCount stops).',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE65100),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // Filter chips
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              if (specialCount > 0) ...[
                                FilterChip(
                                  label: Text(
                                    '⭐ Special Only ($collectedSpecial/$specialCount)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: filter == 'special_only'
                                          ? const Color(0xFFE65100)
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  selected: filter == 'special_only',
                                  selectedColor: const Color(0xFFFFF8E1),
                                  checkmarkColor: const Color(0xFFE65100),
                                  onSelected: (sel) => setSheetState(
                                      () => filter = 'special_only'),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (normalCount > 0) ...[
                                FilterChip(
                                  label: Text(
                                    '🏢 Bins Only ($collectedNormal/$normalCount)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: filter == 'normal_only'
                                          ? const Color(0xFF2E7D32)
                                          : Colors.grey.shade700,
                                    ),
                                  ),
                                  selected: filter == 'normal_only',
                                  selectedColor: const Color(0xFFE8F5E9),
                                  checkmarkColor: const Color(0xFF2E7D32),
                                  onSelected: (sel) => setSheetState(
                                      () => filter = 'normal_only'),
                                ),
                                const SizedBox(width: 8),
                              ],
                              FilterChip(
                                label: Text(
                                  'All Stops ($totalStops)',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold),
                                ),
                                selected: filter == 'all',
                                selectedColor: Colors.grey.shade200,
                                onSelected: (sel) =>
                                    setSheetState(() => filter = 'all'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                    const Divider(height: 1),

                    // Stops Sequence List with Line Bar
                    Expanded(
                      child: visibleStopsWithIndex.isEmpty
                          ? const Center(
                              child: Text(
                                'No stops found for this filter.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.fromLTRB(
                                  16, 12, 16, 16),
                              itemCount: visibleStopsWithIndex.length,
                              itemBuilder: (itemCtx, listIdx) {
                                final entry = visibleStopsWithIndex[listIdx];
                                final originalIdx = entry.key;
                                final stop = entry.value;

                                final isSpecial =
                                    stop['collectionRequestId'] != null &&
                                        stop['collectionRequestId']
                                            .toString()
                                            .isNotEmpty;
                                final status = (stop['status']?.toString() ??
                                        'pending')
                                    .toLowerCase();
                                final address = stop['address']?.toString() ??
                                    'Stop #${originalIdx + 1}';
                                final isCollected = status == 'collected';
                                final isSkipped = status == 'skipped';
                                final isLast = listIdx ==
                                    visibleStopsWithIndex.length - 1;

                                return IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Left timeline column with line bar
                                      SizedBox(
                                        width: 32,
                                        child: Column(
                                          children: [
                                            CircleAvatar(
                                              radius: 14,
                                              backgroundColor: isCollected
                                                  ? const Color(0xFF2E7D32)
                                                  : (isSpecial
                                                      ? const Color(0xFFE65100)
                                                      : const Color(
                                                          0xFF2E7D32)),
                                              foregroundColor: Colors.white,
                                              child: isCollected
                                                  ? const Icon(Icons.check,
                                                      size: 14,
                                                      color: Colors.white)
                                                  : Text(
                                                      filter == 'special_only'
                                                          ? '${listIdx + 1}'
                                                          : '${originalIdx + 1}',
                                                      style: const TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                            ),
                                            if (!isLast)
                                              Expanded(
                                                child: Center(
                                                  child: Container(
                                                    width: 3,
                                                    color: isCollected
                                                        ? const Color(
                                                            0xFF2E7D32)
                                                        : Colors.grey.shade300,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      // Right stop card
                                      Expanded(
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                              bottom: 12),
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: isCollected
                                                ? const Color(0xFFF0FDF4)
                                                : isSkipped
                                                    ? const Color(0xFFFFF1F2)
                                                    : Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: isCollected
                                                  ? const Color(0xFFBBF7D0)
                                                  : isSkipped
                                                      ? const Color(0xFFFECDD3)
                                                      : Colors.grey.shade200,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isSpecial
                                                          ? const Color(
                                                              0xFFFFF8E1)
                                                          : const Color(
                                                              0xFFE8F5E9),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      isSpecial
                                                          ? '⭐ Special'
                                                          : '🏢 Regular Bin',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isSpecial
                                                            ? const Color(
                                                                0xFFE65100)
                                                            : const Color(
                                                                0xFF2E7D32),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                            vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: isCollected
                                                          ? const Color(
                                                              0xFFDCFCE7)
                                                          : isSkipped
                                                              ? const Color(
                                                                  0xFFFFE4E6)
                                                              : Colors
                                                                  .grey.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                    ),
                                                    child: Text(
                                                      isCollected
                                                          ? 'Collected ✓'
                                                          : isSkipped
                                                              ? 'Skipped ⏭️'
                                                              : 'Pending ⏳',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: isCollected
                                                            ? const Color(
                                                                0xFF15803D)
                                                            : isSkipped
                                                                ? const Color(
                                                                    0xFFBE123C)
                                                                : Colors.grey
                                                                    .shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                address,
                                                style: const TextStyle(
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: [
                                                  if (!isCollected)
                                                    ElevatedButton.icon(
                                                      style:
                                                          ElevatedButton.styleFrom(
                                                        backgroundColor:
                                                            const Color(
                                                                0xFF2E7D32),
                                                        foregroundColor:
                                                            Colors.white,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                        minimumSize: Size.zero,
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                      ),
                                                      icon: const Icon(
                                                          Icons.check,
                                                          size: 13),
                                                      label: const Text(
                                                        'Mark Done',
                                                        style: TextStyle(
                                                          fontSize: 10.5,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                      onPressed: () async {
                                                        await ctx
                                                            .read<
                                                                DriverProvider>()
                                                            .updateRouteStopStatus(
                                                              routeId: routeId,
                                                              stopIndex:
                                                                  originalIdx,
                                                              status:
                                                                  'collected',
                                                            );
                                                      },
                                                    ),
                                                  if (!isCollected &&
                                                      !isSkipped) ...[
                                                    const SizedBox(width: 6),
                                                    OutlinedButton(
                                                      style:
                                                          OutlinedButton.styleFrom(
                                                        foregroundColor:
                                                            Colors
                                                                .grey.shade700,
                                                        side: BorderSide(
                                                            color: Colors
                                                                .grey.shade300),
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3),
                                                        minimumSize: Size.zero,
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                        shape:
                                                            RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(6),
                                                        ),
                                                      ),
                                                      child: const Text('Skip',
                                                          style: TextStyle(
                                                              fontSize: 10.5)),
                                                      onPressed: () async {
                                                        final driverProv = ctx
                                                            .read<
                                                                DriverProvider>();
                                                        final reason =
                                                            await _promptSkipReason(
                                                                ctx);
                                                        if (reason != null) {
                                                          await driverProv
                                                              .updateRouteStopStatus(
                                                                routeId:
                                                                    routeId,
                                                                stopIndex:
                                                                    originalIdx,
                                                                status:
                                                                    'skipped',
                                                                reason: reason,
                                                              );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                  if (isCollected)
                                                    TextButton(
                                                      style:
                                                          TextButton.styleFrom(
                                                        foregroundColor: Colors
                                                            .grey.shade600,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 6,
                                                                vertical: 2),
                                                        minimumSize: Size.zero,
                                                        tapTargetSize:
                                                            MaterialTapTargetSize
                                                                .shrinkWrap,
                                                      ),
                                                      child: const Text(
                                                        'Undo (Mark Pending)',
                                                        style: TextStyle(
                                                            fontSize: 10.5),
                                                      ),
                                                      onPressed: () async {
                                                        await ctx
                                                            .read<
                                                                DriverProvider>()
                                                            .updateRouteStopStatus(
                                                              routeId: routeId,
                                                              stopIndex:
                                                                  originalIdx,
                                                              status: 'pending',
                                                            );
                                                      },
                                                    ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),

                    // Open Full Schedule Button
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(bottomSheetContext);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TodayScheduleScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.calendar_today, size: 16),
                          label: const Text(
                            'Open in Full Schedule View',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2E7D32),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Future<String?> _promptSkipReason(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) {
        String? selectedReason = 'Resident not available';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Reason for Skipping Stop',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  'Resident not available',
                  'Bin / Waste not placed outside',
                  'Road blocked / Inaccessible',
                  'Wrong waste type',
                  'Other',
                ].map((reason) {
                  final isSelected = selectedReason == reason;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedReason = reason),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: Row(
                        children: [
                          Icon(
                            isSelected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: isSelected
                                ? const Color(0xFF2E7D32)
                                : Colors.grey,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              reason,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32)),
                  onPressed: () => Navigator.pop(ctx, selectedReason),
                  child: const Text('Confirm Skip',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
