import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/collection_request_model.dart';
import '../../providers/manager_provider.dart';

class AssignRouteScreen extends StatefulWidget {
  const AssignRouteScreen({super.key});

  @override
  State<AssignRouteScreen> createState() => _AssignRouteScreenState();
}

class _AssignRouteScreenState extends State<AssignRouteScreen> {
  final _routeNameController = TextEditingController();
  final _zoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _selectedRequestIds = {};
  DateTime _selectedDate = DateTime.now();
  String? _selectedDriverId;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ManagerProvider>();
      provider.fetchAvailableDrivers();
      provider.setFilter(status: 'requested');
      provider.fetchCollectionRequests(refresh: true);
    });
  }

  @override
  void dispose() {
    _routeNameController.dispose();
    _zoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    final provider = context.read<ManagerProvider>();
    final routeName = _routeNameController.text.trim();
    final zone = _zoneController.text.trim();

    if (routeName.isEmpty || zone.isEmpty) {
      _showMessage('Route name and zone are required');
      return;
    }

    setState(() => _isSubmitting = true);
    final routeId = await provider.createRoute(
      routeName: routeName,
      zone: zone,
      date: _selectedDate,
      description: _descriptionController.text.trim(),
      assignedDriver: _selectedDriverId,
    );

    if (routeId != null) {
      for (final requestId in _selectedRequestIds) {
        if (_selectedDriverId != null) {
          await provider.confirmRequestRoute(
            routeId: routeId,
            collectionRequestId: requestId,
            driverId: _selectedDriverId!,
            date: _selectedDate,
            time: '09:00 AM',
          );
        }
      }
      await provider.fetchRoutes();
      if (mounted) {
        _routeNameController.clear();
        _zoneController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedDriverId = null;
          _selectedRequestIds.clear();
        });
        _showMessage('Route created and requests assigned successfully');
      }
    } else if (mounted) {
      _showMessage(provider.error ?? 'Unable to create route');
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FBFB),
      appBar: AppBar(
        title: const Text('Create & Assign Route',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0097A7),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Consumer<ManagerProvider>(
        builder: (context, provider, child) => RefreshIndicator(
          onRefresh: () async {
            await provider.fetchAvailableDrivers();
            await provider.fetchCollectionRequests(refresh: true);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _label('Route name'),
              _field(_routeNameController, 'e.g. Nugegoda Route'),
              const SizedBox(height: 12),
              _label('Assigned area / zone'),
              _field(_zoneController, 'e.g. Nugegoda'),
              const SizedBox(height: 12),
              _label('Description'),
              _field(_descriptionController, 'Regular collection route', maxLines: 2),
              const SizedBox(height: 12),
              _label('Assigned driver'),
              DropdownButtonFormField<String>(
                initialValue: _selectedDriverId,
                decoration: _decoration(Icons.person, 'Choose a driver'),
                items: provider.availableDrivers.map((driver) {
                  final id = driver['driverId']?.toString();
                  if (id == null) return null;
                  return DropdownMenuItem<String>(
                    value: id,
                    child: Text(driver['name']?.toString() ?? 'Driver'),
                  );
                }).whereType<DropdownMenuItem<String>>().toList(),
                onChanged: (value) => setState(() => _selectedDriverId = value),
              ),
              const SizedBox(height: 12),
              _label('Route date'),
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: _decoration(Icons.calendar_today, 'Select date'),
                  child: Text(
                    '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _label('Add pending collection requests'),
              if (provider.isLoadingRequests)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.requests.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No pending collection requests found.'),
                )
              else
                ...provider.requests.map(_requestTile),
              const SizedBox(height: 20),
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0097A7),
                    foregroundColor: Colors.white,
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.alt_route),
                  label: Text(_isSubmitting ? 'Creating...' : 'Create Route'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestTile(CollectionRequest request) {
    final selected = _selectedRequestIds.contains(request.id);
    return Card(
      elevation: 0,
      child: CheckboxListTile(
        value: selected,
        activeColor: const Color(0xFF0097A7),
        title: Text(request.location),
        subtitle: Text('${request.wasteTypeLabel} • ${request.estimatedQuantity} kg'),
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedRequestIds.add(request.id);
            } else {
              _selectedRequestIds.remove(request.id);
            }
          });
        },
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      );

  Widget _field(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: _decoration(null, hint),
    );
  }

  InputDecoration _decoration(IconData? icon, String hint) => InputDecoration(
        hintText: hint,
        prefixIcon: icon == null
            ? null
            : Icon(icon, color: const Color(0xFF0097A7)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      );
}
