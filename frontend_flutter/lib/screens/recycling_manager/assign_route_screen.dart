import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/manager_provider.dart';

class _WaypointItem {
  final String id;
  String name;
  final LatLng position;
  final String? collectionRequestId;

  _WaypointItem({
    required this.id,
    required this.name,
    required this.position,
    this.collectionRequestId,
  });
}

class AssignRouteScreen extends StatefulWidget {
  final Map<String, dynamic>? initialRoute;

  const AssignRouteScreen({super.key, this.initialRoute});

  @override
  State<AssignRouteScreen> createState() => _AssignRouteScreenState();
}

class _AssignRouteScreenState extends State<AssignRouteScreen> {
  // Malabe central coordinates (Sri Lanka: near SLIIT / Horizon campus, Kaduwela Road)
  static const LatLng _malabeCenter = LatLng(6.9061, 79.9696);

  final MapController _mapController = MapController();
  late final TextEditingController _routeNameController;
  late final TextEditingController _zoneController;
  late final TextEditingController _descriptionController;

  final List<_WaypointItem> _waypoints = [];
  final List<String> _selectedOperatingDays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  String _targetWasteType = 'weekly_schedule';
  final Map<String, String> _weeklyCategoryMap = {
    'Monday': 'organic',
    'Tuesday': 'special_requests',
    'Wednesday': 'plastic_paper',
    'Thursday': 'special_requests',
    'Friday': 'glass_others',
    'Saturday': 'special_requests',
    'Sunday': 'glass_others',
  };

  DateTime _selectedDate = DateTime.now();
  String? _selectedDriverId;
  bool _isSubmitting = false;

  bool get isEditing => widget.initialRoute != null;

  // Key presets around Malabe for quick additions
  final List<Map<String, dynamic>> _malabePresets = [
    {
      'name': 'SLIIT Campus (New Kandy Rd)',
      'pos': const LatLng(6.9147, 79.9733),
    },
    {
      'name': 'Horizon Campus / Knowledge City',
      'pos': const LatLng(6.9110, 79.9805),
    },
    {
      'name': 'Kaduwela Rd - Pittugala Stop',
      'pos': const LatLng(6.9090, 79.9660),
    },
    {
      'name': 'Malabe Junction (Kaduwela Rd)',
      'pos': const LatLng(6.9042, 79.9572),
    },
    {
      'name': 'Chandrika Kumaratunga Mawatha',
      'pos': const LatLng(6.9015, 79.9720),
    },
    {
      'name': 'Kothalawala Interchange (Kaduwela Rd)',
      'pos': const LatLng(6.9205, 79.9790),
    },
  ];

