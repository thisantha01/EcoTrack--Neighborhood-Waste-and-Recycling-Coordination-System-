import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/manager_provider.dart';
import 'manager_route_map_screen.dart';

class ManagerRoutesScreen extends StatefulWidget {
  const ManagerRoutesScreen({super.key});

  @override
  State<ManagerRoutesScreen> createState() => _ManagerRoutesScreenState();
}

class _ManagerRoutesScreenState extends State<ManagerRoutesScreen> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text('Route Management', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
        actions: [
          IconButton(onPressed: () => _showCreateRoute(), icon: const Icon(Icons.add), tooltip: 'Create new route'),
        ],
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, child) {
          if (provider.routes.isEmpty) {
            return RefreshIndicator(
              onRefresh: provider.fetchRoutes,
              child: ListView(children: const [SizedBox(height: 180), Center(child: Text('No routes found'))]),
            );
          }
          return RefreshIndicator(
            onRefresh: provider.fetchRoutes,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.routes.length,
              itemBuilder: (context, index) => _routeCard(provider.routes[index]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateRoute,
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Create New Route'),
      ),
    );
  }

  Widget _routeCard(Map<String, dynamic> route) {
    final driver = route['assignedDriver'];
    final days = (route['operatingDays'] as List? ?? const []).join(', ');
    final status = route['routeStatus']?.toString() ?? route['status']?.toString() ?? 'Inactive';
    final active = status == 'Active' || status == 'assigned' || status == 'in-progress';
    final stops = route['activeStopCount'] ?? (route['routeStops'] as List? ?? route['stops'] as List? ?? const []).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(route['routeName']?.toString() ?? 'Route', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
            _badge(route['zone']?.toString() ?? 'Area', const Color(0xFFE3F6F7)),
            const SizedBox(width: 6),
            _badge(active ? 'Active' : 'Inactive', active ? const Color(0xFFE1F5EC) : const Color(0xFFF1F1F1)),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            CircleAvatar(backgroundColor: const Color(0xFFDDF7F8), child: Icon(Icons.person, color: const Color(0xFF0097A7))),
            const SizedBox(width: 10),
            Text(driver is Map ? driver['name']?.toString() ?? 'Unassigned' : 'Unassigned', style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          _detailRow(Icons.calendar_month_outlined, days.isEmpty ? 'Operating days not set' : days),
          _detailRow(Icons.location_on_outlined, '$stops active pickups'),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton.icon(onPressed: () => _showChangeDriver(route), icon: const Icon(Icons.swap_horiz), label: const Text('Change Driver'))),
            const SizedBox(width: 10),
            Expanded(child: ElevatedButton.icon(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ManagerRouteMapScreen(route: route))), icon: const Icon(Icons.map_outlined), label: const Text('View Stops / Map'), style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white))),
          ]),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(children: [Icon(icon, size: 17, color: Colors.grey.shade600), const SizedBox(width: 8), Text(text, style: TextStyle(color: Colors.grey.shade700, fontSize: 13))]),
  );

  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
  );

  void _showChangeDriver(Map<String, dynamic> route) {
    String? selectedId = (route['assignedDriver'] is Map) ? route['assignedDriver']['_id']?.toString() : null;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(builder: (context, setModalState) {
        final managerProvider = context.read<ManagerProvider>();
        final drivers = managerProvider.availableDrivers;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Change route driver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: selectedId,
              decoration: const InputDecoration(labelText: 'Driver', border: OutlineInputBorder()),
              items: drivers.map((driver) {
                final id = driver['driverId']?.toString();
                return id == null ? null : DropdownMenuItem(value: id, child: Text(driver['name']?.toString() ?? 'Driver'));
              }).whereType<DropdownMenuItem<String>>().toList(),
              onChanged: (value) => setModalState(() => selectedId = value),
            ),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: selectedId == null ? null : () async {
                final ok = await managerProvider.changeRouteDriver(routeId: route['_id'].toString(), driverId: selectedId!);
                if (!mounted) return;
                if (sheetContext.mounted) Navigator.pop(sheetContext);
                ScaffoldMessenger.of(this.context).showSnackBar(SnackBar(content: Text(ok ? 'Driver changed successfully' : 'Unable to change driver')));
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0097A7), foregroundColor: Colors.white),
              child: const Text('Save Driver'),
            )),
          ]),
        );
      }),
    );
  }

  void _showCreateRoute() {
    final nameController = TextEditingController();
    final zoneController = TextEditingController();
    final days = <String>[];
    String? selectedDriverId;
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, setState) => AlertDialog(
        title: const Text('Create New Route'),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Route name')),
          TextField(controller: zoneController, decoration: const InputDecoration(labelText: 'Zone')),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: selectedDriverId,
            decoration: const InputDecoration(
              labelText: 'Assigned driver',
              prefixIcon: Icon(Icons.person_outline),
              border: OutlineInputBorder(),
            ),
            items: context.read<ManagerProvider>().availableDrivers.map((driver) {
              final id = driver['driverId']?.toString();
              if (id == null) return null;
              return DropdownMenuItem<String>(
                value: id,
                child: Text(driver['name']?.toString() ?? 'Driver'),
              );
            }).whereType<DropdownMenuItem<String>>().toList(),
            onChanged: (value) => setState(() => selectedDriverId = value),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            children: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
                .map((day) => FilterChip(
                      label: Text(day.substring(0, 3)),
                      selected: days.contains(day),
                      onSelected: (value) => setState(() => value ? days.add(day) : days.remove(day)),
                    ))
                .toList(),
          ),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          ElevatedButton(onPressed: () async {
            if (nameController.text.trim().isEmpty || zoneController.text.trim().isEmpty) return;
            final provider = context.read<ManagerProvider>();
            await provider.createRoute(routeName: nameController.text.trim(), zone: zoneController.text.trim(), date: DateTime.now(), assignedDriver: selectedDriverId, operatingDays: days);
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }, child: const Text('Create')),
        ],
      )),
    );
  }
}
