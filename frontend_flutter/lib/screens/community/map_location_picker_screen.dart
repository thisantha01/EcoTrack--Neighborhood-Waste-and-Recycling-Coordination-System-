import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Returned when the user confirms a location.
class PickedLocation {
  final double lat;
  final double lng;
  final String? label;

  const PickedLocation({
    required this.lat,
    required this.lng,
    this.label,
  });
}

/// A full-screen map that lets the user tap to place a marker and confirm.
class MapLocationPickerScreen extends StatefulWidget {
  final LatLng? initialPosition;
  final String? initialLabel;

  const MapLocationPickerScreen({
    super.key,
    this.initialPosition,
    this.initialLabel,
  });

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  final TextEditingController _labelCtrl = TextEditingController();
  LatLng? _selectedPoint;

  // Default centre: Colombo, Sri Lanka
  static const _defaultCentre = LatLng(6.9271, 79.8612);

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _selectedPoint = widget.initialPosition;
    }
    if (widget.initialLabel != null) {
      _labelCtrl.text = widget.initialLabel!;
    }
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng latLng) {
    setState(() {
      _selectedPoint = latLng;
    });
  }

  void _confirm() {
    if (_selectedPoint == null) return;
    Navigator.pop(
      context,
      PickedLocation(
        lat: _selectedPoint!.latitude,
        lng: _selectedPoint!.longitude,
        label: _labelCtrl.text.trim().isNotEmpty ? _labelCtrl.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
        title: const Text(
          '📍 Pick Location on Map',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: _selectedPoint != null ? _confirm : null,
            child: const Text(
              'CONFIRM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────
          FlutterMap(
            options: MapOptions(
              initialCenter: _selectedPoint ?? _defaultCentre,
              initialZoom: 14,
              onTap: _onMapTap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.ecotrack.app',
              ),
              if (_selectedPoint != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selectedPoint!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_pin,
                        color: Color(0xFFD32F2F),
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // ── Instruction banner ───────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFFD32F2F), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tap anywhere on the map to drop a pin at the exact location.',
                      style: TextStyle(fontSize: 13, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Selected coordinates display ─────────────────
          if (_selectedPoint != null)
            Positioned(
              bottom: 120,
              left: 12,
              right: 12,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.push_pin,
                        color: Color(0xFFD32F2F), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedPoint!.latitude.toStringAsFixed(5)}, '
                        '${_selectedPoint!.longitude.toStringAsFixed(5)}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedPoint = null),
                      child: const Text('Clear', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ),

          // ── Optional label input + confirm button ────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _labelCtrl,
                    decoration: InputDecoration(
                      hintText:
                          'Optional: add a label (e.g. "near bus stop")',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.label_outline, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _selectedPoint != null ? _confirm : null,
                      icon: const Icon(Icons.check, size: 20),
                      label: const Text(
                        'Use This Location',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade300,
                        disabledForegroundColor: Colors.grey.shade600,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