  @override
  void initState() {
    super.initState();

    if (isEditing) {
      final r = widget.initialRoute!;
      _routeNameController = TextEditingController(text: r['routeName']?.toString() ?? '');
      _zoneController = TextEditingController(text: r['zone']?.toString() ?? 'Malabe');
      _descriptionController = TextEditingController(text: r['description']?.toString() ?? '');

      if (r['operatingDays'] is List) {
        _selectedOperatingDays.clear();
        _selectedOperatingDays.addAll((r['operatingDays'] as List).map((e) => e.toString()));
      }

      if (r['targetWasteType'] != null && r['targetWasteType'].toString().isNotEmpty) {
        String t = r['targetWasteType'].toString();
        if (t == 'plastic' || t == 'paper') t = 'plastic_paper';
        if (t == 'glass_metal' || t == 'glass' || t == 'other') t = 'glass_others';
        _targetWasteType = t;
      }

      if (r['weeklyCategorySchedule'] is List) {
        for (final item in (r['weeklyCategorySchedule'] as List)) {
          if (item is Map && item['day'] != null && item['category'] != null) {
            final dayStr = item['day'].toString();
            String c = item['category'].toString();
            if (c == 'plastic' || c == 'paper') c = 'plastic_paper';
            if (c == 'glass_metal' || c == 'glass' || c == 'other') c = 'glass_others';
            // Migrate legacy Tuesday/Thursday plastic_paper, Wednesday organic, Friday organic
            if ((dayStr == 'Tuesday' || dayStr == 'Thursday') && (c == 'plastic_paper' || c == 'plastic' || c == 'paper')) {
              c = 'special_requests';
            } else if (dayStr == 'Wednesday' && c == 'organic') {
              c = 'plastic_paper';
            } else if (dayStr == 'Friday' && c == 'organic') {
              c = 'glass_others';
            }
            _weeklyCategoryMap[dayStr] = c;
          }
        }
      }

      if (r['date'] != null) {
        final d = DateTime.tryParse(r['date'].toString());
        if (d != null) _selectedDate = d;
      }

      final drv = r['assignedDriver'];
      _selectedDriverId = drv is Map
          ? (drv['_id']?.toString() ?? drv['driverId']?.toString())
          : drv?.toString();

      final rawStops = (r['routeStops'] as List?) ?? (r['stops'] as List?) ?? [];
      for (int i = 0; i < rawStops.length; i++) {
        final s = rawStops[i];
        if (s is Map && s['location'] is Map) {
          final lat = s['location']['lat'];
          final lng = s['location']['lng'];
          if (lat is num && lng is num) {
            final reqId = s['collectionRequestId'] is Map
                ? s['collectionRequestId']['_id']?.toString()
                : s['collectionRequestId']?.toString();
            _waypoints.add(_WaypointItem(
              id: s['_id']?.toString() ?? 'wp_${i + 1}',
              name: s['address']?.toString() ?? 'Stop ${i + 1}',
              position: LatLng(lat.toDouble(), lng.toDouble()),
              collectionRequestId: reqId,
            ));
          }
        }
      }
    } else {
      _routeNameController = TextEditingController(text: 'Malabe Campus & Kaduwela Rd Loop');
      _zoneController = TextEditingController(text: 'Malabe');
      _descriptionController = TextEditingController(text: 'Waste & recycling collection around SLIIT, Horizon campus and Kaduwela Road');

      // Default with top 3 Malabe waypoints
      _waypoints.add(_WaypointItem(
        id: 'wp_1',
        name: 'SLIIT Campus (New Kandy Rd)',
        position: const LatLng(6.9147, 79.9733),
      ));
      _waypoints.add(_WaypointItem(
        id: 'wp_2',
        name: 'Horizon Campus / Knowledge City',
        position: const LatLng(6.9110, 79.9805),
      ));
      _waypoints.add(_WaypointItem(
        id: 'wp_3',
        name: 'Malabe Junction (Kaduwela Rd)',
        position: const LatLng(6.9042, 79.9572),
      ));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagerProvider>();
      provider.fetchAvailableDrivers();
    });
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _zoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _addPresetWaypoint(Map<String, dynamic> preset) {
    final String name = preset['name'];
    final LatLng pos = preset['pos'];

    // Avoid duplicate preset clicks if same position
    final exists = _waypoints.any(
      (w) => (w.position.latitude - pos.latitude).abs() < 0.0001 &&
             (w.position.longitude - pos.longitude).abs() < 0.0001,
    );

    if (exists) {
      _showMessage('Waypoint already exists on this route');
      return;
    }

    setState(() {
      _waypoints.add(_WaypointItem(
        id: 'wp_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        position: pos,
      ));
    });

    _mapController.move(pos, 14.0);
  }

  void _onMapTap(TapPosition tapPos, LatLng point) {
    final int nextIndex = _waypoints.length + 1;
    final String stopName = 'Stop #$nextIndex (Malabe - ${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})';

    setState(() {
      _waypoints.add(_WaypointItem(
        id: 'wp_${DateTime.now().millisecondsSinceEpoch}',
        name: stopName,
        position: point,
      ));
    });

    _showMessage('Added waypoint #$nextIndex at selected location');
  }

  void _moveWaypointUp(int index) {
    if (index > 0) {
      setState(() {
        final item = _waypoints.removeAt(index);
        _waypoints.insert(index - 1, item);
      });
    }
  }

