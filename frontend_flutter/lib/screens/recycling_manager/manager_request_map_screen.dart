import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/collection_request_model.dart';
import '../../providers/manager_provider.dart';
import 'manager_assignment_screen.dart';
import 'manager_route_map_screen.dart';

class ManagerRequestMapScreen extends StatefulWidget {
  final CollectionRequest request;

  const ManagerRequestMapScreen({super.key, required this.request});

  @override
  State<ManagerRequestMapScreen> createState() =>
      _ManagerRequestMapScreenState();
}

class _ManagerRequestMapScreenState extends State<ManagerRequestMapScreen> {
  static const LatLng _malabeDefault = LatLng(6.9061, 79.9696);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagerProvider>();
      provider.fetchRoutes();
      provider.fetchAvailableDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestPoint = LatLng(
      widget.request.lat ?? _malabeDefault.latitude,
      widget.request.lng ?? _malabeDefault.longitude,
    );

    final isSpecial = widget.request.estimatedQuantity >= 10.0 ||
        widget.request.wasteType == 'electronic' ||
        widget.request.wasteType == 'hazardous' ||
        widget.request.wasteType == 'organic';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Collection Map (Malabe)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, child) {
          final markers = <Marker>[];
          final polylines = <Polyline>[];

          // Request Marker
          markers.add(
            Marker(
              point: requestPoint,
              width: 50,
              height: 50,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.location_on,
                    color: Colors.red,
                    size: 46,
                  ),
                  Positioned(
                    top: 8,
                    child: Icon(
                      CollectionRequest.getWasteTypeIcon(widget.request.wasteType),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          );

          // Route Markers & Polylines
          for (final route in provider.routes) {
            final rawStops = (route['routeStops'] as List?) ??
                (route['stops'] as List?) ??
                const [];
            final routePts = <LatLng>[];

            for (int i = 0; i < rawStops.length; i++) {
              final stop = rawStops[i];
              if (stop is Map && stop['location'] is Map) {
                final lat = stop['location']['lat'];
                final lng = stop['location']['lng'];
                if (lat is num && lng is num) {
                  final pt = LatLng(lat.toDouble(), lng.toDouble());
                  routePts.add(pt);
                  markers.add(
                    Marker(
                      point: pt,
                      width: 28,
                      height: 28,
                      child: GestureDetector(
                        onTap: () => _showRoute(route),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF0097A7),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              }
            }

            if (routePts.length > 1) {
              polylines.add(
                Polyline(
                  points: routePts,
                  color: const Color(0xFF0097A7).withValues(alpha: 0.6),
                  strokeWidth: 3.0,
                ),
              );
            }
          }

          return Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: requestPoint,
                  initialZoom: 13.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.ecotrack.app',
                  ),
                  if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Map Legend
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on, color: Colors.red, size: 14),
                          SizedBox(width: 4),
                          Text('Request Stop', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle, color: Color(0xFF0097A7), size: 12),
                          SizedBox(width: 4),
                          Text('Route Waypoints', style: TextStyle(fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Request Card & Actions
              Positioned(
                left: 12,
                right: 12,
                bottom: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${widget.request.wasteTypeLabel} Pickup',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            if (isSpecial)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Special / Excess',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                widget.request.location,
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Requester: ${widget.request.requester?.name ?? 'Resident'}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '${widget.request.estimatedQuantity} kg',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0097A7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0097A7),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              final navigator = Navigator.of(context);
                              final assigned = await navigator.push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => ManagerAssignmentScreen(
                                    request: widget.request,
                                  ),
                                ),
                              );
                              if (assigned == true && mounted) {
                                navigator.pop(true);
                              }
                            },
                            icon: const Icon(Icons.auto_awesome, size: 16),
                            label: const Text(
                              'Smart Assign to Nearest Malabe Route',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRoute(Map<String, dynamic> route) {
    final driver = route['assignedDriver'];
    final rawStops = (route['routeStops'] as List?) ??
        (route['stops'] as List?) ??
        const [];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0097A7).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    route['zone']?.toString() ?? 'Malabe',
                    style: const TextStyle(
                      color: Color(0xFF0097A7),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Driver: ${driver is Map ? driver['name'] ?? 'Unassigned' : 'Unassigned'}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.alt_route, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text(
                  'Stops / Waypoints: ${rawStops.length}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ManagerRouteMapScreen(route: route),
                        ),
                      );
                    },
                    icon: const Icon(Icons.map, size: 16),
                    label: const Text('View Route'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0097A7),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      navigator.pop();
                      final assigned = await navigator.push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ManagerAssignmentScreen(
                            request: widget.request,
                          ),
                        ),
                      );
                      if (assigned == true && mounted) {
                        navigator.pop(true);
                      }
                    },
                    icon: const Icon(Icons.add_location, size: 16),
                    label: const Text('Append Stop'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
