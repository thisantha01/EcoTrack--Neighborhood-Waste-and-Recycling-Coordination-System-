import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/collection_request_model.dart';
import '../../providers/manager_provider.dart';

class ManagerRequestMapScreen extends StatefulWidget {
  final CollectionRequest request;

  const ManagerRequestMapScreen({super.key, required this.request});

  @override
  State<ManagerRequestMapScreen> createState() => _ManagerRequestMapScreenState();
}

class _ManagerRequestMapScreenState extends State<ManagerRequestMapScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ManagerProvider>().fetchRoutes();
      context.read<ManagerProvider>().fetchAvailableDrivers();
    });
  }

  @override
  Widget build(BuildContext context) {
    final requestPoint = LatLng(widget.request.lat ?? 6.9271, widget.request.lng ?? 79.8612);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Map'),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, child) {
          final markers = <Marker>[
            Marker(point: requestPoint, width: 42, height: 42, child: const Icon(Icons.location_pin, color: Colors.red, size: 42)),
          ];
          for (final route in provider.routes) {
            final coords = route['areaCoordinates'];
            if (coords is Map && coords['lat'] is num && coords['lng'] is num) {
              markers.add(Marker(
                point: LatLng((coords['lat'] as num).toDouble(), (coords['lng'] as num).toDouble()),
                width: 36,
                height: 36,
                child: GestureDetector(
                  onTap: () => _showRoute(route),
                  child: const Icon(Icons.alt_route, color: Color(0xFF0097A7), size: 32),
                ),
              ));
            }
          }
          return Stack(children: [
            FlutterMap(
              options: MapOptions(initialCenter: requestPoint, initialZoom: 12),
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
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Selected request', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(widget.request.location),
                    const SizedBox(height: 6),
                    Text('Tap a route marker to review its driver and stops.', style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                  ]),
                ),
              ),
            ),
          ]);
        },
      ),
    );
  }

  void _showRoute(Map<String, dynamic> route) {
    final driver = route['assignedDriver'];
    final stops = route['stops'] as List? ?? const [];
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(route['routeName']?.toString() ?? 'Route', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(route['zone']?.toString() ?? ''),
          const SizedBox(height: 10),
          Text('Driver: ${driver is Map ? driver['name'] ?? 'Unassigned' : 'Unassigned'}'),
          Text('Stops: ${stops.length}'),
          Text('Status: ${route['status'] ?? 'draft'}'),
        ]),
      ),
    );
  }
}
