import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/driver_provider.dart';
import 'pickup_detail_screen.dart';
import 'widgets/schedule_timeline_item.dart';

class TodayScheduleScreen extends StatefulWidget {
  const TodayScheduleScreen({super.key});

  @override
  State<TodayScheduleScreen> createState() => _TodayScheduleScreenState();
}

class _TodayScheduleScreenState extends State<TodayScheduleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _routeStopFilter = 'all'; // 'special_only', 'normal_only', 'all'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _routeStopFilter = 'all';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DriverProvider>();
      provider.fetchTodaySchedule();
      provider.fetchAssignedRoutes();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = context.watch<DriverProvider>();
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

    // Calculate all route stops
    int totalRouteStops = 0;
    int collectedRouteStops = 0;
    for (final r in driverProvider.assignedRoutes) {
      final stops = (r['routeStops'] as List?) ??
          (r['stops'] as List?) ??
          const [];
      totalRouteStops += stops.length;
      collectedRouteStops += stops
          .where((s) =>
              s is Map && (s['status']?.toString() ?? '') == 'collected')
          .length;
    }

    final totalDirectPickups = driverProvider.scheduleList.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF0F2E1D)),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          "Today's Schedule",
          style: TextStyle(
              color: Color(0xFF0F2E1D),
              fontWeight: FontWeight.bold,
              fontSize: 20),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF2E7D32),
          unselectedLabelColor: Colors.grey.shade600,
          indicatorColor: const Color(0xFF2E7D32),
          indicatorWeight: 3,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.alt_route, size: 16),
                  const SizedBox(width: 6),
                  Text('Route Stops ($totalRouteStops)'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.local_shipping_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('Direct Pickups ($totalDirectPickups)'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: driverProvider.isScheduleLoading || driverProvider.isRoutesLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : RefreshIndicator(
              color: const Color(0xFF2E7D32),
              onRefresh: () async {
                final p = context.read<DriverProvider>();
                await Future.wait([
                  p.fetchTodaySchedule(),
                  p.fetchAssignedRoutes(),
                ]);
              },
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRouteStopsTab(
                      driverProvider, todayName, collectedRouteStops, totalRouteStops),
                  _buildDirectPickupsTab(driverProvider),
                ],
              ),
            ),
    );
  }

  Widget _buildRouteStopsTab(
    DriverProvider provider,
    String todayName,
    int collectedStops,
    int totalStops,
  ) {
    final allRoutes = List<Map<String, dynamic>>.from(provider.assignedRoutes);
    allRoutes.sort((a, b) {
      final aDays = (a['operatingDays'] as List?) ?? const [];
      final bDays = (b['operatingDays'] as List?) ?? const [];
      final aActive = aDays.isEmpty || aDays.contains(todayName);
      final bActive = bDays.isEmpty || bDays.contains(todayName);
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      return (a['routeName']?.toString() ?? '')
          .compareTo(b['routeName']?.toString() ?? '');
    });

    if (allRoutes.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [
          SizedBox(height: 60),
          Icon(
            Icons.route_outlined,
            size: 64,
            color: Color(0xFF94A3B8),
          ),
          SizedBox(height: 16),
          Text(
            'No routes assigned yet',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Your manager has not assigned any collection routes to you yet. Please check back later or contact your supervisor.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF64748B), height: 1.4),
          ),
        ],
      );
    }

    // Calculate totals across all assigned routes
    int totalStopsToday = 0;
    int collectedStopsToday = 0;
    int skippedStopsToday = 0;
    int pendingStopsToday = 0;
    int totalSpecialToday = 0;
    int collectedSpecialToday = 0;
    int skippedSpecialToday = 0;
    int pendingSpecialToday = 0;
    int totalNormalToday = 0;
    int collectedNormalToday = 0;

    for (final r in allRoutes) {
      final rawStops = ((r['routeStops'] as List?) ??
              (r['stops'] as List?) ??
              const [])
          .whereType<Map>();
      for (final s in rawStops) {
        totalStopsToday++;
        final isSpecial = s['collectionRequestId'] != null &&
            s['collectionRequestId'].toString().isNotEmpty;
        final status = (s['status']?.toString() ?? 'pending').toLowerCase();
        if (status == 'collected') {
          collectedStopsToday++;
        } else if (status == 'skipped') {
          skippedStopsToday++;
        } else {
          pendingStopsToday++;
        }

        if (isSpecial) {
          totalSpecialToday++;
          if (status == 'collected') {
            collectedSpecialToday++;
          } else if (status == 'skipped') {
            skippedSpecialToday++;
          } else {
            pendingSpecialToday++;
          }
        } else {
          totalNormalToday++;
          if (status == 'collected') {
            collectedNormalToday++;
          }
        }
      }
    }

    final bool isDedicatedSpecialDay =
        todayName == 'Tuesday' || todayName == 'Thursday';

    final double overallProgress = isDedicatedSpecialDay
        ? (totalSpecialToday > 0 ? (collectedSpecialToday / totalSpecialToday) : 0.0)
        : (totalStopsToday > 0 ? (collectedStopsToday / totalStopsToday) : 0.0);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        // 1. Overview Header Card (Driver Green gradient)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF2E7D32),
                Color(0xFF1B5E20),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formattedToday(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isDedicatedSpecialDay
                          ? '⭐ Special Requests Day'
                          : '$todayName Operations',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: overallProgress,
                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF69F0AE)),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _statBadge(
                    label: isDedicatedSpecialDay ? 'Special Pickups' : 'Total Stops',
                    value: isDedicatedSpecialDay ? '$totalSpecialToday' : '$totalStopsToday',
                    color: Colors.white,
                  ),
                  _statBadge(
                    label: 'Completed',
                    value: isDedicatedSpecialDay ? '$collectedSpecialToday' : '$collectedStopsToday',
                    color: const Color(0xFF69F0AE),
                  ),
                  _statBadge(
                    label: 'Pending',
                    value: isDedicatedSpecialDay ? '$pendingSpecialToday' : '$pendingStopsToday',
                    color: const Color(0xFFFFD54F),
                  ),
                  _statBadge(
                    label: 'Skipped',
                    value: isDedicatedSpecialDay ? '$skippedSpecialToday' : '$skippedStopsToday',
                    color: const Color(0xFFFF8A80),
                  ),
                ],
              ),
              if (isDedicatedSpecialDay) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '⭐ Special Pickups: $collectedSpecialToday / $totalSpecialToday',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '🏢 Regular Bins: $totalNormalToday (Hidden today)',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (totalSpecialToday > 0 || totalNormalToday > 0) ...[
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '🏢 Municipal Bins: $collectedNormalToday / $totalNormalToday',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '⭐ Special Requests: $collectedSpecialToday / $totalSpecialToday',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. Filter selection chips (Only on normal days when multiple categories exist)
        if (!isDedicatedSpecialDay) ...[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: Text(
                    'All Stops ($totalStopsToday)',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: _routeStopFilter == 'all'
                          ? const Color(0xFF2E7D32)
                          : Colors.grey.shade700,
                    ),
                  ),
                  selected: _routeStopFilter == 'all',
                  selectedColor: const Color(0xFFE8F5E9),
                  checkmarkColor: const Color(0xFF2E7D32),
                  onSelected: (sel) => setState(() => _routeStopFilter = 'all'),
                ),
                const SizedBox(width: 8),
                if (totalNormalToday > 0) ...[
                  FilterChip(
                    label: Text(
                      '🏢 Regular Bins ($collectedNormalToday/$totalNormalToday)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _routeStopFilter == 'normal_only'
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade700,
                      ),
                    ),
                    selected: _routeStopFilter == 'normal_only',
                    selectedColor: const Color(0xFFE8F5E9),
                    checkmarkColor: const Color(0xFF2E7D32),
                    onSelected: (sel) =>
                        setState(() => _routeStopFilter = 'normal_only'),
                  ),
                  const SizedBox(width: 8),
                ],
                if (totalSpecialToday > 0) ...[
                  FilterChip(
                    label: Text(
                      '⭐ Special Requests ($collectedSpecialToday/$totalSpecialToday)',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _routeStopFilter == 'special_only'
                            ? const Color(0xFFE65100)
                            : Colors.grey.shade700,
                      ),
                    ),
                    selected: _routeStopFilter == 'special_only',
                    selectedColor: const Color(0xFFFFF8E1),
                    checkmarkColor: const Color(0xFFE65100),
                    onSelected: (sel) =>
                        setState(() => _routeStopFilter = 'special_only'),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Section Header: Assigned Routes & Sequence
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Assigned Routes (${allRoutes.length})',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F2E1D),
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                todayName,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Route by Route cards with stop sequence
        ...allRoutes.map((route) => _buildDriverRouteCard(route, todayName)),
      ],
    );
  }

  Widget _buildDriverRouteCard(
    Map<String, dynamic> route,
    String todayName,
  ) {
    final routeId = route['_id']?.toString() ?? '';
    final routeName = route['routeName']?.toString() ?? 'Route';
    final zone = route['zone']?.toString() ?? 'Area';

    final operatingDays = (route['operatingDays'] as List?) ?? const [];
    final operatesToday =
        operatingDays.isEmpty || operatingDays.contains(todayName);

    final rawStops = ((route['routeStops'] as List?) ??
            (route['stops'] as List?) ??
            const [])
        .whereType<Map>()
        .toList();

    int collectedCount = 0;
    int specialCount = 0;
    int normalCount = 0;
    int collectedSpecial = 0;

    for (final s in rawStops) {
      final hasReq = s['collectionRequestId'] != null &&
          s['collectionRequestId'].toString().isNotEmpty;
      final isDone =
          (s['status']?.toString() ?? '').toLowerCase() == 'collected';
      if (isDone) collectedCount++;
      if (hasReq) {
        specialCount++;
        if (isDone) collectedSpecial++;
      } else {
        normalCount++;
      }
    }

    final todayCategory = _getTodayCategory(route, todayName);
    final bool isSpecialDay = todayCategory == 'special_requests' ||
        todayName == 'Tuesday' ||
        todayName == 'Thursday';

    // On special request collection days: ONLY show the special request sequence stops!
    final visibleStopsWithIndex = <MapEntry<int, Map>>[];
    for (int i = 0; i < rawStops.length; i++) {
      final s = rawStops[i];
      final isSpecial = s['collectionRequestId'] != null &&
          s['collectionRequestId'].toString().isNotEmpty;
      if (isSpecialDay) {
        if (!isSpecial) continue; // EXCLUDE normal roadside bins on special request collection days
      } else {
        if (_routeStopFilter == 'special_only' && !isSpecial) continue;
        if (_routeStopFilter == 'normal_only' && isSpecial) continue;
      }
      visibleStopsWithIndex.add(MapEntry(i, s));
    }

    final int effectiveTotal = isSpecialDay ? specialCount : rawStops.length;
    final int effectiveCollected =
        isSpecialDay ? collectedSpecial : collectedCount;
    final double progress =
        effectiveTotal > 0 ? (effectiveCollected / effectiveTotal) : 0.0;
    final int pct = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: operatesToday ? const Color(0xFFA5D6A7) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Route Header
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: operatesToday
                          ? const Color(0xFFE8F5E9)
                          : Colors.grey.shade100,
                      child: Icon(
                        Icons.alt_route,
                        color: operatesToday
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade600,
                        size: 18,
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
                              fontSize: 15,
                              color: Color(0xFF0F2E1D),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isSpecialDay
                                ? '$zone • $specialCount special request pickups'
                                : '$zone • ${rawStops.length} stops ($normalCount bins${specialCount > 0 ? ', $specialCount special' : ''})',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: operatesToday
                            ? const Color(0xFFE8F5E9)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: operatesToday
                              ? const Color(0xFFA5D6A7)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Text(
                        operatesToday ? 'Active Today' : 'Off-Schedule',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: operatesToday
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                _driverCategoryChip(todayCategory, operatesToday, todayName),
                if (isSpecialDay) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8E1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color:
                              const Color(0xFFFFB74D).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: Color(0xFFE65100), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Special Requests Collection Day: Roadside bins are excluded ($normalCount bins hidden). Showing only on-demand resident pickups ($specialCount stops).',
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
                ],
                if (effectiveTotal > 0) ...[
                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      backgroundColor:
                          const Color(0xFFE8F5E9).withValues(alpha: 0.5),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2E7D32)),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isSpecialDay
                            ? 'Special Pickups: $effectiveCollected / $effectiveTotal collected'
                            : 'Route Progress: $effectiveCollected / $effectiveTotal collected',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: effectiveCollected == effectiveTotal &&
                                  effectiveTotal > 0
                              ? const Color(0xFF2E7D32)
                              : Colors.grey.shade700,
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          const Divider(height: 1),

          // Stops Timeline
          if (visibleStopsWithIndex.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      isSpecialDay
                          ? Icons.check_circle_outline
                          : Icons.location_off_outlined,
                      size: 36,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isSpecialDay
                          ? 'No special requests scheduled for this route today.'
                          : rawStops.isEmpty
                              ? 'No stops added to this route yet.'
                              : 'No stops matching the current filter.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isSpecialDay && normalCount > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Regular roadside bins ($normalCount bins) are not scheduled today.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Icon(
                          isSpecialDay
                              ? Icons.stars_rounded
                              : Icons.format_list_numbered,
                          size: 15,
                          color: isSpecialDay
                              ? const Color(0xFFE65100)
                              : const Color(0xFF2E7D32),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isSpecialDay
                              ? 'Special Pickups Sequence (${visibleStopsWithIndex.length} stops)'
                              : 'Stops Sequence (${visibleStopsWithIndex.length} stops)',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F2E1D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...List.generate(visibleStopsWithIndex.length, (listIdx) {
                    final entry = visibleStopsWithIndex[listIdx];
                    final originalIdx = entry.key;
                    final stop = entry.value;

                    final isSpecial = stop['collectionRequestId'] != null &&
                        stop['collectionRequestId'].toString().isNotEmpty;
                    final status =
                        (stop['status']?.toString() ?? 'pending').toLowerCase();
                    final address = stop['address']?.toString() ??
                        'Stop #${originalIdx + 1}';
                    final isCollected = status == 'collected';
                    final isSkipped = status == 'skipped';
                    final skipReason = stop['skipReason']?.toString();
                    final isLast = listIdx == visibleStopsWithIndex.length - 1;

                    String? requesterInfo;
                    if (stop['collectionRequestId'] is Map) {
                      final reqMap = stop['collectionRequestId'] as Map;
                      if (reqMap['requester'] is Map) {
                        final u = reqMap['requester'] as Map;
                        final name = u['name']?.toString() ?? '';
                        final phone = u['phone']?.toString() ?? '';
                        if (name.isNotEmpty) {
                          requesterInfo =
                              'Resident: $name ${phone.isNotEmpty ? '($phone)' : ''}';
                        }
                      }
                    }

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left timeline column with node & line
                          SizedBox(
                            width: 32,
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: isCollected
                                      ? const Color(0xFF2E7D32)
                                      : isSkipped
                                          ? const Color(0xFFE53935)
                                          : isSpecial
                                              ? const Color(0xFFE65100)
                                              : const Color(0xFF2E7D32),
                                  foregroundColor: Colors.white,
                                  child: isCollected
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 14)
                                      : isSkipped
                                          ? const Icon(Icons.close,
                                              color: Colors.white, size: 14)
                                          : Text(
                                              isSpecialDay
                                                  ? '${listIdx + 1}'
                                                  : '${originalIdx + 1}',
                                              style: const TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                ),
                                if (!isLast)
                                  Expanded(
                                    child: Center(
                                      child: Container(
                                        width: 3,
                                        color: isCollected
                                            ? const Color(0xFF2E7D32)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Stop details & actions card
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isCollected
                                    ? const Color(0xFFF0FDF4)
                                    : isSkipped
                                        ? const Color(0xFFFFF1F2)
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isCollected
                                      ? const Color(0xFFBBF7D0)
                                      : isSkipped
                                          ? const Color(0xFFFECDD3)
                                          : Colors.grey.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSpecial
                                              ? const Color(0xFFFFF8E1)
                                              : const Color(0xFFE8F5E9),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isSpecial
                                              ? '⭐ Special Request'
                                              : '🏢 Regular Bin',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isSpecial
                                                ? const Color(0xFFE65100)
                                                : const Color(0xFF2E7D32),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isCollected
                                              ? const Color(0xFFDCFCE7)
                                              : isSkipped
                                                  ? const Color(0xFFFFE4E6)
                                                  : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          isCollected
                                              ? 'Collected ✓'
                                              : isSkipped
                                                  ? 'Skipped ⏭️'
                                                  : 'Pending ⏳',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: isCollected
                                                ? const Color(0xFF15803D)
                                                : isSkipped
                                                    ? const Color(0xFFBE123C)
                                                    : Colors.grey.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    address,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      decoration: isCollected
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color: isCollected
                                          ? Colors.grey.shade600
                                          : const Color(0xFF0F2E1D),
                                    ),
                                  ),
                                  if (requesterInfo != null) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      requesterInfo,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                  if (isSkipped &&
                                      skipReason != null &&
                                      skipReason.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      'Reason: $skipReason',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 8),

                                  // Action buttons
                                  Row(
                                    children: [
                                      if (!isCollected)
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                const Color(0xFF2E7D32),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          icon:
                                              const Icon(Icons.check, size: 14),
                                          label: const Text(
                                            'Mark Done',
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () async {
                                            await context
                                                .read<DriverProvider>()
                                                .updateRouteStopStatus(
                                                  routeId: routeId,
                                                  stopIndex: originalIdx,
                                                  status: 'collected',
                                                );
                                          },
                                        ),
                                      if (!isCollected && !isSkipped) ...[
                                        const SizedBox(width: 8),
                                        OutlinedButton(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                Colors.grey.shade700,
                                            side: BorderSide(
                                                color: Colors.grey.shade300),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 4),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                          child: const Text('Skip',
                                              style: TextStyle(fontSize: 11)),
                                          onPressed: () async {
                                            final reason =
                                                await _promptSkipReason(
                                                    context);
                                            if (reason != null && mounted) {
                                              await context
                                                  .read<DriverProvider>()
                                                  .updateRouteStopStatus(
                                                    routeId: routeId,
                                                    stopIndex: originalIdx,
                                                    status: 'skipped',
                                                    reason: reason,
                                                  );
                                            }
                                          },
                                        ),
                                      ],
                                      if (isCollected || isSkipped)
                                        TextButton(
                                          style: TextButton.styleFrom(
                                            foregroundColor:
                                                Colors.grey.shade600,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize
                                                .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Undo (Mark Pending)',
                                            style: TextStyle(fontSize: 11),
                                          ),
                                          onPressed: () async {
                                            await context
                                                .read<DriverProvider>()
                                                .updateRouteStopStatus(
                                                  routeId: routeId,
                                                  stopIndex: originalIdx,
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
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _getTodayCategory(Map<String, dynamic> route, String todayName) {
    final targetWasteType =
        route['targetWasteType']?.toString() ?? 'weekly_schedule';
    final weeklySchedule =
        route['weeklyCategorySchedule'] as List? ?? const [];
    final isWeekly = targetWasteType == 'weekly_schedule';

    String todayCategory = 'organic';
    if (!isWeekly && targetWasteType.isNotEmpty) {
      todayCategory = targetWasteType;
    } else if (weeklySchedule.isNotEmpty) {
      final found = weeklySchedule.firstWhere(
        (s) => s is Map && s['day'] == todayName,
        orElse: () => null,
      );
      if (found is Map && found['category'] != null) {
        todayCategory = found['category'].toString();
        if ((todayName == 'Tuesday' || todayName == 'Thursday') &&
            (todayCategory == 'plastic_paper' ||
                todayCategory == 'plastic' ||
                todayCategory == 'paper')) {
          todayCategory = 'special_requests';
        } else if (todayName == 'Wednesday' && todayCategory == 'organic') {
          todayCategory = 'plastic_paper';
        } else if (todayName == 'Friday' && todayCategory == 'organic') {
          todayCategory = 'glass_others';
        }
      } else {
        if (todayName == 'Tuesday' || todayName == 'Thursday') {
          todayCategory = 'special_requests';
        } else if (todayName == 'Wednesday') {
          todayCategory = 'plastic_paper';
        } else if (todayName == 'Friday') {
          todayCategory = 'glass_others';
        } else if (todayName == 'Saturday') {
          todayCategory = 'special_requests';
        } else {
          todayCategory = 'organic';
        }
      }
    } else {
      if (todayName == 'Tuesday' || todayName == 'Thursday') {
        todayCategory = 'special_requests';
      } else if (todayName == 'Wednesday') {
        todayCategory = 'plastic_paper';
      } else if (todayName == 'Friday') {
        todayCategory = 'glass_others';
      } else if (todayName == 'Saturday') {
        todayCategory = 'special_requests';
      } else {
        todayCategory = 'organic';
      }
    }

    if (todayCategory == 'plastic' || todayCategory == 'paper') {
      todayCategory = 'plastic_paper';
    } else if (todayCategory == 'glass_metal' ||
        todayCategory == 'glass' ||
        todayCategory == 'other') {
      todayCategory = 'glass_others';
    }

    return todayCategory;
  }

  Widget _driverCategoryChip(
      String category, bool operatesToday, String todayName) {
    Color bg;
    Color fg;
    String icon;
    String name;

    switch (category.toLowerCase()) {
      case 'organic':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = '🥬';
        name = 'Organic Waste';
        break;
      case 'plastic_paper':
      case 'plastic':
      case 'paper':
        bg = const Color(0xFFE1F5FE);
        fg = const Color(0xFF0288D1);
        icon = '🧴📦';
        name = 'Plastic & Paper';
        break;
      case 'glass_others':
      case 'glass_metal':
      case 'glass':
      case 'other':
        bg = const Color(0xFFEDE7F6);
        fg = const Color(0xFF5E35B1);
        icon = '🍾';
        name = 'Glass & Others';
        break;
      case 'all':
        bg = const Color(0xFFE0F2F1);
        fg = const Color(0xFF00796B);
        icon = '♻️';
        name = 'All Categories';
        break;
      case 'special_requests':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFE65100);
        icon = '⭐';
        name = 'Special Requests Day';
        break;
      default:
        bg = const Color(0xFFECEFF1);
        fg = const Color(0xFF455A64);
        icon = '🗑️';
        name = category;
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '$todayName Category: $name',
              style: TextStyle(
                color: fg,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBadge({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildDirectPickupsTab(DriverProvider provider) {
    if (provider.scheduleList.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 80),
          const Icon(Icons.event_available_outlined,
              size: 56, color: Color(0xFF94A3B8)),
          const SizedBox(height: 16),
          const Text('No direct pickups scheduled for today',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
          if (provider.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(provider.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF64748B))),
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PickupDetailScreen(pickup: pickup),
              ),
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

  String _formattedToday() {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final today = DateTime.now();
    return '${weekdays[today.weekday - 1]}, ${today.day} ${months[today.month - 1]}';
  }
}