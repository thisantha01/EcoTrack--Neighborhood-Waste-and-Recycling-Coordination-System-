import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/collection_request_model.dart';
import '../../providers/manager_provider.dart';

class ManagerAssignmentScreen extends StatefulWidget {
  final CollectionRequest request;

  const ManagerAssignmentScreen({super.key, required this.request});

  @override
  State<ManagerAssignmentScreen> createState() => _ManagerAssignmentScreenState();
}

class _ManagerAssignmentScreenState extends State<ManagerAssignmentScreen> {
  String? _routeId;
  String? _driverId;
  DateTime? _date;
  TimeOfDay? _time;
  Map<String, dynamic>? _suggestedRoute;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _date = widget.request.preferredDate ?? DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagerProvider>();
      provider.fetchRoutes();
      provider.fetchAvailableDrivers();
      if (widget.request.lat != null && widget.request.lng != null) {
        provider.suggestRoute(lat: widget.request.lat!, lng: widget.request.lng!).then((route) {
          if (!mounted || route == null) return;
          final driver = route['assignedDriver'];
          setState(() {
            _suggestedRoute = route;
            _routeId ??= route['_id']?.toString();
            _driverId ??= driver is Map ? driver['_id']?.toString() : null;
          });
        });
      }
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
      initialTime: _time ?? TimeOfDay.now(),
    );
    if (value != null) setState(() => _time = value);
  }

  Future<void> _confirm() async {
    final time = _time;
    final provider = context.read<ManagerProvider>();
    if (_routeId == null || _driverId == null || _date == null || time == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select route, driver, date and time')),
      );
      return;
    }

    final matchingRoutes = provider.routes.where((route) => route['_id']?.toString() == _routeId).toList();
    final operatingDays = matchingRoutes.isEmpty
        ? const <String>[]
        : (matchingRoutes.first['operatingDays'] as List? ?? const [])
            .map((day) => day.toString())
            .toList();
    if (operatingDays.isNotEmpty && !operatingDays.contains(_weekdayName(_date!))) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('This route operates on ${operatingDays.join(', ')}')));
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Collection scheduled successfully')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(provider.error ?? 'Assignment failed')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text('Assign Collection', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, child) {
          final matchingRoutes = provider.routes.where((r) => r['_id']?.toString() == _routeId).toList();
          final selectedRoute = matchingRoutes.isEmpty ? null : matchingRoutes.first;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _requestSummary(),
              const SizedBox(height: 18),
              if (_suggestedRoute != null) ...[
                _suggestedRouteCard(),
                const SizedBox(height: 14),
              ],
              const Text('Select route', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _routeId,
                decoration: _decoration(Icons.alt_route, 'Choose an existing route'),
                items: provider.routes.map((route) {
                  final id = route['_id']?.toString();
                  if (id == null) return null;
                  return DropdownMenuItem(value: id, child: Text(route['routeName']?.toString() ?? route['zone']?.toString() ?? 'Route'));
                }).whereType<DropdownMenuItem<String>>().toList(),
                onChanged: (value) {
                  final route = provider.routes.firstWhere((item) => item['_id']?.toString() == value, orElse: () => {});
                  final driver = route['assignedDriver'];
                  setState(() {
                    _routeId = value;
                    _driverId = driver is Map ? driver['_id']?.toString() : null;
                  });
                },
              ),
              if (selectedRoute != null) ...[
                const SizedBox(height: 8),
                Text('${selectedRoute['zone'] ?? ''} • ${((selectedRoute['routeStops'] as List?) ?? (selectedRoute['stops'] as List?) ?? const []).length} current stops', style: TextStyle(color: Colors.grey.shade700)),
              ],
              const SizedBox(height: 16),
              const Text('Select driver', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _driverId,
                decoration: _decoration(Icons.person_outline, 'Choose a driver'),
                items: provider.availableDrivers.map((driver) {
                  final id = driver['driverId']?.toString();
                  if (id == null) return null;
                  return DropdownMenuItem(value: id, child: Text(driver['name']?.toString() ?? 'Driver'));
                }).whereType<DropdownMenuItem<String>>().toList(),
                onChanged: (value) => setState(() => _driverId = value),
              ),
              const SizedBox(height: 16),
              const Text('Collection date and time', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Row(children: [
                Expanded(child: OutlinedButton.icon(onPressed: _chooseDate, icon: const Icon(Icons.calendar_today), label: Text(_date == null ? 'Date' : '${_date!.day}/${_date!.month}/${_date!.year}'))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton.icon(onPressed: _chooseTime, icon: const Icon(Icons.access_time), label: Text(_time?.format(context) ?? 'Time'))),
              ]),
              const SizedBox(height: 24),
              const Text('Assignment summary', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _summaryLine('Request', widget.request.wasteTypeLabel),
              _summaryLine('Location', widget.request.location),
              _summaryLine('Quantity', '${widget.request.estimatedQuantity} kg'),
              _summaryLine('Status after confirm', 'Scheduled'),
              const SizedBox(height: 20),
              SizedBox(height: 52, child: ElevatedButton.icon(
                onPressed: _saving ? null : _confirm,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white),
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Assigning...' : 'Confirm Assignment'),
              )),
            ],
          );
        },
      ),
    );
  }

  Widget _requestSummary() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Collection request', style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 4),
      Text(widget.request.wasteTypeLabel, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      Text(widget.request.location, style: TextStyle(color: Colors.grey.shade700)),
    ]),
  );

  Widget _summaryLine(String title, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: TextStyle(color: Colors.grey.shade700)), Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold)))]),
  );

  Widget _suggestedRouteCard() {
    final driver = _suggestedRoute?['assignedDriver'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: const Color(0xFFE3F6F7), borderRadius: BorderRadius.circular(14)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Suggested Route', style: TextStyle(color: Color(0xFF007C87), fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('${_suggestedRoute?['routeName'] ?? 'Route'} (${_suggestedRoute?['zone'] ?? ''})', style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('Permanent driver: ${driver is Map ? driver['name'] ?? 'Unassigned' : 'Unassigned'}'),
        const SizedBox(height: 4),
        const Text('Review this suggestion and change it before confirming if needed.', style: TextStyle(fontSize: 12)),
      ]),
    );
  }

  String _weekdayName(DateTime date) => const [
        'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
      ][date.weekday - 1];

  InputDecoration _decoration(IconData icon, String hint) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon, color: const Color(0xFF0097A7)),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  );
}
