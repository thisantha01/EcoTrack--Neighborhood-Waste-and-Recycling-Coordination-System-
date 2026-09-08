import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class ManagerRouteMapScreen extends StatelessWidget {
  final Map<String, dynamic> route;

  const ManagerRouteMapScreen({super.key, required this.route});

  @override
  Widget build(BuildContext context) {
    final area = route['areaCoordinates'];
    final center = area is Map && area['lat'] is num && area['lng'] is num
        ? LatLng((area['lat'] as num).toDouble(), (area['lng'] as num).toDouble())
        : const LatLng(6.9271, 79.8612);
    final stops = (route['routeStops'] as List?) ?? (route['stops'] as List?) ?? const [];
    final markers = <Marker>[
      Marker(point: center, width: 42, height: 42, child: const Icon(Icons.alt_route, color: Color(0xFF0097A7), size: 36)),
    ];
    for (final stop in stops) {
      if (stop is Map && stop['location'] is Map && stop['location']['lat'] is num && stop['location']['lng'] is num) {
        markers.add(Marker(
          point: LatLng((stop['location']['lat'] as num).toDouble(), (stop['location']['lng'] as num).toDouble()),
          width: 36,
          height: 36,
          child: const Icon(Icons.location_pin, color: Colors.red, size: 34),
        ));
      }
    }
    final driver = route['assignedDriver'];
    return Scaffold(
      appBar: AppBar(title: Text(route['routeName']?.toString() ?? 'Route Map'), backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white),
      body: Stack(children: [
        FlutterMap(
          options: MapOptions(initialCenter: center, initialZoom: 12),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.ecotrack.app'),
            MarkerLayer(markers: markers),
          ],
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 16,
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(route['routeName']?.toString() ?? 'Route', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${route['zone'] ?? ''} • ${stops.length} stops'),
                  Text('Driver: ${driver is Map ? driver['name'] ?? 'Unassigned' : 'Unassigned'}'),
                  Text('Status: ${route['status'] ?? 'Inactive'}'),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