  void _moveWaypointDown(int index) {
    if (index < _waypoints.length - 1) {
      setState(() {
        final item = _waypoints.removeAt(index);
        _waypoints.insert(index + 1, item);
      });
    }
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
    });
  }

  Future<void> _submit() async {
    final provider = context.read<ManagerProvider>();
    final routeName = _routeNameController.text.trim();
    final zone = _zoneController.text.trim();

    if (routeName.isEmpty || zone.isEmpty) {
      _showMessage('Route name and zone are required');
      return;
    }

    if (_waypoints.isEmpty) {
      _showMessage('Please add at least one waypoint on the map');
      return;
    }

    setState(() => _isSubmitting = true);

    // Format waypoint array with sequence order and coordinate objects
    final routeStops = _waypoints.asMap().entries.map((entry) {
      final int idx = entry.key;
      final _WaypointItem wp = entry.value;
      return {
        if (wp.collectionRequestId != null) 'collectionRequestId': wp.collectionRequestId,
        'location': {
          'lat': wp.position.latitude,
          'lng': wp.position.longitude,
        },
        'address': wp.name,
        'sequenceOrder': idx + 1,
        'status': 'pending',
      };
    }).toList();

    final weeklyScheduleList = _selectedOperatingDays.map((d) {
      return {
        'day': d,
        'category': _weeklyCategoryMap[d] ?? 'organic',
      };
    }).toList();

    if (isEditing) {
      final String existingId = widget.initialRoute!['_id'].toString();
      final ok = await provider.updateRoute(
        routeId: existingId,
        routeName: routeName,
        zone: zone,
        date: _selectedDate,
        description: _descriptionController.text.trim(),
        assignedDriver: _selectedDriverId,
        operatingDays: _selectedOperatingDays,
        targetWasteType: _targetWasteType,
        weeklyCategorySchedule: weeklyScheduleList,
        routeStops: routeStops,
        areaCoordinates: {
          'lat': _waypoints.first.position.latitude,
          'lng': _waypoints.first.position.longitude,
        },
      );

      if (ok) {
        await provider.fetchRoutes();
        await provider.fetchAvailableDrivers();
        await provider.fetchDashboardStats();

        if (mounted) {
          _showMessage('Route updated with ${_waypoints.length} stops successfully!');
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        _showMessage(provider.error ?? 'Unable to update route');
      }
    } else {
      final routeId = await provider.createRoute(
        routeName: routeName,
        zone: zone,
        date: _selectedDate,
        description: _descriptionController.text.trim(),
        assignedDriver: _selectedDriverId,
        operatingDays: _selectedOperatingDays,
        targetWasteType: _targetWasteType,
        weeklyCategorySchedule: weeklyScheduleList,
        routeStops: routeStops,
        areaCoordinates: {
          'lat': _waypoints.first.position.latitude,
          'lng': _waypoints.first.position.longitude,
        },
      );

      if (routeId != null) {
        await provider.fetchRoutes();
        await provider.fetchAvailableDrivers();
        await provider.fetchDashboardStats();

        if (mounted) {
          _showMessage('Route created with ${_waypoints.length} waypoints successfully!');
          Navigator.pop(context, true);
        }
      } else if (mounted) {
        _showMessage(provider.error ?? 'Unable to create route');
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ManagerProvider>();

    // Build polyline from waypoints sequence
    final polylinePoints = _waypoints.map((w) => w.position).toList();

    // Build numbered markers for waypoints
    final markers = <Marker>[];
    for (int i = 0; i < _waypoints.length; i++) {
      final wp = _waypoints[i];
      final isFirst = i == 0;
      final isLast = i == _waypoints.length - 1 && _waypoints.length > 1;

      markers.add(
        Marker(
          point: wp.position,
          width: 44,
          height: 44,
          child: Tooltip(
            message: '${i + 1}. ${wp.name}',
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  Icons.location_on,
                  color: isFirst
                      ? const Color(0xFF2E7D32)
                      : (isLast ? Colors.deepOrange : const Color(0xFF0097A7)),
                  size: 42,
                ),
                Positioned(
                  top: 8,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isFirst
                            ? const Color(0xFF2E7D32)
                            : (isLast ? Colors.deepOrange : const Color(0xFF0097A7)),
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

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Route & Waypoints' : 'Create Route & Waypoints',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await provider.fetchAvailableDrivers();
          await provider.fetchCollectionRequests(refresh: true);
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Target Location banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0097A7).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF0097A7).withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.location_city, color: Color(0xFF0097A7), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Target: Malabe Area (Sri Lanka)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Around SLIIT, Horizon Campus & Kaduwela Road. Tap on map to add custom stops.',
                          style: TextStyle(fontSize: 11, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Map Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Presets horizontal bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: Colors.white,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Quick Add Malabe Waypoints:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 6),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _malabePresets.map((preset) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ActionChip(
                                  avatar: const Icon(Icons.add_location, size: 14, color: Color(0xFF0097A7)),
                                  label: Text(preset['name'] as String, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: const Color(0xFFF1F8F8),
                                  side: BorderSide(color: Colors.grey.shade300),
                                  onPressed: () => _addPresetWaypoint(preset),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // The Interactive Map
                  SizedBox(
                    height: 280,
                    child: Stack(
                      children: [
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _malabeCenter,
                            initialZoom: 13.5,
                            onTap: _onMapTap,
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
                        Positioned(
                          top: 10,
                          right: 10,
                          child: FloatingActionButton.small(
                            heroTag: 'recenter_map',
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0097A7),
                            tooltip: 'Center Malabe',
                            onPressed: () => _mapController.move(_malabeCenter, 14.0),
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                        Positioned(
                          bottom: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${_waypoints.length} stops sequenced',
                              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Collapsible Waypoints Sequence Card
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              clipBehavior: Clip.antiAlias,
              child: ExpansionTile(
                initiallyExpanded: false,
                tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: const Color(0xFF0097A7).withValues(alpha: 0.12),
                  child: const Icon(Icons.format_list_numbered, color: Color(0xFF0097A7), size: 18),
                ),
                title: Text(
                  'Route Stops Sequence (${_waypoints.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  _waypoints.isEmpty
                      ? 'Tap map to add stops'
                      : 'Tap to view / reorder sequenced stops',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  if (_waypoints.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _waypoints.clear()),
                          icon: const Icon(Icons.clear_all, size: 16, color: Colors.red),
                          label: const Text('Clear All Stops', style: TextStyle(color: Colors.red, fontSize: 12)),
                        ),
                      ],
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _waypoints.length,
                        itemBuilder: (context, index) {
                          final wp = _waypoints[index];
                          return Card(
                            elevation: 0,
                            margin: const EdgeInsets.only(bottom: 6),
                            color: const Color(0xFFF9FAFB),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 12,
                                    backgroundColor: const Color(0xFF0097A7),
                                    foregroundColor: Colors.white,
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          wp.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${wp.position.latitude.toStringAsFixed(4)}, ${wp.position.longitude.toStringAsFixed(4)}',
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_upward, size: 16),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Move up',
                                    onPressed: index > 0 ? () => _moveWaypointUp(index) : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_downward, size: 16),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Move down',
                                    onPressed: index < _waypoints.length - 1 ? () => _moveWaypointDown(index) : null,
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                                    visualDensity: VisualDensity.compact,
                                    tooltip: 'Remove stop',
                                    onPressed: () => _removeWaypoint(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'No stops added yet. Tap on the Malabe map or choose a preset above.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),

            // Route Configuration Details
            const Text(
              'Route Configuration',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 12),

            _label('Route Name'),
            _field(_routeNameController, 'e.g. Malabe Campus Loop'),
            const SizedBox(height: 12),

            _label('Area / Zone'),
            _field(_zoneController, 'e.g. Malabe'),
            const SizedBox(height: 12),

            _label('Description'),
            _field(
              _descriptionController,
              'Regular collection route description',
              maxLines: 2,
            ),
            const SizedBox(height: 12),

            _label('Assign Driver'),
            DropdownButtonFormField<String>(
              initialValue: _selectedDriverId,
              decoration: _decoration(Icons.local_shipping, 'Choose a driver'),
              items: provider.availableDrivers.map((driver) {
                final id = driver['driverId']?.toString() ?? driver['_id']?.toString();
                if (id == null) return null;
                final name = driver['name']?.toString() ?? 'Driver';
                final isAvailable = driver['availability'] == 'available';
                return DropdownMenuItem<String>(
                  value: id,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name),
                      const SizedBox(width: 8),
                      Text(
                        isAvailable ? 'Available' : 'Busy',
                        style: TextStyle(
                          fontSize: 10,
                          color: isAvailable ? Colors.green : Colors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }).whereType<DropdownMenuItem<String>>().toList(),
              onChanged: (value) => setState(() => _selectedDriverId = value),
            ),
            const SizedBox(height: 12),

            _label('Operating Days'),
            Wrap(
              spacing: 6,
              children: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((day) {
                final isSelected = _selectedOperatingDays.contains(day);
                return FilterChip(
                  label: Text(day.substring(0, 3)),
                  selected: isSelected,
                  selectedColor: const Color(0xFF0097A7).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFF0097A7),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedOperatingDays.add(day);
                      } else {
                        _selectedOperatingDays.remove(day);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Target Waste Category / Mode
            _label('Target Waste Category / Mode'),
            DropdownButtonFormField<String>(
              initialValue: _targetWasteType,
              decoration: _decoration(Icons.recycling_outlined, 'Select category mode'),
              items: const [
                DropdownMenuItem(
                  value: 'weekly_schedule',
                  child: Text('🗓️ Weekly Schedule (Day-wise rotation)'),
                ),
                DropdownMenuItem(
                  value: 'organic',
                  child: Text('🥬 Organic Waste Only (දිරන කසළ)'),
                ),
                DropdownMenuItem(
                  value: 'plastic_paper',
                  child: Text('🧴📦 Plastic & Paper Only (ප්ලාස්ටික් සහ කඩදාසි)'),
                ),
                DropdownMenuItem(
                  value: 'glass_others',
                  child: Text('🍾 Glass & Others Only (වීදුරු සහ අනෙකුත් ද්‍රව්‍ය)'),
                ),
                DropdownMenuItem(
                  value: 'all',
                  child: Text('♻️ All 3 Categories (සියලු වර්ග)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _targetWasteType = val);
              },
            ),
            const SizedBox(height: 12),

            // Day-wise category mapper if weekly schedule is selected
            if (_targetWasteType == 'weekly_schedule') ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF86EFAC)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.calendar_month, size: 18, color: Color(0xFF15803D)),
                            SizedBox(width: 6),
                            Text(
                              'Weekly Waste Coordination Schedule',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          onPressed: () {
                            setState(() {
                              _weeklyCategoryMap['Monday'] = 'organic';
                              _weeklyCategoryMap['Tuesday'] = 'special_requests';
                              _weeklyCategoryMap['Wednesday'] = 'plastic_paper';
                              _weeklyCategoryMap['Thursday'] = 'special_requests';
                              _weeklyCategoryMap['Friday'] = 'glass_others';
                              _weeklyCategoryMap['Saturday'] = 'special_requests';
                              _weeklyCategoryMap['Sunday'] = 'glass_others';
                            });
                          },
                          child: const Text(
                            'Apply Standard',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFBBF7D0)),
                      ),
                      child: const Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.info_outline, size: 15, color: Color(0xFF15803D)),
                          SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '• Mon, Wed, Fri: Default municipal route + Special Requests in remaining shift time.\n• Tue, Thu: Dedicated all day for Special Requests collection.',
                              style: TextStyle(fontSize: 11, color: Color(0xFF166534), height: 1.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (_selectedOperatingDays.isEmpty)
                      const Text(
                        'Select operating days above to assign collection categories.',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      )
                    else
                      ..._selectedOperatingDays.map((day) {
                        final currentCat = _weeklyCategoryMap[day] ?? 'organic';
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 95,
                                child: Text(
                                  day,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: currentCat,
                                  isDense: true,
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    fillColor: Colors.white,
                                    filled: true,
                                    isDense: true,
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'organic',
                                      child: Text('🥬 Organic (දිරන)', style: TextStyle(fontSize: 13)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'plastic_paper',
                                      child: Text('🧴📦 Plastic & Paper (ප්ලාස්ටික් / කඩදාසි)', style: TextStyle(fontSize: 13)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'glass_others',
                                      child: Text('🍾 Glass & Others (වීදුරු / වෙනත්)', style: TextStyle(fontSize: 13)),
                                    ),
                                    DropdownMenuItem(
                                      value: 'special_requests',
                                      child: Text('⭐ Special Requests Only (විශේෂ ඉල්ලීම්)', style: TextStyle(fontSize: 13)),
                                    ),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) {
                                      setState(() {
                                        _weeklyCategoryMap[day] = val;
                                      });
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0097A7),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSubmitting
                      ? 'Saving Route...'
                      : (isEditing
                          ? 'Save Route Changes (${_waypoints.length} Stops)'
                          : 'Save & Assign Route (${_waypoints.length} Waypoints)'),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );

  Widget _field(
    TextEditingController controller,
    String hint, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _decoration(null, hint),
    );
  }

  InputDecoration _decoration(IconData? icon, String hint) => InputDecoration(
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: const Color(0xFF0097A7)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      );
}
