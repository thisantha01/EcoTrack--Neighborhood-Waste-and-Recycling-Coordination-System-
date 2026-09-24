import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/manager_provider.dart';
import 'assign_route_screen.dart';

class ManagerRouteMapScreen extends StatefulWidget {
  final Map<String, dynamic> route;

  const ManagerRouteMapScreen({super.key, required this.route});

  @override
  State<ManagerRouteMapScreen> createState() => _ManagerRouteMapScreenState();
}

class _ManagerRouteMapScreenState extends State<ManagerRouteMapScreen> {
  static const LatLng _malabeDefault = LatLng(6.9061, 79.9696);
  late Map<String, dynamic> _currentRoute;
  bool _showStopList = false;

  @override
  void initState() {
    super.initState();
    _currentRoute = Map<String, dynamic>.from(widget.route);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: const Color(0xFF0097A7),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  void _openEditRoute() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AssignRouteScreen(initialRoute: _currentRoute),
      ),
    ).then((_) {
      if (mounted) {
        final provider = context.read<ManagerProvider>();
        final routeId = _currentRoute['_id']?.toString();
        if (routeId != null) {
          final updated = provider.routes.firstWhere(
            (r) => r['_id']?.toString() == routeId,
            orElse: () => _currentRoute,
          );
          setState(() {
            _currentRoute = Map<String, dynamic>.from(updated);
          });
        }
      }
    });
  }

  bool _isOptimizing = false;

  Future<void> _optimizeSequence() async {
    final stops = ((_currentRoute['routeStops'] as List?) ??
            (_currentRoute['stops'] as List?) ??
            [])
        .whereType<Map>()
        .toList();
    if (stops.length <= 2) {
      _showMessage('Need at least 3 stops to auto-optimize sequence');
      return;
    }

    setState(() => _isOptimizing = true);
    final routeId = _currentRoute['_id'].toString();
    final provider = context.read<ManagerProvider>();
    final updated = await provider.optimizeRouteSequence(routeId);
    setState(() => _isOptimizing = false);

    if (updated != null) {
      setState(() {
        _currentRoute = updated;
      });
      _showMessage('Route stops auto-optimized along shortest path!');
    } else {
      _showMessage(provider.error ?? 'Failed to optimize route sequence');
    }
  }

  Future<void> _updateStopStatus(int stopIndex, String newStatus) async {
    final routeId = _currentRoute['_id'].toString();
    final provider = context.read<ManagerProvider>();
    final ok = await provider.updateRouteStopStatus(
      routeId: routeId,
      stopIndex: stopIndex,
      status: newStatus,
    );
    if (ok) {
      setState(() {
        final raw = ((_currentRoute['routeStops'] as List?) ??
                (_currentRoute['stops'] as List?) ??
                [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        if (stopIndex >= 0 && stopIndex < raw.length) {
          raw[stopIndex]['status'] = newStatus;
          _currentRoute['routeStops'] = raw;
          _currentRoute['stops'] = raw;
        }
      });
      _showMessage('Stop marked as $newStatus');
    } else {
      _showMessage(provider.error ?? 'Failed to update stop status');
    }
  }

  Future<void> _moveStopUp(int index, List<Map<String, dynamic>> stops) async {
    if (index <= 0) return;
    final updatedStops = List<Map<String, dynamic>>.from(stops);
    final temp = updatedStops[index];
    updatedStops[index] = updatedStops[index - 1];
    updatedStops[index - 1] = temp;

    for (int i = 0; i < updatedStops.length; i++) {
      updatedStops[i]['sequenceOrder'] = i + 1;
    }

    final routeId = _currentRoute['_id'].toString();
    final provider = context.read<ManagerProvider>();

    final ok = await provider.reorderRouteStops(
      routeId: routeId,
      routeStops: updatedStops,
    );

    if (ok) {
      setState(() {
        _currentRoute['routeStops'] = updatedStops;
        _currentRoute['stops'] = updatedStops;
      });
      _showMessage('Stop moved up in sequence');
    } else {
      _showMessage(provider.error ?? 'Failed to reorder stops');
    }
  }

  Future<void> _moveStopDown(int index, List<Map<String, dynamic>> stops) async {
    if (index >= stops.length - 1) return;
    final updatedStops = List<Map<String, dynamic>>.from(stops);
    final temp = updatedStops[index];
    updatedStops[index] = updatedStops[index + 1];
    updatedStops[index + 1] = temp;

    for (int i = 0; i < updatedStops.length; i++) {
      updatedStops[i]['sequenceOrder'] = i + 1;
    }

    final routeId = _currentRoute['_id'].toString();
    final provider = context.read<ManagerProvider>();

    final ok = await provider.reorderRouteStops(
      routeId: routeId,
      routeStops: updatedStops,
    );

    if (ok) {
      setState(() {
        _currentRoute['routeStops'] = updatedStops;
        _currentRoute['stops'] = updatedStops;
      });
      _showMessage('Stop moved down in sequence');
    } else {
      _showMessage(provider.error ?? 'Failed to reorder stops');
    }
  }

  Future<void> _confirmRemoveStop(Map<String, dynamic> stop, int index) async {
    final name = stop['address']?.toString() ?? 'Stop ${index + 1}';
    final routeId = _currentRoute['_id'].toString();

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

    if (ok) {
      setState(() {
        final raw = ((_currentRoute['routeStops'] as List?) ??
                (_currentRoute['stops'] as List?) ??
                [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        raw.removeWhere((s) {
          if (stop['_id'] != null && s['_id']?.toString() == stop['_id']?.toString()) {
            return true;
          }
          if (stop['collectionRequestId'] != null &&
              s['collectionRequestId']?.toString() == stop['collectionRequestId']?.toString()) {
            return true;
          }
          return s['sequenceOrder'] == stop['sequenceOrder'];
        });

        for (int i = 0; i < raw.length; i++) {
          raw[i]['sequenceOrder'] = i + 1;
        }

        _currentRoute['routeStops'] = raw;
        _currentRoute['stops'] = raw;
      });
      _showMessage('Stop removed successfully');
    } else {
      _showMessage(provider.error ?? 'Failed to remove stop');
    }
  }

  void _showAddStopDialog({LatLng? initialPos}) {
    final nameController = TextEditingController();
    final latController = TextEditingController(
      text: initialPos != null ? initialPos.latitude.toStringAsFixed(6) : '6.9061',
    );
    final lngController = TextEditingController(
      text: initialPos != null ? initialPos.longitude.toStringAsFixed(6) : '79.9696',
    );

    final malabePresets = [
      {'name': 'SLIIT Campus (New Kandy Rd)', 'lat': 6.9147, 'lng': 79.9733},
      {'name': 'Horizon Campus / Knowledge City', 'lat': 6.9110, 'lng': 79.9805},
      {'name': 'Kaduwela Rd - Pittugala Stop', 'lat': 6.9090, 'lng': 79.9660},
      {'name': 'Malabe Junction (Kaduwela Rd)', 'lat': 6.9042, 'lng': 79.9572},
      {'name': 'Kothalawala Interchange', 'lat': 6.9205, 'lng': 79.9790},
      {'name': 'Chandrika Kumaratunga Mw', 'lat': 6.9015, 'lng': 79.9720},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            20,
            20,
            MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Stop to Route',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetCtx),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Quick Malabe Landmarks:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: malabePresets.map((preset) {
                  return ActionChip(
                    label: Text(preset['name'] as String, style: const TextStyle(fontSize: 11)),
                    backgroundColor: const Color(0xFF0097A7).withValues(alpha: 0.1),
                    onPressed: () {
                      setModalState(() {
                        nameController.text = preset['name'] as String;
                        latController.text = (preset['lat'] as double).toString();
                        lngController.text = (preset['lng'] as double).toString();
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Stop Name / Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF0097A7)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Latitude',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: lngController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Longitude',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final address = nameController.text.trim();
                    final lat = double.tryParse(latController.text.trim());
                    final lng = double.tryParse(lngController.text.trim());

                    if (address.isEmpty || lat == null || lng == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please provide a stop name and valid coordinates')),
                      );
                      return;
                    }

                    Navigator.pop(sheetCtx);
                    final routeId = _currentRoute['_id'].toString();
                    final provider = context.read<ManagerProvider>();

                    final ok = await provider.addStopToRoute(
                      routeId: routeId,
                      lat: lat,
                      lng: lng,
                      address: address,
                    );

                    if (ok) {
                      final updated = provider.routes.firstWhere(
                        (r) => r['_id']?.toString() == routeId,
                        orElse: () => _currentRoute,
                      );
                      setState(() {
                        _currentRoute = Map<String, dynamic>.from(updated);
                      });
                      _showMessage('Stop added to route successfully');
                    } else {
                      _showMessage(provider.error ?? 'Failed to add stop');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0097A7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.add_location_alt_outlined),
                  label: const Text('Add Stop', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final area = _currentRoute['areaCoordinates'];
    final LatLng center = area is Map && area['lat'] is num && area['lng'] is num
        ? LatLng(
            (area['lat'] as num).toDouble(),
            (area['lng'] as num).toDouble(),
          )
        : _malabeDefault;

    final rawStops =
        (_currentRoute['routeStops'] as List?) ?? (_currentRoute['stops'] as List?) ?? [];

    final stops = rawStops.whereType<Map>().map((s) => Map<String, dynamic>.from(s)).toList();
    stops.sort((a, b) {
      final aSeq = (a['sequenceOrder'] is num) ? (a['sequenceOrder'] as num).toInt() : 0;
      final bSeq = (b['sequenceOrder'] is num) ? (b['sequenceOrder'] as num).toInt() : 0;
      return aSeq.compareTo(bSeq);
    });

    final polylinePoints = <LatLng>[];
    final markers = <Marker>[];

    // Center zone marker
    markers.add(
      Marker(
        point: center,
        width: 44,
        height: 44,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0097A7).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFF0097A7), width: 2),
          ),
          child: const Icon(Icons.hub, color: Color(0xFF0097A7), size: 24),
        ),
      ),
    );

    for (int i = 0; i < stops.length; i++) {
      final stop = stops[i];
      final loc = stop['location'];
      if (loc is Map && loc['lat'] is num && loc['lng'] is num) {
        final point = LatLng(
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        );
        polylinePoints.add(point);

        final reqId = stop['collectionRequestId'];
        final isSpecial = reqId != null && reqId.toString().isNotEmpty;
        final stopStatus = (stop['status']?.toString() ?? 'pending').toLowerCase();
        final isCollected = stopStatus == 'collected';

        final baseColor = isCollected
            ? const Color(0xFF15803D)
            : (isSpecial
                ? const Color(0xFFE65100)
                : (i == 0 ? const Color(0xFF2E7D32) : const Color(0xFF0097A7)));

        markers.add(
          Marker(
            point: point,
            width: 46,
            height: 46,
            child: Tooltip(
              message: '${i + 1}. ${isSpecial ? '⭐ [Special Request] ' : '🏢 [Regular Stop] '}${stop['address'] ?? 'Stop'} (${isCollected ? 'Collected' : 'Pending'})',
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    isSpecial ? Icons.stars_rounded : Icons.location_on,
                    color: baseColor,
                    size: isSpecial ? 42 : 40,
                  ),
                  Positioned(
                    top: isSpecial ? 12 : 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 2)],
                      ),
                      child: Text(
                        isCollected ? '✓' : '${i + 1}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: baseColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }

    final driver = _currentRoute['assignedDriver'];
    final driverName = driver is Map ? driver['name']?.toString() ?? 'Unassigned' : 'Unassigned';
    final status = _currentRoute['status']?.toString() ?? 'Active';

    final targetWasteType = _currentRoute['targetWasteType']?.toString() ?? 'weekly_schedule';
    final weeklySchedule = _currentRoute['weeklyCategorySchedule'] as List? ?? const [];
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

    final bool isSpecialDay = todayCategory == 'special_requests' ||
        todayName == 'Tuesday' ||
        todayName == 'Thursday';

    final displayedStopsWithIndex = <MapEntry<int, Map<String, dynamic>>>[];
    for (int i = 0; i < stops.length; i++) {
      final s = stops[i];
      final isSpecial = s['collectionRequestId'] != null &&
          s['collectionRequestId'].toString().isNotEmpty;
      if (isSpecialDay && !isSpecial) continue;
      displayedStopsWithIndex.add(MapEntry(i, s));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_currentRoute['routeName']?.toString() ?? 'Route Map'),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isOptimizing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            tooltip: 'Auto-Optimize Sequence (Shortest Path)',
            onPressed: _isOptimizing ? null : _optimizeSequence,
          ),
          IconButton(
            icon: const Icon(Icons.add_location_alt_outlined),
            tooltip: 'Add Stop',
            onPressed: () => _showAddStopDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit Route Details',
            onPressed: _openEditRoute,
          ),
          IconButton(
            icon: Icon(_showStopList ? Icons.map : Icons.format_list_numbered),
            tooltip: _showStopList ? 'View Map' : 'View Stop List & Sequence',
            onPressed: () => setState(() => _showStopList = !_showStopList),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: polylinePoints.isNotEmpty ? polylinePoints.first : center,
              initialZoom: 13.5,
              onTap: (tapPosition, point) => _showAddStopDialog(initialPos: point),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecotrack.app',
              ),
              if (polylinePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: polylinePoints,
                      color: const Color(0xFF0097A7),
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
            ],
          ),

          // Tap map prompt
          Positioned(
            top: 10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.touch_app, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Tap map to add stop', style: TextStyle(color: Colors.white, fontSize: 11)),
                ],
              ),
            ),
          ),

          // Map Legend
          Positioned(
            top: 10,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🏢 Bin', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(width: 6),
                  Text('⭐ Special', style: TextStyle(color: Color(0xFFFFB74D), fontSize: 10, fontWeight: FontWeight.bold)),
                  SizedBox(width: 6),
                  Text('✓ Done', style: TextStyle(color: Color(0xFF81C784), fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),

          // Sliding Stop List Tray if toggled
          if (_showStopList)
            Positioned(
              top: 45,
              left: 12,
              right: 12,
              bottom: 140,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isSpecialDay
                                ? 'Stops Sequence (${displayedStopsWithIndex.length} Special Pickups)'
                                : 'Stops Sequence (${stops.length})',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Row(
                            children: [
                              TextButton.icon(
                                onPressed: _isOptimizing ? null : _optimizeSequence,
                                icon: const Icon(Icons.auto_awesome, size: 15),
                                label: const Text('Auto-Optimize', style: TextStyle(fontSize: 11)),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF00838F),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, size: 20),
                                onPressed: () => setState(() => _showStopList = false),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Collection Progress Indicator
                      () {
                        final total = displayedStopsWithIndex.length;
                        final collected = displayedStopsWithIndex.where((e) => (e.value['status']?.toString() ?? '').toLowerCase() == 'collected').length;
                        final specialCount = stops.where((s) => s['collectionRequestId'] != null && s['collectionRequestId'].toString().isNotEmpty).length;
                        final regularCount = stops.length - specialCount;
                        final specialColl = stops.where((s) => s['collectionRequestId'] != null && s['collectionRequestId'].toString().isNotEmpty && (s['status']?.toString() ?? '').toLowerCase() == 'collected').length;
                        final regColl = stops.where((s) => (s['collectionRequestId'] == null || s['collectionRequestId'].toString().isEmpty) && (s['status']?.toString() ?? '').toLowerCase() == 'collected').length;
                        final pct = total > 0 ? ((collected / total) * 100).toInt() : 0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
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
                                        ? 'Special Requests: $collected / $total Pickups'
                                        : 'Today\'s Collection: $collected / $total Stops',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    '$pct%',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF00838F), fontSize: 12),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: total > 0 ? (collected / total) : 0.0,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0097A7)),
                                  minHeight: 5,
                                ),
                              ),
                              const SizedBox(height: 5),
                              if (isSpecialDay)
                                const Row(
                                  children: [
                                    Icon(Icons.stars_rounded, size: 14, color: Color(0xFF00796B)),
                                    SizedBox(width: 4),
                                    Text(
                                      '⭐ Dedicated on-demand resident pickups only for today',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: Color(0xFF00796B),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                )
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('🏢 Regular Bins: $regColl/$regularCount', style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700)),
                                    Text('⭐ Special Requests: $specialColl/$specialCount', style: const TextStyle(fontSize: 10.5, color: Color(0xFF00796B), fontWeight: FontWeight.bold)),
                                  ],
                                ),
                            ],
                          ),
                        );
                      }(),
                      const Divider(height: 1),
                      Expanded(
                        child: displayedStopsWithIndex.isEmpty
                            ? Center(
                                child: Text(
                                  isSpecialDay
                                      ? 'No special request pickups scheduled on this route.'
                                      : 'No stops recorded on this route yet.\nTap "Add Stop" to add one.',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: displayedStopsWithIndex.length,
                                itemBuilder: (ctx, idx) {
                                  final entry = displayedStopsWithIndex[idx];
                                  final originalIdx = entry.key;
                                  final s = entry.value;
                                  final loc = s['location'] as Map?;
                                  final lat = loc?['lat'];
                                  final lng = loc?['lng'];
                                  final isSpecial = s['collectionRequestId'] != null && s['collectionRequestId'].toString().isNotEmpty;
                                  final stopStatus = (s['status']?.toString() ?? 'pending').toLowerCase();
                                  final isColl = stopStatus == 'collected';

                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: isColl ? const Color(0xFFF0FDF4) : Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: isColl ? const Color(0xFFBBF7D0) : Colors.grey.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 12,
                                              backgroundColor: isColl
                                                  ? const Color(0xFF15803D)
                                                  : const Color(0xFF0097A7),
                                              foregroundColor: Colors.white,
                                              child: Text(
                                                isColl ? '✓' : '${idx + 1}',
                                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                s['address']?.toString() ?? 'Stop ${idx + 1}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                  decoration: isColl ? TextDecoration.lineThrough : null,
                                                ),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isSpecial ? const Color(0xFFE0F7FA) : Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: isSpecial ? const Color(0xFF80DEEA) : Colors.grey.shade300,
                                                ),
                                              ),
                                              child: Text(
                                                isSpecial ? '⭐ Special' : '🏢 Regular',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: isSpecial ? const Color(0xFF00838F) : Colors.grey.shade700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (lat != null && lng != null) ...[
                                          const SizedBox(height: 3),
                                          Padding(
                                            padding: const EdgeInsets.only(left: 32),
                                            child: Text(
                                              'Coord: ${(lat as num).toStringAsFixed(5)}, ${(lng as num).toStringAsFixed(5)}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              onTap: () => _updateStopStatus(originalIdx, isColl ? 'pending' : 'collected'),
                                              borderRadius: BorderRadius.circular(6),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                                decoration: BoxDecoration(
                                                  color: isColl ? const Color(0xFFDCFCE7) : Colors.grey.shade100,
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: isColl ? const Color(0xFF86EFAC) : Colors.grey.shade300,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      isColl ? Icons.check_circle : Icons.radio_button_unchecked,
                                                      size: 13,
                                                      color: isColl ? const Color(0xFF15803D) : Colors.grey.shade700,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      isColl ? 'Collected ✓' : 'Mark Done',
                                                      style: TextStyle(
                                                        fontSize: 10.5,
                                                        fontWeight: FontWeight.bold,
                                                        color: isColl ? const Color(0xFF15803D) : Colors.grey.shade800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.arrow_upward, size: 16),
                                                  color: originalIdx > 0 ? const Color(0xFF0097A7) : Colors.grey.shade300,
                                                  tooltip: 'Move Up',
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                  onPressed: originalIdx > 0 ? () => _moveStopUp(originalIdx, stops) : null,
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.arrow_downward, size: 16),
                                                  color: originalIdx < stops.length - 1
                                                      ? const Color(0xFF0097A7)
                                                      : Colors.grey.shade300,
                                                  tooltip: 'Move Down',
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                  onPressed: originalIdx < stops.length - 1
                                                      ? () => _moveStopDown(originalIdx, stops)
                                                      : null,
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                                  tooltip: 'Remove Stop',
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                                                  onPressed: () => _confirmRemoveStop(s, originalIdx),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Bottom Route Summary Card
          Positioned(
            left: 12,
            right: 12,
            bottom: 16,
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _currentRoute['routeName']?.toString() ?? 'Route',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0097A7).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(
                              color: Color(0xFF0097A7),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_city, size: 15, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Zone: ${_currentRoute['zone'] ?? 'Malabe'}',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.alt_route, size: 15, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          isSpecialDay
                              ? '${displayedStopsWithIndex.length} Special Pickups'
                              : '${stops.length} Sequenced Stops',
                          style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 15, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          'Driver: $driverName',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.recycling, size: 15, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 4),
                        Text(
                          'Today: ${_formatCategoryName(todayCategory)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2E7D32)),
                        ),
                        if (isWeekly) ...[
                          const SizedBox(width: 8),
                          Text(
                            '• Weekly rotation',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _showAddStopDialog(),
                            icon: const Icon(Icons.add_location_alt_outlined, size: 15),
                            label: const Text('Add Stop'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF0097A7),
                              side: const BorderSide(color: Color(0xFF0097A7)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _openEditRoute,
                            icon: const Icon(Icons.edit_outlined, size: 15),
                            label: const Text('Edit Route'),
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
            ),
          ),
        ],
      ),
    );
  }

  String _formatCategoryName(String cat) {
    switch (cat.toLowerCase()) {
      case 'organic':
        return '🥬 Organic';
      case 'plastic_paper':
      case 'plastic':
      case 'paper':
        return '🧴📦 Plastic & Paper';
      case 'glass_others':
      case 'glass_metal':
      case 'glass':
      case 'other':
        return '🍾 Glass & Others';
      case 'all':
        return '♻️ All 3 Categories';
      case 'special_requests':
        return '⭐ Special Requests (All Day)';
      default:
        return '🗑️ $cat';
    }
  }
}
