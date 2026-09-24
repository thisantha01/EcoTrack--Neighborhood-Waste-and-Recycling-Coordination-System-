import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/manager_provider.dart';
import 'assign_route_screen.dart';
import 'manager_route_map_screen.dart';

class ManagerRoutesScreen extends StatefulWidget {
  const ManagerRoutesScreen({super.key});

  @override
  State<ManagerRoutesScreen> createState() => _ManagerRoutesScreenState();
}
 
class _ManagerRoutesScreenState extends State<ManagerRoutesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isOptimizing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagerProvider>();
      provider.fetchRoutes();
      provider.fetchAvailableDrivers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ManagerProvider>(
      builder: (context, provider, child) {
        return Scaffold(
          backgroundColor: const Color(0xFFF7FBFB),
          appBar: AppBar(
            title: const Text(
              'Route Management',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF0097A7),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                onPressed: () => _showCreateRoute(),
                icon: const Icon(Icons.add),
                tooltip: 'Create new route',
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white.withValues(alpha: 0.75),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.alt_route, size: 16),
                      const SizedBox(width: 6),
                      Text('Routes (${provider.routes.length})'),
                    ],
                  ),
                ),
                const Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.today, size: 16),
                      SizedBox(width: 6),
                      Text("Today's Route Status"),
                    ],
                  ),
                ),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildRoutesTab(provider),
              _buildTodayRouteStatusTab(provider),
            ],
          ),
          floatingActionButton: _tabController.index == 0
              ? FloatingActionButton.extended(
                  onPressed: _showCreateRoute,
                  backgroundColor: const Color(0xFF0097A7),
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Route'),
                )
              : null,
        );
      },
    );
  }

  Widget _buildRoutesTab(ManagerProvider provider) {
    if (provider.routes.isEmpty) {
      return RefreshIndicator(
        onRefresh: provider.fetchRoutes,
        child: ListView(
          children: const [
            SizedBox(height: 180),
            Center(child: Text('No routes found')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: provider.fetchRoutes,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: provider.routes.length,
        itemBuilder: (context, index) =>
            _routeCard(provider.routes[index]),
      ),
    );
  }

  Widget _routeCard(Map<String, dynamic> route) {
    final driver = route['assignedDriver'];
    final days = (route['operatingDays'] as List? ?? const []).join(', ');
    final status =
        route['routeStatus']?.toString() ??
        route['status']?.toString() ??
        'Inactive';
    final active =
        status == 'Active' || status == 'assigned' || status == 'in-progress';
    final rawStops = (route['routeStops'] as List?) ??
        (route['stops'] as List?) ??
        const [];
    final stops = route['activeStopCount'] ?? rawStops.length;

    final targetWasteType = route['targetWasteType']?.toString() ?? 'weekly_schedule';
    final weeklySchedule = route['weeklyCategorySchedule'] as List? ?? const [];
    final isWeekly = targetWasteType == 'weekly_schedule';

    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final todayName = dayNames[DateTime.now().weekday - 1];

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
        // Legacy migration: Tuesday/Thursday was plastic_paper, Wednesday was organic, Friday was organic
        if ((todayName == 'Tuesday' || todayName == 'Thursday') &&
            (todayCategory == 'plastic_paper' || todayCategory == 'plastic' || todayCategory == 'paper')) {
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
    } else if (todayCategory == 'glass_metal' || todayCategory == 'glass' || todayCategory == 'other') {
      todayCategory = 'glass_others';
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    route['routeName']?.toString() ?? 'Route',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _badge(
                  route['zone']?.toString() ?? 'Area',
                  const Color(0xFFE3F6F7),
                ),
                const SizedBox(width: 6),
                _badge(
                  active ? 'Active' : 'Inactive',
                  active ? const Color(0xFFE1F5EC) : const Color(0xFFF1F1F1),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, size: 20, color: Colors.grey),
                  tooltip: 'Route Actions',
                  onSelected: (val) {
                    if (val == 'edit') {
                      _editRoute(route);
                    } else if (val == 'delete') {
                      _confirmDeleteRoute(route);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_outlined, size: 18, color: Color(0xFF0097A7)),
                          SizedBox(width: 8),
                          Text('Edit Route & Stops'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete Route', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFFDDF7F8),
                  child: Icon(Icons.person, color: const Color(0xFF0097A7)),
                ),
                const SizedBox(width: 10),
                Text(
                  driver is Map
                      ? driver['name']?.toString() ?? 'Unassigned'
                      : 'Unassigned',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _detailRow(Icons.calendar_month_outlined, days.isEmpty ? 'Operating days not set' : days),
            _detailRow(Icons.location_on_outlined, '$stops active waypoints/stops'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _categoryBadge(todayCategory, prefix: isWeekly ? 'Today ($todayName)' : null),
                if (isWeekly)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cached, size: 11, color: Colors.black54),
                        SizedBox(width: 3),
                        Text(
                          'Weekly Schedule',
                          style: TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            if (rawStops.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: rawStops
                    .map((s) => s is Map ? (s['stopName'] ?? s['address'])?.toString() : null)
                    .whereType<String>()
                    .take(4)
                    .map((name) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0097A7).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0097A7).withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place, size: 10, color: Color(0xFF0097A7)),
                        const SizedBox(width: 3),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Color(0xFF007C87),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () => _editRoute(route),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0097A7),
                    side: const BorderSide(color: Color(0xFF0097A7)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showChangeDriver(route),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Driver'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManagerRouteMapScreen(route: route),
                      ),
                    ).then((_) {
                      if (mounted) {
                        context.read<ManagerProvider>().fetchRoutes();
                      }
                    }),
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text('Map / Stops'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0097A7),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Icon(icon, size: 17, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
      ],
    ),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
    ),
  );

  Widget _categoryBadge(String category, {String? prefix}) {
    Color bg;
    Color fg;
    String icon;
    String name;

    switch (category.toLowerCase()) {
      case 'organic':
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        icon = '🥬';
        name = 'Organic';
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
        name = 'All 3 Categories';
        break;
      case 'special_requests':
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFE65100);
        icon = '⭐';
        name = 'Special Requests (All Day)';
        break;
      default:
        bg = const Color(0xFFECEFF1);
        fg = const Color(0xFF455A64);
        icon = '🗑️';
        name = category;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            prefix != null ? '$prefix: $name' : name,
            style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  void _showChangeDriver(Map<String, dynamic> route) {
    String? selectedId = (route['assignedDriver'] is Map)
        ? route['assignedDriver']['_id']?.toString()
        : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) {
          final managerProvider = context.read<ManagerProvider>();
          final drivers = managerProvider.availableDrivers;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Change route driver',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: selectedId,
                  decoration: const InputDecoration(
                    labelText: 'Driver',
                    border: OutlineInputBorder(),
                  ),
                  items: drivers
                      .map((driver) {
                        final id = driver['driverId']?.toString();
                        return id == null
                            ? null
                            : DropdownMenuItem(
                                value: id,
                                child: Text(
                                  driver['name']?.toString() ?? 'Driver',
                                ),
                              );
                      })
                      .whereType<DropdownMenuItem<String>>()
                      .toList(),
                  onChanged: (value) => setModalState(() => selectedId = value),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedId == null
                        ? null
                        : () async {
                            final ok = await managerProvider.changeRouteDriver(
                              routeId: route['_id'].toString(),
                              driverId: selectedId!,
                            );
                            if (!mounted) return;
                            if (sheetContext.mounted) {
                              Navigator.pop(sheetContext);
                            }
                            ScaffoldMessenger.of(this.context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  ok
                                      ? 'Driver changed successfully'
                                      : 'Unable to change driver',
                                ),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0097A7),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save Driver'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _editRoute(Map<String, dynamic> route) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignRouteScreen(initialRoute: route),
      ),
    ).then((_) {
      if (mounted) {
        final provider = context.read<ManagerProvider>();
        provider.fetchRoutes();
        provider.fetchAvailableDrivers();
      }
    });
  }

  void _confirmDeleteRoute(Map<String, dynamic> route) {
    final routeName = route['routeName']?.toString() ?? 'this route';
    final routeId = route['_id']?.toString();
    if (routeId == null) return;

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Delete Route?'),
          ],
        ),
        content: Text(
          'Are you sure you want to delete "$routeName"?\n\nAny scheduled collection requests on this route will revert back to pending.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogCtx);
              final provider = context.read<ManagerProvider>();
              final success = await provider.deleteRoute(routeId);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Route "$routeName" deleted successfully'
                        : (provider.error ?? 'Unable to delete route'),
                  ),
                  backgroundColor: success ? const Color(0xFF0097A7) : Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showCreateRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AssignRouteScreen(),
      ),
    ).then((created) {
      if (mounted) {
        context.read<ManagerProvider>().fetchRoutes();
        context.read<ManagerProvider>().fetchAvailableDrivers();
      }
    });
  }

  Future<void> _optimizeRouteSequence(String routeId) async {
    setState(() => _isOptimizing = true);
    final provider = context.read<ManagerProvider>();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Auto-optimizing route stop sequence...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    final updated = await provider.optimizeRouteSequence(routeId);
    if (!mounted) return;
    setState(() => _isOptimizing = false);
    if (updated != null) {
      await provider.fetchRoutes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Route stops auto-optimized along shortest path!'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to auto-optimize route sequence'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _moveStopUp(Map<String, dynamic> route, int index) async {
    if (index <= 0) return;
    final rawStops = ((route['routeStops'] as List?) ??
            (route['stops'] as List?) ??
            [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (index >= rawStops.length) return;

    final temp = rawStops[index];
    rawStops[index] = rawStops[index - 1];
    rawStops[index - 1] = temp;

    for (int i = 0; i < rawStops.length; i++) {
      rawStops[i]['sequenceOrder'] = i + 1;
    }

    final routeId = route['_id'].toString();
    final provider = context.read<ManagerProvider>();
    final ok = await provider.reorderRouteStops(
      routeId: routeId,
      routeStops: rawStops,
    );

    if (!mounted) return;
    if (ok) {
      await provider.fetchRoutes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop moved up in sequence'),
          duration: Duration(milliseconds: 700),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to reorder stops'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _moveStopDown(Map<String, dynamic> route, int index) async {
    final rawStops = ((route['routeStops'] as List?) ??
            (route['stops'] as List?) ??
            [])
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();

    if (index >= rawStops.length - 1) return;

    final temp = rawStops[index];
    rawStops[index] = rawStops[index + 1];
    rawStops[index + 1] = temp;

    for (int i = 0; i < rawStops.length; i++) {
      rawStops[i]['sequenceOrder'] = i + 1;
    }

    final routeId = route['_id'].toString();
    final provider = context.read<ManagerProvider>();
    final ok = await provider.reorderRouteStops(
      routeId: routeId,
      routeStops: rawStops,
    );

    if (!mounted) return;
    if (ok) {
      await provider.fetchRoutes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop moved down in sequence'),
          duration: Duration(milliseconds: 700),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to reorder stops'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmRemoveStop(
      Map<String, dynamic> route, Map<dynamic, dynamic> stop, int index) async {
    final name = stop['address']?.toString() ?? 'Stop #${index + 1}';
    final routeId = route['_id']?.toString() ?? '';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.remove_circle_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Remove Stop?'),
          ],
        ),
        content: Text('Are you sure you want to remove "$name" from this route?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final provider = context.read<ManagerProvider>();
    final ok = await provider.removeStopFromRoute(
      routeId: routeId,
      stopId: stop['_id']?.toString(),
      collectionRequestId: stop['collectionRequestId'] is Map
          ? stop['collectionRequestId']['_id']?.toString()
          : stop['collectionRequestId']?.toString(),
      sequenceOrder: stop['sequenceOrder'] is num
          ? (stop['sequenceOrder'] as num).toInt()
          : index + 1,
    );

    if (!mounted) return;
    if (ok) {
      await provider.fetchRoutes();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Stop removed from route'),
          backgroundColor: Color(0xFF0097A7),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Failed to remove stop'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTodayRouteStatusTab(ManagerProvider provider) {
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
    final isDedicatedSpecialDay =
        todayName == 'Tuesday' || todayName == 'Thursday';

    final allRoutes = provider.routes;
    final displayedRoutes = List<Map<String, dynamic>>.from(allRoutes);
    displayedRoutes.sort((a, b) {
      final aDays = (a['operatingDays'] as List?) ?? const [];
      final bDays = (b['operatingDays'] as List?) ?? const [];
      final aActive = aDays.isEmpty || aDays.contains(todayName);
      final bActive = bDays.isEmpty || bDays.contains(todayName);
      if (aActive && !bActive) return -1;
      if (!aActive && bActive) return 1;
      return (a['routeName']?.toString() ?? '')
          .compareTo(b['routeName']?.toString() ?? '');
    });

    // Calculate totals across displayed routes
    int totalStopsToday = 0;
    int collectedStopsToday = 0;
    int skippedStopsToday = 0;
    int pendingStopsToday = 0;
    int totalSpecialToday = 0;
    int collectedSpecialToday = 0;
    int totalNormalToday = 0;
    int collectedNormalToday = 0;

    for (final r in displayedRoutes) {
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
          }
        } else {
          totalNormalToday++;
          if (status == 'collected') {
            collectedNormalToday++;
          }
        }
      }
    }

    final double overallProgress =
        totalStopsToday > 0 ? (collectedStopsToday / totalStopsToday) : 0.0;

    return RefreshIndicator(
      onRefresh: () async {
        await Future.wait([
          provider.fetchRoutes(),
          provider.fetchAvailableDrivers(),
        ]);
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 1. Today Overview Header Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF0097A7),
                  Color(0xFF00838F),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0097A7).withValues(alpha: 0.25),
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
                            : '$todayName Collection',
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
                      label: 'Total Stops',
                      value: '$totalStopsToday',
                      color: Colors.white,
                    ),
                    _statBadge(
                      label: 'Completed',
                      value: '$collectedStopsToday',
                      color: const Color(0xFF69F0AE),
                    ),
                    _statBadge(
                      label: 'Pending',
                      value: '$pendingStopsToday',
                      color: const Color(0xFFFFD54F),
                    ),
                    _statBadge(
                      label: 'Skipped',
                      value: '$skippedStopsToday',
                      color: const Color(0xFFFF8A80),
                    ),
                  ],
                ),
                if (totalSpecialToday > 0 || totalNormalToday > 0) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.12),
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
          const SizedBox(height: 14),

          // 2. Section Header: Routes & Today's Operations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Routes & Today\'s Operations (${displayedRoutes.length})',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF006064),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F7FA),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  todayName,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00838F),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 3. Route-wise cards with stop sequence
          if (displayedRoutes.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Icon(Icons.event_busy, size: 56, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No Routes Found',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Create routes in the "Routes" tab to begin monitoring.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            ...displayedRoutes.map((route) {
              return _todayRouteStatusCard(route, provider, todayName);
            }),
        ],
      ),
    );
  }

  Widget _todayRouteStatusCard(
    Map<String, dynamic> route,
    ManagerProvider provider,
    String todayName,
  ) {
    final routeName = route['routeName']?.toString() ?? 'Route';
    final zone = route['zone']?.toString() ?? 'Area';

    final operatingDays = (route['operatingDays'] as List?) ?? const [];
    final operatesToday =
        operatingDays.isEmpty || operatingDays.contains(todayName);

    // Driver lookup
    final rawDriver = route['assignedDriver'];
    String driverName = 'Unassigned';
    String driverPhone = '';
    if (rawDriver is Map) {
      driverName = rawDriver['name']?.toString() ?? 'Unassigned';
      driverPhone = rawDriver['phone']?.toString() ?? '';
    } else if (rawDriver != null && rawDriver.toString().isNotEmpty) {
      final driverId = rawDriver.toString();
      final match = provider.availableDrivers.firstWhere(
        (d) =>
            d['_id']?.toString() == driverId ||
            d['id']?.toString() == driverId,
        orElse: () => {},
      );
      if (match.isNotEmpty && match['name'] != null) {
        driverName = match['name'].toString();
        driverPhone = match['phone']?.toString() ?? '';
      }
    }

    final rawStops = ((route['routeStops'] as List?) ??
            (route['stops'] as List?) ??
            const [])
        .whereType<Map>()
        .toList();

    final int totalStops = rawStops.length;
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

    // Calculate today category
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

    final bool isSpecialDay = todayCategory == 'special_requests' ||
        todayName == 'Tuesday' ||
        todayName == 'Thursday';

    final int effectiveTotalStops = isSpecialDay ? specialCount : totalStops;
    final int effectiveCollectedCount =
        isSpecialDay ? collectedSpecial : collectedCount;

    final double progress = effectiveTotalStops > 0
        ? (effectiveCollectedCount / effectiveTotalStops)
        : 0.0;
    final int pct = (progress * 100).toInt();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: operatesToday ? const Color(0xFFB2EBF2) : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: operatesToday
                    ? const Color(0xFFE0F7FA)
                    : Colors.grey.shade100,
                child: Icon(
                  Icons.alt_route,
                  color: operatesToday
                      ? const Color(0xFF00838F)
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
                        color: Color(0xFF102A2D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isSpecialDay
                          ? '$zone • $specialCount special request pickups'
                          : '$zone • $totalStops stops ($normalCount bins, $specialCount special)',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 13.5,
                          color: driverName != 'Unassigned'
                              ? const Color(0xFF0097A7)
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Driver: $driverName',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: driverName != 'Unassigned'
                                ? const Color(0xFF00796B)
                                : Colors.grey.shade600,
                          ),
                        ),
                        if (driverPhone.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            '($driverPhone)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: operatesToday
                      ? const Color(0xFFE0F7FA)
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: operatesToday
                        ? const Color(0xFF80DEEA)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  operatesToday ? 'Active Today' : 'Off-Schedule',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: operatesToday
                        ? const Color(0xFF00838F)
                        : Colors.grey.shade600,
                  ),
                ),
              ),
            ],
          ),
          _driverCategoryChip(todayCategory, operatesToday, todayName),
          if (effectiveTotalStops > 0) ...[
            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE0F2F1).withValues(alpha: 0.5),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF0097A7)),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isSpecialDay
                      ? 'Progress: $effectiveCollectedCount / $effectiveTotalStops special requests collected'
                      : 'Progress: $effectiveCollectedCount / $effectiveTotalStops collected',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: effectiveCollectedCount == effectiveTotalStops &&
                            effectiveTotalStops > 0
                        ? const Color(0xFF00796B)
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  '$pct%',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00838F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRouteStopsSheet(context, route),
                    icon: const Icon(Icons.format_list_numbered, size: 16),
                    label: Text(
                      isSpecialDay
                          ? 'Stops Sequence ($effectiveCollectedCount/$effectiveTotalStops Special)'
                          : 'Stops Sequence ($effectiveCollectedCount/$effectiveTotalStops)',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF00838F),
                      side: const BorderSide(color: Color(0xFF0097A7)),
                      backgroundColor:
                          const Color(0xFFE0F7FA).withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManagerRouteMapScreen(route: route),
                        ),
                      ).then((_) {
                        if (mounted) {
                          provider.fetchRoutes();
                        }
                      });
                    },
                    icon: const Icon(Icons.map_outlined, size: 16),
                    label: const Text(
                      'Route Map',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0097A7),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 6),
                Text(
                  'No stops added to this route yet.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ManagerRouteMapScreen(route: route),
                      ),
                    ).then((_) {
                      if (mounted) {
                        provider.fetchRoutes();
                      }
                    });
                  },
                  icon: const Icon(Icons.add_location_alt, size: 14),
                  label: const Text('Add Stops / Map',
                      style: TextStyle(fontSize: 11.5)),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0097A7),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
        name = 'All 3 Categories';
        break;
      case 'special_requests':
        bg = const Color(0xFFE0F7FA);
        fg = const Color(0xFF00838F);
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

  void _showRouteStopsSheet(BuildContext context, Map<String, dynamic> route,
      {String initialFilter = 'all'}) {
    String currentFilter = initialFilter;
    final routeId = route['_id']?.toString() ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final managerProvider = sheetContext.watch<ManagerProvider>();
          final liveRoute = managerProvider.routes.firstWhere(
            (r) => r['_id']?.toString() == routeId,
            orElse: () => route,
          );
          final rawStops = ((liveRoute['routeStops'] as List?) ??
                  (liveRoute['stops'] as List?) ??
                  const [])
              .whereType<Map>()
              .toList();

          final int totalStops = rawStops.length;
          int collectedCount = 0;
          int specialCount = 0;
          int normalCount = 0;
          int collectedSpecial = 0;
          int collectedNormal = 0;

          for (final s in rawStops) {
            final isSpecial = s['collectionRequestId'] != null &&
                s['collectionRequestId'].toString().isNotEmpty;
            final isDone =
                (s['status']?.toString() ?? '').toLowerCase() == 'collected';
            if (isDone) collectedCount++;
            if (isSpecial) {
              specialCount++;
              if (isDone) collectedSpecial++;
            } else {
              normalCount++;
              if (isDone) collectedNormal++;
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

          final targetWasteType =
              liveRoute['targetWasteType']?.toString() ?? 'weekly_schedule';
          final weeklySchedule =
              liveRoute['weeklyCategorySchedule'] as List? ?? const [];
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
              } else if (todayName == 'Wednesday' &&
                  todayCategory == 'organic') {
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

          final bool isSpecialDay = todayCategory == 'special_requests' ||
              todayName == 'Tuesday' ||
              todayName == 'Thursday';

          final visibleStopsWithIndex = <MapEntry<int, Map>>[];
          for (int i = 0; i < rawStops.length; i++) {
            final s = rawStops[i];
            final isSpecial = s['collectionRequestId'] != null &&
                s['collectionRequestId'].toString().isNotEmpty;
            if (isSpecialDay) {
              if (!isSpecial) continue;
            } else {
              if (currentFilter == 'special_only' && !isSpecial) continue;
              if (currentFilter == 'normal_only' && isSpecial) continue;
            }
            visibleStopsWithIndex.add(MapEntry(i, s));
          }

          final int displayTotal = isSpecialDay
              ? specialCount
              : (currentFilter == 'special_only'
                  ? specialCount
                  : currentFilter == 'normal_only'
                      ? normalCount
                      : totalStops);
          final int displayCollected = isSpecialDay
              ? collectedSpecial
              : (currentFilter == 'special_only'
                  ? collectedSpecial
                  : currentFilter == 'normal_only'
                      ? collectedNormal
                      : collectedCount);
          final double progressValue =
              displayTotal > 0 ? (displayCollected / displayTotal) : 0.0;
          final int pct = (progressValue * 100).toInt();

          return Container(
            height: MediaQuery.of(sheetContext).size.height * 0.85,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 6),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header: Title, Auto-Optimize, Close
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              liveRoute['routeName']?.toString() ??
                                   'Route Stops',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F2E1D),
                              ),
                            ),
                            Text(
                              isSpecialDay
                                  ? 'Stops Sequence ($specialCount Special Pickups)'
                                  : 'Stops Sequence ($totalStops stops)',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _isOptimizing
                                ? null
                                : () async {
                                    await _optimizeRouteSequence(routeId);
                                    setSheetState(() {});
                                  },
                            icon: const Icon(Icons.auto_awesome,
                                size: 14, color: Color(0xFF00838F)),
                            label: const Text(
                              'Auto-Optimize',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF00838F),
                              ),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFE0F7FA),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () =>
                                Navigator.pop(bottomSheetContext),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Progress Banner
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                                ? 'Special Requests: $collectedSpecial / $specialCount Pickups'
                                : (currentFilter == 'special_only'
                                    ? 'Special Requests: $collectedSpecial / $specialCount'
                                    : currentFilter == 'normal_only'
                                        ? 'Regular Bins: $collectedNormal / $normalCount'
                                        : 'Today\'s Collection: $collectedCount / $totalStops Stops'),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                          Text(
                            '$pct%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00838F),
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
                            Color(0xFF0097A7),
                          ),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (isSpecialDay)
                        const Row(
                          children: [
                            Icon(Icons.stars_rounded,
                                size: 14, color: Color(0xFF00796B)),
                            SizedBox(width: 4),
                            Text(
                              'Special Requests Collection Day: Dedicated pickup schedule',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF00796B),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                                '🏢 Regular Bins: $collectedNormal/$normalCount',
                                style: TextStyle(
                                    fontSize: 11, color: Colors.grey.shade700)),
                            Text(
                                '⭐ Special Requests: $collectedSpecial/$specialCount',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF00796B),
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                    ],
                  ),
                ),

                if (isSpecialDay) ...[
                  Container(
                    margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F7FA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF80DEEA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded,
                            color: Color(0xFF00838F), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Special Requests Collection Day: Normal roadside bins are hidden ($normalCount bins). Only on-demand resident pickups are shown ($specialCount stops).',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF00838F),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Filter chips
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          if (specialCount > 0) ...[
                            FilterChip(
                              label: Text(
                                '⭐ Special Requests ($collectedSpecial/$specialCount)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: currentFilter == 'special_only'
                                      ? const Color(0xFF00838F)
                                      : Colors.grey.shade700,
                                ),
                              ),
                              selected: currentFilter == 'special_only',
                              selectedColor: const Color(0xFFE0F7FA),
                              checkmarkColor: const Color(0xFF00838F),
                              onSelected: (sel) => setSheetState(
                                  () => currentFilter = 'special_only'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          if (normalCount > 0) ...[
                            FilterChip(
                              label: Text(
                                '🏢 Municipal Bins ($collectedNormal/$normalCount)',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: currentFilter == 'normal_only'
                                      ? const Color(0xFF00838F)
                                      : Colors.grey.shade700,
                                ),
                              ),
                              selected: currentFilter == 'normal_only',
                              selectedColor: const Color(0xFFE0F7FA),
                              checkmarkColor: const Color(0xFF00838F),
                              onSelected: (sel) => setSheetState(
                                  () => currentFilter = 'normal_only'),
                            ),
                            const SizedBox(width: 8),
                          ],
                          FilterChip(
                            label: Text(
                              'All Stops ($totalStops)',
                              style: const TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            selected: currentFilter == 'all',
                            selectedColor: Colors.grey.shade200,
                            onSelected: (sel) =>
                                setSheetState(() => currentFilter = 'all'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (currentFilter == 'special_only') ...[
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F7FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF80DEEA)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline,
                              color: Color(0xFF00838F), size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Special Requests Filter: Normal roadside bins are hidden. Only showing resident on-demand pickups.',
                              style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF00838F)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],

                const Divider(height: 1),

                // Stops sequence list
                Expanded(
                  child: visibleStopsWithIndex.isEmpty
                      ? const Center(
                          child: Text(
                            'No stops found for this filter.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                          itemCount: visibleStopsWithIndex.length,
                          itemBuilder: (ctx, listIdx) {
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
                            final isLast =
                                listIdx == visibleStopsWithIndex.length - 1;

                            final loc = stop['location'] as Map?;
                            final lat = loc?['lat'];
                            final lng = loc?['lng'];

                            String? requesterInfo;
                            if (stop['collectionRequestId'] is Map) {
                              final reqMap =
                                  stop['collectionRequestId'] as Map;
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
                                  // Left timeline column
                                  SizedBox(
                                    width: 30,
                                    child: Column(
                                      children: [
                                        CircleAvatar(
                                          radius: 13,
                                          backgroundColor: isCollected
                                              ? const Color(0xFF00897B)
                                              : (isSpecial
                                                  ? const Color(0xFF00838F)
                                                  : const Color(0xFF0097A7)),
                                          foregroundColor: Colors.white,
                                          child: isCollected
                                              ? const Icon(Icons.check,
                                                  size: 13,
                                                  color: Colors.white)
                                              : Text(
                                                  currentFilter ==
                                                          'special_only'
                                                      ? '${listIdx + 1}'
                                                      : '${originalIdx + 1}',
                                                  style: const TextStyle(
                                                    fontSize: 9.5,
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
                                                    ? const Color(0xFF00897B)
                                                    : Colors.grey.shade300,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Right details card
                                  Expanded(
                                    child: Container(
                                      margin:
                                          const EdgeInsets.only(bottom: 10),
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: isCollected
                                            ? const Color(0xFFE0F2F1)
                                            : isSkipped
                                                ? const Color(0xFFFFF1F2)
                                                : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isCollected
                                              ? const Color(0xFF80CBC4)
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
                                              Expanded(
                                                child: Text(
                                                  address,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    decoration: isCollected
                                                        ? TextDecoration
                                                            .lineThrough
                                                        : null,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 5,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isSpecial
                                                      ? const Color(
                                                          0xFFE0F7FA)
                                                      : const Color(
                                                          0xFFE0F2F1),
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                  border: Border.all(
                                                    color: isSpecial
                                                        ? const Color(
                                                            0xFF80DEEA)
                                                        : const Color(
                                                            0xFF80CBC4),
                                                  ),
                                                ),
                                                child: Text(
                                                  isSpecial
                                                      ? '⭐ Special'
                                                      : '🏢 Regular',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: isSpecial
                                                        ? const Color(
                                                            0xFF00838F)
                                                        : const Color(
                                                            0xFF00796B),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (requesterInfo != null) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              requesterInfo,
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF00796B),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                          if (lat != null && lng != null) ...[
                                            const SizedBox(height: 3),
                                            Text(
                                              'Coord: ${(lat as num).toStringAsFixed(5)}, ${(lng as num).toStringAsFixed(5)}',
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 6),

                                          // Actions
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment
                                                    .spaceBetween,
                                            children: [
                                              Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: () async {
                                                      await managerProvider
                                                          .updateRouteStopStatus(
                                                        routeId: routeId,
                                                        stopIndex:
                                                            originalIdx,
                                                        status: isCollected
                                                            ? 'pending'
                                                            : 'collected',
                                                      );
                                                      setSheetState(() {});
                                                    },
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            6),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets
                                                              .symmetric(
                                                              horizontal: 8,
                                                              vertical: 3.5),
                                                      decoration:
                                                          BoxDecoration(
                                                        color: isCollected
                                                            ? const Color(
                                                                0xFFE0F2F1)
                                                            : Colors.grey
                                                                .shade100,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(6),
                                                        border: Border.all(
                                                          color: isCollected
                                                              ? const Color(
                                                                  0xFF80CBC4)
                                                              : Colors.grey
                                                                  .shade300,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            isCollected
                                                                ? Icons
                                                                    .check_circle
                                                                : Icons
                                                                    .radio_button_unchecked,
                                                            size: 13,
                                                            color: isCollected
                                                                ? const Color(
                                                                    0xFF00796B)
                                                                : Colors.grey
                                                                    .shade700,
                                                          ),
                                                          const SizedBox(
                                                              width: 4),
                                                          Text(
                                                            isCollected
                                                                ? 'Collected ✓'
                                                                : 'Mark Done',
                                                            style: TextStyle(
                                                              fontSize: 10.5,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: isCollected
                                                                  ? const Color(
                                                                      0xFF00796B)
                                                                  : Colors
                                                                      .grey
                                                                      .shade800,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                  if (!isCollected &&
                                                      !isSkipped) ...[
                                                    const SizedBox(width: 6),
                                                    InkWell(
                                                      onTap: () async {
                                                        final reason =
                                                            await _promptSkipReason(
                                                                context);
                                                        if (reason != null &&
                                                            mounted) {
                                                          await managerProvider
                                                              .updateRouteStopStatus(
                                                            routeId: routeId,
                                                            stopIndex:
                                                                originalIdx,
                                                            status: 'skipped',
                                                            reason: reason,
                                                          );
                                                          setSheetState(() {});
                                                        }
                                                      },
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(6),
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 8,
                                                                vertical: 3.5),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: Colors
                                                              .grey.shade100,
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      6),
                                                          border: Border.all(
                                                              color: Colors
                                                                  .grey
                                                                  .shade300),
                                                        ),
                                                        child: const Text(
                                                            'Skip',
                                                            style: TextStyle(
                                                                fontSize:
                                                                    10.5,
                                                                color: Colors
                                                                    .black54)),
                                                      ),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                              Row(
                                                mainAxisSize:
                                                    MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.arrow_upward,
                                                        size: 16),
                                                    color: originalIdx > 0
                                                        ? const Color(
                                                            0xFF0097A7)
                                                        : Colors.grey.shade300,
                                                    tooltip: 'Move Up',
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                            minWidth: 28,
                                                            minHeight: 28),
                                                    onPressed:
                                                        originalIdx > 0
                                                            ? () async {
                                                                await _moveStopUp(
                                                                    liveRoute,
                                                                    originalIdx);
                                                                setSheetState(
                                                                    () {});
                                                              }
                                                            : null,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.arrow_downward,
                                                        size: 16),
                                                    color: originalIdx <
                                                            rawStops.length - 1
                                                        ? const Color(
                                                            0xFF0097A7)
                                                        : Colors.grey.shade300,
                                                    tooltip: 'Move Down',
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                            minWidth: 28,
                                                            minHeight: 28),
                                                    onPressed: originalIdx <
                                                            rawStops.length - 1
                                                        ? () async {
                                                                await _moveStopDown(
                                                                    liveRoute,
                                                                    originalIdx);
                                                                setSheetState(
                                                                    () {});
                                                              }
                                                        : null,
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                        Icons.delete_outline,
                                                        size: 16,
                                                        color: Colors.red),
                                                    tooltip: 'Remove Stop',
                                                    padding: EdgeInsets.zero,
                                                    constraints:
                                                        const BoxConstraints(
                                                            minWidth: 28,
                                                            minHeight: 28),
                                                    onPressed: () async {
                                                      await _confirmRemoveStop(
                                                          liveRoute,
                                                          stop,
                                                          originalIdx);
                                                      setSheetState(() {});
                                                    },
                                                  ),
                                                ],
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
              ],
            ),
          );
        },
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
                                ? const Color(0xFF0097A7)
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
                                    ? FontWeight.bold
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
                      backgroundColor: const Color(0xFF0097A7)),
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
