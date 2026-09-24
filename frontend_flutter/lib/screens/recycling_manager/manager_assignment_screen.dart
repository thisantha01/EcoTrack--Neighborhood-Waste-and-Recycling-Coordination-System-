import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/collection_request_model.dart';
import '../../providers/manager_provider.dart';

class ManagerAssignmentScreen extends StatefulWidget {
  final CollectionRequest request;

  const ManagerAssignmentScreen({super.key, required this.request});

  @override
  State<ManagerAssignmentScreen> createState() =>
      _ManagerAssignmentScreenState();
}

class _ManagerAssignmentScreenState extends State<ManagerAssignmentScreen> {
  static const LatLng _malabeDefault = LatLng(6.9061, 79.9696);

  String? _routeId;
  String? _driverId;
  DateTime? _date;
  TimeOfDay? _time;
  Map<String, dynamic>? _suggestedRoute;
  double? _suggestedDistanceKm;
  String? _closestPointName;
  bool _isLoadingSuggestion = true;
  bool _saving = false;

  TimeOfDay? _parseTimeOfDay(String? timeStr) {
    if (timeStr == null || timeStr.trim().isEmpty) return null;
    final clean = timeStr.trim();

    // 12-hour format with AM/PM e.g. "9:30 AM", "09:30 PM", "2:00PM"
    final regex12 = RegExp(r'^(\d{1,2}):(\d{2})\s*(AM|PM)$', caseSensitive: false);
    final match12 = regex12.firstMatch(clean);
    if (match12 != null) {
      int hour = int.parse(match12.group(1)!);
      final minute = int.parse(match12.group(2)!);
      final period = match12.group(3)!.toUpperCase();
      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: minute);
    }

    // 24-hour format e.g. "09:30", "14:00", "9:05"
    final regex24 = RegExp(r'^(\d{1,2}):(\d{2})$');
    final match24 = regex24.firstMatch(clean);
    if (match24 != null) {
      final hour = int.parse(match24.group(1)!);
      final minute = int.parse(match24.group(2)!);
      if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    // Hour only with AM/PM e.g. "8AM", "2 PM"
    final regexHourOnly = RegExp(r'(\d{1,2})\s*(AM|PM)', caseSensitive: false);
    final matchHour = regexHourOnly.firstMatch(clean);
    if (matchHour != null) {
      int hour = int.parse(matchHour.group(1)!);
      final period = matchHour.group(2)!.toUpperCase();
      if (period == 'PM' && hour < 12) hour += 12;
      if (period == 'AM' && hour == 12) hour = 0;
      return TimeOfDay(hour: hour, minute: 0);
    }

    return null;
  }

