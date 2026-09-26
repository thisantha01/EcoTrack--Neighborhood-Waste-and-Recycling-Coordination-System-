import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/driver_provider.dart';
import 'widgets/driver_bottom_navigation.dart';

class TodayRouteScreen extends StatefulWidget {
  const TodayRouteScreen({super.key, this.showBottomNavigationBar = true});
  final bool showBottomNavigationBar;

  @override
  State<TodayRouteScreen> createState() => _TodayRouteScreenState();
}

class _TodayRouteScreenState extends State<TodayRouteScreen> {
  int _routeIndex = 0;
  late final DriverProvider _driverProvider;

  @override
  void initState() {
    super.initState();
    _driverProvider = context.read<DriverProvider>();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _driverProvider.fetchAssignedRoutes();
      if (mounted) await _driverProvider.startLiveTracking();
    });
  }

  @override
  void dispose() {
    _driverProvider.stopLiveTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final routes = provider.assignedRoutes;
    if (_routeIndex >= routes.length && routes.isNotEmpty) _routeIndex = 0;
    final route = routes.isEmpty ? null : routes[_routeIndex];
    final stops = _stops(route);
    final position = provider.liveLocation;
    final center = position != null
        ? LatLng(position.latitude, position.longitude)
        : stops.isNotEmpty
            ? stops.first.point
            : const LatLng(6.9271, 79.8612);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Today's Route"),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
      ),
      body: provider.isRoutesLoading
          ? const Center(child: CircularProgressIndicator())
          : routes.isEmpty
              ? const Center(child: Text('No active route assigned today.'))
              : Column(
                  children: [
                    if (routes.length > 1)
                      _RoutePicker(
                        routes: routes,
                        selectedIndex: _routeIndex,
                        onChanged: (index) => setState(() => _routeIndex = index),
                      ),
                    Expanded(
                      child: FlutterMap(
                        options: MapOptions(initialCenter: center, initialZoom: 13),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.ecotrack.app',
                          ),
                          MarkerLayer(
                            markers: [
                              if (position != null)
                                Marker(
                                  point: LatLng(position.latitude, position.longitude),
                                  width: 52,
                                  height: 52,
                                  child: const Icon(Icons.navigation, color: Colors.blue, size: 42),
                                ),
                              ...stops.map(
                                (stop) => Marker(
                                  point: stop.point,
                                  width: 46,
                                  height: 46,
                                  child: GestureDetector(
                                    onTap: () => _showStopActions(route!, stop),
                                    child: Icon(Icons.location_pin, color: _statusColor(stop.status), size: 44),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    _StopList(route: route!, stops: stops, onTap: (stop) => _showStopActions(route, stop)),
                ],
              ),
      bottomNavigationBar: widget.showBottomNavigationBar
          ? const DriverBottomNavigation(selectedIndex: 2)
          : null,
    );
  }

  List<_RouteStop> _stops(Map<String, dynamic>? route) {
    final raw = (route?['routeStops'] as List?) ?? const [];
    return raw.whereType<Map>().map((rawStop) {
      final stop = Map<String, dynamic>.from(rawStop);
      final location = stop['location'] as Map?;
      if (stop['_id'] == null || location?['lat'] is! num || location?['lng'] is! num) {
        return null;
      }
      return _RouteStop(
        id: stop['_id'].toString(),
        point: LatLng((location!['lat'] as num).toDouble(), (location['lng'] as num).toDouble()),
        address: stop['address']?.toString() ?? 'Collection stop',
        status: stop['status']?.toString() ?? 'pending',
      );
    }).whereType<_RouteStop>().toList();
  }

  Future<void> _showStopActions(Map<String, dynamic> route, _RouteStop stop) async {
    final status = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(children: [
          ListTile(title: Text(stop.address), subtitle: Text('Current status: ${stop.status}')),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Mark collected'),
            onTap: () => Navigator.pop(sheetContext, 'collected'),
          ),
          ListTile(
            leading: const Icon(Icons.skip_next, color: Colors.grey),
            title: const Text('Mark skipped'),
            onTap: () => Navigator.pop(sheetContext, 'skipped'),
          ),
        ]),
      ),
    );
    if (status == null || !mounted) return;
    final updated = await context.read<DriverProvider>().updateRouteStopStatus(
          routeId: route['_id']?.toString() ?? '',
          stopId: stop.id,
          status: status,
        );
    if (!updated && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to update this stop. Please try again.')),
      );
    }
  }

  Color _statusColor(String status) => switch (status) {
        'collected' => Colors.green,
        'skipped' => Colors.grey,
        _ => Colors.red,
      };
}

class _RouteStop {
  const _RouteStop({required this.id, required this.point, required this.address, required this.status});
  final String id;
  final LatLng point;
  final String address;
  final String status;
}

class _RoutePicker extends StatelessWidget {
  const _RoutePicker({required this.routes, required this.selectedIndex, required this.onChanged});
  final List<Map<String, dynamic>> routes;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 54,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(8),
          itemCount: routes.length,
          itemBuilder: (_, index) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(routes[index]['routeName']?.toString() ?? 'Route'),
              selected: selectedIndex == index,
              onSelected: (_) => onChanged(index),
            ),
          ),
        ),
      );
}

class _StopList extends StatelessWidget {
  const _StopList({required this.route, required this.stops, required this.onTap});
  final Map<String, dynamic> route;
  final List<_RouteStop> stops;
  final ValueChanged<_RouteStop> onTap;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: 180,
        child: ListView.builder(
          itemCount: stops.length,
          itemBuilder: (_, index) {
            final stop = stops[index];
            return ListTile(
              onTap: () => onTap(stop),
              leading: Icon(Icons.location_pin, color: _color(stop.status)),
              title: Text(stop.address),
              subtitle: Text(stop.status),
            );
          },
        ),
      );

  Color _color(String status) => status == 'collected'
      ? Colors.green
      : status == 'skipped'
          ? Colors.grey
          : Colors.red;
}
