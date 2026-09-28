import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../models/user_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/manager_service.dart';
import '../../../services/profile_service.dart';
import '../../community/request_collection_screen.dart';
import '../../profile/map_picker_screen.dart';

/// Interactive Home tab section displaying the user's assigned municipal
/// waste collection route, collection points, and schedule awareness.
class HomeRouteMapSection extends StatefulWidget {
  final VoidCallback? onGoToRequests;

  const HomeRouteMapSection({super.key, this.onGoToRequests});

  @override
  State<HomeRouteMapSection> createState() => _HomeRouteMapSectionState();
}

class _HomeRouteMapSectionState extends State<HomeRouteMapSection> {
  final ManagerService _managerService = ManagerService();
  final ProfileService _profileService = ProfileService();
  final MapController _mapController = MapController();
  final Distance _distance = const Distance();

  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _assignedRoute;
  Map<String, dynamic>? _closestStop;
  double? _distanceToClosestStop;
  Map<String, String>? _nextCollectionInfo;
  bool _isOutOfCoverage = false;
  Map<String, dynamic>? _selectedStop;

  @override
  void initState() {
    super.initState();
    _loadScheduleAndMatch();
  }

  Future<void> _loadScheduleAndMatch() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
      _selectedStop = null;
    });

    try {
      final user = context.read<AuthProvider>().user;
      final scheduleRes = await _managerService.getPublicRouteSchedule();
      final rawRoutes = (scheduleRes['routes'] as List?)
              ?.whereType<Map>()
              .map((r) => Map<String, dynamic>.from(r))
              .toList() ??
          [];

      _matchUserToRoute(user, rawRoutes);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _matchUserToRoute(UserModel? user, List<Map<String, dynamic>> routes) {
    if (user == null || user.locationCoordinates?.lat == null || user.locationCoordinates?.lng == null) {
      _assignedRoute = null;
      _isOutOfCoverage = false;
      _nextCollectionInfo = null;
      return;
    }

    final userPoint = LatLng(user.locationCoordinates!.lat!, user.locationCoordinates!.lng!);

    Map<String, dynamic>? bestRoute;
    Map<String, dynamic>? bestStop;
    double minDistance = double.infinity;

    for (final route in routes) {
      final stops = ((route['routeStops'] as List?) ?? (route['stops'] as List?) ?? [])
          .whereType<Map>()
          .map((s) => Map<String, dynamic>.from(s))
          .toList();

      for (final stop in stops) {
        final loc = stop['location'] as Map<String, dynamic>? ?? {};
        final lat = (loc['lat'] ?? stop['lat']) as num?;
        final lng = (loc['lng'] ?? stop['lng']) as num?;

        if (lat != null && lng != null) {
          final stopPoint = LatLng(lat.toDouble(), lng.toDouble());
          final d = _distance.as(LengthUnit.Meter, userPoint, stopPoint);
          if (d < minDistance) {
            minDistance = d;
            bestRoute = route;
            bestStop = stop;
          }
        }
      }

      // Also check area centroid coordinates if available
      final areaCoords = route['areaCoordinates'] as Map<String, dynamic>?;
      if (areaCoords != null && areaCoords['lat'] != null && areaCoords['lng'] != null) {
        final areaPoint = LatLng((areaCoords['lat'] as num).toDouble(), (areaCoords['lng'] as num).toDouble());
        final d = _distance.as(LengthUnit.Meter, userPoint, areaPoint);
        if (d < minDistance) {
          minDistance = d;
          bestRoute = route;
        }
      }
    }

    // Proximity coverage threshold: 3.5 km (3500 meters)
    if (bestRoute != null && minDistance <= 3500) {
      _assignedRoute = bestRoute;
      _closestStop = bestStop;
      _distanceToClosestStop = minDistance;
      _isOutOfCoverage = false;

      final operatesToday = bestRoute['operatesToday'] == true;
      if (!operatesToday) {
        _nextCollectionInfo = _calculateNextCollection(bestRoute);
      } else {
        _nextCollectionInfo = null;
      }
    } else {
      _assignedRoute = null;
      _closestStop = null;
      _distanceToClosestStop = null;
      _isOutOfCoverage = true;
      _nextCollectionInfo = null;
    }
  }

  Map<String, String>? _calculateNextCollection(Map<String, dynamic> route) {
    final operatingDays = (route['operatingDays'] as List?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    if (operatingDays.isEmpty) return null;

    const daysOfWeek = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];

    final now = DateTime.now();
    final currentDayIndex = now.weekday - 1;

    for (int offset = 1; offset <= 7; offset++) {
      final nextIndex = (currentDayIndex + offset) % 7;
      final nextDayName = daysOfWeek[nextIndex];
      if (operatingDays.contains(nextDayName)) {
        final targetDate = now.add(Duration(days: offset));
        final dateFormatted = DateFormat('EEEE, MMM d').format(targetDate);

        String category = 'organic';
        final weeklySchedule = (route['weeklyCategorySchedule'] as List?) ?? [];
        for (final item in weeklySchedule) {
          if (item is Map && item['day']?.toString() == nextDayName) {
            category = item['category']?.toString() ?? 'organic';
            break;
          }
        }

        return {
          'day': nextDayName,
          'date': dateFormatted,
          'category': category,
          'isTomorrow': offset == 1 ? 'true' : 'false',
        };
      }
    }
    return null;
  }

  String _formatCategory(String? cat) {
    switch (cat) {
      case 'organic':
        return '🥬 Organic Waste';
      case 'plastic_paper':
        return '🧴📦 Plastic & Paper';
      case 'glass_others':
        return '🍾 Glass & Recyclables';
      case 'special_requests':
        return '⭐ Special Requests Day';
      default:
        return '♻️ Waste Collection';
    }
  }

  Future<void> _openLocationPicker(UserModel user) async {
    final curLat = user.locationCoordinates?.lat;
    final curLng = user.locationCoordinates?.lng;

    final picked = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: curLat,
          initialLng: curLng,
        ),
      ),
    );

    if (picked != null && mounted) {
      try {
        await _profileService.updateProfile(
          locationCoordinates: {
            'lat': picked.latitude,
            'lng': picked.longitude,
          },
        );
        if (!mounted) return;
        await context.read<AuthProvider>().checkAuthentication();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location updated successfully! Updating route schedule...'),
              backgroundColor: Color(0xFF2E7D32),
            ),
          );
          _loadScheduleAndMatch();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save location: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final hasCoords = user?.locationCoordinates?.lat != null && user?.locationCoordinates?.lng != null;
    final isRestaurant = user?.role == 'restaurant_owner';

    if (_loading) {
      return Container(
        height: 220,
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Color(0xFF2E7D32)),
              SizedBox(height: 12),
              Text(
                'Detecting your waste collection route...',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          children: [
            const Icon(Icons.sync_problem, color: Colors.red, size: 36),
            const SizedBox(height: 8),
            Text(
              'Unable to load route schedule: $_error',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: _loadScheduleAndMatch,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // State 4: Location coordinates not set
    if (!hasCoords) {
      return _buildNoCoordinatesCard(user, isRestaurant);
    }

    // State 3: Out of coverage / No route saved by manager
    if (_isOutOfCoverage || _assignedRoute == null) {
      return _buildOutOfCoverageCard(user!, isRestaurant);
    }

    // State 1 & 2: Route assigned (either operates today or upcoming)
    final operatesToday = _assignedRoute!['operatesToday'] == true;
    return _buildActiveRouteCard(user!, isRestaurant, operatesToday);
  }

  // ─────────────────────────────────────────────────────────
  // CARD 1 & 2: Active or Upcoming Route Card with Interactive Map
  // ─────────────────────────────────────────────────────────
  Widget _buildActiveRouteCard(UserModel user, bool isRestaurant, bool operatesToday) {
    final routeName = _assignedRoute!['routeName']?.toString() ?? 'Collection Route';
    final zone = _assignedRoute!['zone']?.toString() ?? 'Neighborhood';
    final todayCat = _assignedRoute!['todayCategory']?.toString() ?? 'organic';

    final userLat = user.locationCoordinates!.lat!;
    final userLng = user.locationCoordinates!.lng!;
    final userPos = LatLng(userLat, userLng);

    // Parse route stops
    final rawStops = ((_assignedRoute!['routeStops'] as List?) ??
            (_assignedRoute!['stops'] as List?) ??
            [])
        .whereType<Map>()
        .map((s) => Map<String, dynamic>.from(s))
        .toList();

    final List<LatLng> polylinePoints = [];
    final List<Marker> markers = [];

    // Add User Pin
    markers.add(
      Marker(
        point: userPos,
        width: 48,
        height: 48,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: isRestaurant ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Icon(
                isRestaurant ? Icons.restaurant : Icons.home,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );

    // Add Stop Pins & Polyline
    for (int i = 0; i < rawStops.length; i++) {
      final stop = rawStops[i];
      final loc = stop['location'] as Map<String, dynamic>? ?? {};
      final lat = (loc['lat'] ?? stop['lat']) as num?;
      final lng = (loc['lng'] ?? stop['lng']) as num?;

      if (lat != null && lng != null) {
        final pos = LatLng(lat.toDouble(), lng.toDouble());
        polylinePoints.add(pos);

        final seq = stop['sequenceOrder'] ?? (i + 1);
        final status = (stop['status']?.toString() ?? 'pending').toLowerCase();
        final isCollected = status == 'collected';

        markers.add(
          Marker(
            point: pos,
            width: 38,
            height: 38,
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedStop = stop);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isCollected ? const Color(0xFF00897B) : const Color(0xFF2E7D32),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                  boxShadow: const [
                    BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Center(
                  child: isCollected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : Text(
                          '$seq',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Header Banner
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              color: operatesToday ? const Color(0xFFE8F5E9) : const Color(0xFFFFF8E1),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: operatesToday ? const Color(0xFF2E7D32) : const Color(0xFFFFA000),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      operatesToday ? Icons.local_shipping : Icons.schedule,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              operatesToday ? 'Collection Active Today!' : 'No Collection Today',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: operatesToday
                                    ? const Color(0xFF1B5E20)
                                    : const Color(0xFFB45309),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: operatesToday
                                    ? const Color(0xFF2E7D32).withAlpha(30)
                                    : const Color(0xFFFFA000).withAlpha(38),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                zone,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: operatesToday
                                      ? const Color(0xFF2E7D32)
                                      : const Color(0xFFB45309),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          routeName,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Schedule & Category Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (operatesToday) ...[
                    Row(
                      children: [
                        const Icon(Icons.recycling, size: 18, color: Color(0xFF2E7D32)),
                        const SizedBox(width: 8),
                        Text(
                          'Today\'s Category: ',
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
                        ),
                        Text(
                          _formatCategory(todayCat),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '🚛 Waste truck is scheduled on your street today. Place bins out by 7:00 AM.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ] else if (_nextCollectionInfo != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.event, color: Color(0xFFB45309), size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _nextCollectionInfo!['isTomorrow'] == 'true'
                                      ? '🗓️ Next Collection: Tomorrow (${_nextCollectionInfo!['day']})'
                                      : '🗓️ Next Collection: ${_nextCollectionInfo!['date']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFFB45309),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Target: ${_formatCategory(_nextCollectionInfo!['category'])}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.brown.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (_closestStop != null && _distanceToClosestStop != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.near_me, size: 15, color: Color(0xFF1565C0)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Nearest collection point: ${_closestStop!['address'] ?? 'Street Stop'} (${_distanceToClosestStop!.toStringAsFixed(0)}m away)',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Interactive Map View
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: userPos,
                      initialZoom: 15.0,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.ecotrack.app',
                      ),
                      if (polylinePoints.isNotEmpty)
                        PolylineLayer(
                          polylines: [
                            Polyline(
                              points: polylinePoints,
                              strokeWidth: 4.5,
                              color: const Color(0xFF2E7D32).withAlpha(216),
                            ),
                          ],
                        ),
                      MarkerLayer(markers: markers),
                    ],
                  ),

                  // Map controls overlay
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Column(
                      children: [
                        _mapButton(
                          icon: Icons.my_location,
                          tooltip: 'Recenter on my location',
                          onTap: () => _mapController.move(userPos, 15.5),
                        ),
                        const SizedBox(height: 6),
                        _mapButton(
                          icon: Icons.zoom_in,
                          tooltip: 'Zoom in',
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom + 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _mapButton(
                          icon: Icons.zoom_out,
                          tooltip: 'Zoom out',
                          onTap: () => _mapController.move(
                            _mapController.camera.center,
                            _mapController.camera.zoom - 1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Map Legend Pill
                  Positioned(
                    bottom: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(242),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 4),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isRestaurant ? Icons.restaurant : Icons.home,
                            size: 14,
                            color: isRestaurant ? const Color(0xFFE65100) : const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isRestaurant ? 'Restaurant' : 'House',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFF2E7D32),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('Points', style: TextStyle(fontSize: 11)),
                          const SizedBox(width: 8),
                          Container(
                            width: 16,
                            height: 3,
                            color: const Color(0xFF2E7D32),
                          ),
                          const SizedBox(width: 4),
                          const Text('Route', style: TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Selected Stop Card (if tapped)
            if (_selectedStop != null)
              Container(
                padding: const EdgeInsets.all(14),
                color: const Color(0xFFF1F8E9),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '#${_selectedStop!['sequenceOrder'] ?? ''}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedStop!['address'] ?? 'Waste Collection Point',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          Text(
                            'Status: ${(_selectedStop!['status'] ?? 'pending').toString().toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: (_selectedStop!['status'] == 'collected')
                                  ? const Color(0xFF00897B)
                                  : const Color(0xFF2E7D32),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => setState(() => _selectedStop = null),
                    ),
                  ],
                ),
              ),

            // Footer action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                children: [
                  Text(
                    '${rawStops.length} collection points on this route',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _openLocationPicker(user),
                    icon: const Icon(Icons.edit_location_alt, size: 16),
                    label: const Text('Update Location', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // CARD 3: Out of Route Coverage / Not Saved by Manager
  // ─────────────────────────────────────────────────────────
  Widget _buildOutOfCoverageCard(UserModel user, bool isRestaurant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFCC80), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF3E0),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFE65100), size: 26),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Route for Your Area',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    Text(
                      'Municipal route not yet mapped to this location',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Your registered location is currently outside the scheduled municipal waste collection routes. Regular roadside collection is not active here yet.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.4),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (widget.onGoToRequests != null) {
                      widget.onGoToRequests!();
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RequestCollectionScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.local_shipping_outlined, size: 16),
                  label: const Text('Request Pickup', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => _openLocationPicker(user),
                icon: const Icon(Icons.map, size: 16),
                label: const Text('Change Location', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFE65100),
                  side: const BorderSide(color: Color(0xFFE65100)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // CARD 4: Prompt when Coordinates Not Marked
  // ─────────────────────────────────────────────────────────
  Widget _buildNoCoordinatesCard(UserModel? user, bool isRestaurant) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFBBDEFB), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFE3F2FD),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_location_alt, color: Color(0xFF1565C0), size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isRestaurant ? 'Pin Your Restaurant on Map' : 'Pin Your House on Map',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1565C0),
                      ),
                    ),
                    const Text(
                      'View your collection route and today\'s schedule',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Mark your exact location on the map so EcoTrack can match you to your neighborhood collection route and alert you on collection days.',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                if (user != null) _openLocationPicker(user);
              },
              icon: const Icon(Icons.pin_drop, size: 18),
              label: const Text('Mark Location on Map'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Icon(icon, size: 18, color: Colors.black87),
        ),
      ),
    );
  }
}