  @override
  void initState() {
    super.initState();
    _date = widget.request.preferredDate ?? DateTime.now();
    _time = _parseTimeOfDay(widget.request.preferredTime) ??
        const TimeOfDay(hour: 9, minute: 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagerProvider>();
      provider.fetchRoutes();
      provider.fetchAvailableDrivers();

      final double queryLat = widget.request.lat ?? _malabeDefault.latitude;
      final double queryLng = widget.request.lng ?? _malabeDefault.longitude;

      provider.suggestRoute(lat: queryLat, lng: queryLng).then((res) {
        if (!mounted) return;
        setState(() {
          _isLoadingSuggestion = false;
          if (res != null) {
            _suggestedRoute = res;
            _suggestedDistanceKm = (res['distanceKm'] as num?)?.toDouble();
            final cp = res['closestPoint'];
            if (cp is Map) {
              _closestPointName = cp['stopName']?.toString() ?? cp['areaName']?.toString();
            }
            _routeId ??= res['_id']?.toString();
            final driver = res['assignedDriver'];
            _driverId ??= driver is Map
                ? (driver['_id']?.toString() ?? driver['driverId']?.toString())
                : null;
          }
        });
      }).catchError((_) {
        if (mounted) setState(() => _isLoadingSuggestion = false);
      });
    });
  }

  Future<void> _chooseDate() async {
    final value = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (value != null) setState(() => _date = value);
  }

  Future<void> _chooseTime() async {
    final value = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (value != null) setState(() => _time = value);
  }

  Future<void> _confirmAssignment() async {
    final time = _time ?? const TimeOfDay(hour: 9, minute: 0);
    final provider = context.read<ManagerProvider>();

    if (_routeId == null) {
      _showMessage('Please select a route to append this request to');
      return;
    }

    if (_driverId == null) {
      _showMessage('Please select an assigned driver for this route');
      return;
    }

    if (_date == null) {
      _showMessage('Please select a collection date');
      return;
    }

    final matchingRoutes = provider.routes
        .where((route) => route['_id']?.toString() == _routeId)
        .toList();

    final operatingDays = matchingRoutes.isEmpty
        ? const <String>[]
        : (matchingRoutes.first['operatingDays'] as List? ?? const [])
            .map((day) => day.toString())
            .toList();

    if (operatingDays.isNotEmpty &&
        !operatingDays.contains(_weekdayName(_date!))) {
      _showMessage('This route operates on ${operatingDays.join(', ')}');
      return;
    }

    setState(() => _saving = true);

    final success = await provider.confirmRequestRoute(
      routeId: _routeId!,
      collectionRequestId: widget.request.id,
      driverId: _driverId!,
      date: _date!,
      time: time.format(context),
    );

    if (mounted) {
      setState(() => _saving = false);
      if (success) {
        _showMessage('Special request successfully appended to route!');
        Navigator.pop(context, true);
      } else {
        _showMessage(provider.error ?? 'Assignment failed');
      }
    }
  }

  void _showMessage(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0097A7),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final LatLng reqPos = LatLng(
      widget.request.lat ?? _malabeDefault.latitude,
      widget.request.lng ?? _malabeDefault.longitude,
    );

    final isSpecialPickup = widget.request.estimatedQuantity >= 10.0 ||
        widget.request.wasteType == 'electronic' ||
        widget.request.wasteType == 'hazardous' ||
        widget.request.wasteType == 'organic';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text(
          'Smart Route Assignment',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, child) {
          final matchingRoutes = provider.routes
              .where((r) => r['_id']?.toString() == _routeId)
              .toList();
          final selectedRoute = matchingRoutes.isNotEmpty ? matchingRoutes.first : _suggestedRoute;

          // Build mini-map markers and polyline
          final markers = <Marker>[
            // Request marker (Red)
            Marker(
              point: reqPos,
              width: 44,
              height: 44,
              child: const Tooltip(
                message: 'Special Request Location',
                child: Icon(Icons.location_on, color: Colors.red, size: 42),
              ),
            ),
          ];

          final polylinePoints = <LatLng>[];

          if (selectedRoute != null) {
            final rawStops = (selectedRoute['routeStops'] as List?) ??
                (selectedRoute['stops'] as List?) ??
                [];
            for (int i = 0; i < rawStops.length; i++) {
              final s = rawStops[i];
              if (s is Map && s['location'] is Map) {
                final lat = s['location']['lat'];
                final lng = s['location']['lng'];
                if (lat is num && lng is num) {
                  final pt = LatLng(lat.toDouble(), lng.toDouble());
                  polylinePoints.add(pt);
                  markers.add(
                    Marker(
                      point: pt,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF0097A7),
                          shape: BoxShape.circle,
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
                  );
                }
              }
            }
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Special Pickup Header
              _specialPickupCard(isSpecialPickup),
              const SizedBox(height: 14),

              // Smart Route Suggestion Banner
              if (_isLoadingSuggestion)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0097A7)),
                        ),
                        SizedBox(width: 12),
                        Text('Finding nearest active route in Malabe...', style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ),
                )
              else if (_suggestedRoute != null)
                _suggestedRouteBanner(_suggestedRoute!)
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'No active route found directly nearby. You can select an active route below or create a new route.',
                    style: TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ),

              const SizedBox(height: 14),

              // Proximity Mini Map
              Card(
                elevation: 1,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                child: SizedBox(
                  height: 190,
                  child: Stack(
                    children: [
                      FlutterMap(
                        options: MapOptions(
                          initialCenter: reqPos,
                          initialZoom: 13.5,
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
                                  strokeWidth: 3.5,
                                ),
                              ],
                            ),
                          MarkerLayer(markers: markers),
                        ],
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.location_on, color: Colors.red, size: 14),
                              SizedBox(width: 4),
                              Text('Request', style: TextStyle(color: Colors.white, fontSize: 10)),
                              SizedBox(width: 8),
                              Icon(Icons.circle, color: Color(0xFF0097A7), size: 10),
                              SizedBox(width: 4),
                              Text('Route Stops', style: TextStyle(color: Colors.white, fontSize: 10)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // Select Route Dropdown
              const Text(
                'Target Route (Append Stop)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _routeId,
                decoration: _decoration(Icons.alt_route, 'Choose route'),
                items: provider.routes.map((route) {
                  final id = route['_id']?.toString();
                  if (id == null) return null;
                  final name = route['routeName']?.toString() ?? 'Route';
                  final zone = route['zone']?.toString() ?? '';
                  return DropdownMenuItem(
                    value: id,
                    child: Text('$name ($zone)'),
                  );
                }).whereType<DropdownMenuItem<String>>().toList(),
                onChanged: (value) {
                  final r = provider.routes.firstWhere(
                    (item) => item['_id']?.toString() == value,
                    orElse: () => {},
                  );
                  final d = r['assignedDriver'];
                  setState(() {
                    _routeId = value;
                    _driverId = d is Map ? (d['_id']?.toString() ?? d['driverId']?.toString()) : null;
                  });
                },
              ),

              if (selectedRoute != null) ...[
                const SizedBox(height: 6),
                Text(
                  'Zone: ${selectedRoute['zone'] ?? ''} • Current stops: ${((selectedRoute['routeStops'] as List?) ?? (selectedRoute['stops'] as List?) ?? const []).length}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],

              const SizedBox(height: 16),

              // Assigned Driver Dropdown
              const Text(
                'Assigned Driver',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _driverId,
                decoration: _decoration(Icons.person_outline, 'Choose driver'),
                items: provider.availableDrivers.map((driver) {
                  final id = driver['driverId']?.toString() ?? driver['_id']?.toString();
                  if (id == null) return null;
                  final name = driver['name']?.toString() ?? 'Driver';
                  final isAvail = driver['availability'] == 'available';
                  return DropdownMenuItem(
                    value: id,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(name),
                        const SizedBox(width: 8),
                        Text(
                          isAvail ? 'Available' : 'Busy',
                          style: TextStyle(
                            fontSize: 11,
                            color: isAvail ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).whereType<DropdownMenuItem<String>>().toList(),
                onChanged: (value) => setState(() => _driverId = value),
              ),

              const SizedBox(height: 16),

              // Date & Time pickers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pickup Schedule Date & Time',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (widget.request.preferredDate != null ||
                      widget.request.preferredTime != null)
                    InkWell(
                      onTap: () {
                        setState(() {
                          if (widget.request.preferredDate != null) {
                            _date = widget.request.preferredDate;
                          }
                          final parsed = _parseTimeOfDay(widget.request.preferredTime);
                          if (parsed != null) {
                            _time = parsed;
                          }
                        });
                        _showMessage('Applied customer preferred date & time');
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0097A7).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.restore, size: 13, color: Color(0xFF0097A7)),
                            SizedBox(width: 4),
                            Text(
                              'Use Customer Preferred',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF0097A7),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _chooseDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(
                        _date == null
                            ? 'Date'
                            : DateFormat('EEE, MMM d, yyyy').format(_date!),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _chooseTime,
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(_time?.format(context) ?? 'Time'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Confirm Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _confirmAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0097A7),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.add_location_alt_outlined),
                  label: Text(
                    _saving ? 'Appending Stop...' : 'Append Stop to Nearest Route',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }

  Widget _specialPickupCard(bool isSpecial) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSpecial ? const Color(0xFF0097A7) : Colors.grey.shade200,
          width: isSpecial ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    CollectionRequest.getWasteTypeIcon(widget.request.wasteType),
                    color: const Color(0xFF0097A7),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${widget.request.wasteTypeLabel} Pickup',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
              if (isSpecial)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Special / Excess Waste',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.brown),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  widget.request.location,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Requester: ${widget.request.requester?.name ?? 'Resident / Business'}',
                style: const TextStyle(fontSize: 12, color: Colors.black87),
              ),
              Text(
                'Est: ${widget.request.estimatedQuantity} kg',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0097A7)),
              ),
            ],
          ),
          if (widget.request.preferredDate != null ||
              (widget.request.preferredTime != null &&
                  widget.request.preferredTime!.trim().isNotEmpty)) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF0097A7).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF0097A7).withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.event_available,
                    color: Color(0xFF0097A7),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Customer Preferred Schedule',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0097A7),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.request.preferredDate != null ? DateFormat('EEE, MMM d, yyyy').format(widget.request.preferredDate!) : 'No specific date'}'
                          ' • ${widget.request.preferredTime?.trim().isNotEmpty == true ? widget.request.preferredTime : 'Flexible time'}',
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
          ],
        ],
      ),
    );
  }

  Widget _suggestedRouteBanner(Map<String, dynamic> route) {
    final driver = route['assignedDriver'];
    final driverName = driver is Map ? driver['name']?.toString() ?? 'Unassigned' : 'Unassigned';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F6F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0097A7).withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF007C87), size: 16),
              SizedBox(width: 6),
              Text(
                'Nearest Active Malabe Route Found:',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF007C87), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            route['routeName']?.toString() ?? 'Malabe Route',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            'Zone: ${route['zone'] ?? 'Malabe'} • Driver: $driverName',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
          ),
          if (_suggestedDistanceKm != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.near_me, size: 13, color: Color(0xFF007C87)),
                const SizedBox(width: 4),
                Text(
                  'Distance: ~${_suggestedDistanceKm!.toStringAsFixed(2)} km${_closestPointName != null ? ' from $_closestPointName' : ''}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF007C87),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          const Text(
            'This route is optimal for appending this stop with minimal detour.',
            style: TextStyle(fontSize: 11, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  String _weekdayName(DateTime date) => const [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ][date.weekday - 1];

  InputDecoration _decoration(IconData icon, String hint) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0097A7)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      );
}
