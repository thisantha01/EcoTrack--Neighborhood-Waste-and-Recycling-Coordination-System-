import 'package:flutter/material.dart';

class AssignRouteScreen extends StatefulWidget {
  const AssignRouteScreen({super.key});

  @override
  State<AssignRouteScreen> createState() => _AssignRouteScreenState();
}

class _AssignRouteScreenState extends State<AssignRouteScreen> {
  // Predefined Zones/Areas
  final List<String> _zones = [
    'Colombo 03 (Kollupitiya)',
    'Colombo 07 (Cinnamon Gardens)',
    'Maharagama Zone A',
    'Dehiwala Main Route',
    'Kaduwela Industrial Zone',
  ];

  // Shift Types
  final List<String> _shifts = ['Morning Shift', 'Evening Shift'];

  // Drivers List
  final List<Map<String, String>> _drivers = [
    {'id': 'driver_1', 'name': 'Sunil Perera (Driver #1)'},
    {'id': 'driver_2', 'name': 'Kamal Silva (Driver #2)'},
    {'id': 'driver_3', 'name': 'Nimal Siripala (Driver #3)'},
  ];

  // Pending Pickups
  final List<Map<String, dynamic>> _pendingPickups = [
    {
      'id': 'p1',
      'address': 'No. 12, Main St, Colombo 03',
      'type': 'Plastic/Metal',
      'selected': false
    },
    {
      'id': 'p2',
      'address': 'No. 45, Highlevel Rd, Maharagama',
      'type': 'Organic Waste',
      'selected': false
    },
    {
      'id': 'p3',
      'address': 'No. 88, Galle Rd, Dehiwala',
      'type': 'Paper/Cardboard',
      'selected': false
    },
  ];

  String? _selectedZone;
  String _selectedShift = 'Morning Shift';
  String? _selectedDriverId;
  DateTime _selectedDate = DateTime.now();
  bool _isLoading = false;

  // Auto-generated Route Name getter
  String get _generatedRouteName {
    if (_selectedZone == null) return 'Select a Zone to generate Route Name';
    final dateStr = "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";
    return '$_selectedZone | $_selectedShift | $dateStr';
  }

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submitRoute() async {
    final selectedPickupIds = _pendingPickups
        .where((p) => p['selected'] == true)
        .map((p) => p['id'] as String)
        .toList();

    if (_selectedZone == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a Zone / Area')),
      );
      return;
    }

    if (_selectedDriverId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a driver')),
      );
      return;
    }

    if (selectedPickupIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one pickup location')),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Route "$_generatedRouteName" assigned successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedZone = null;
        _selectedDriverId = null;
        for (var p in _pendingPickups) {
          p['selected'] = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F3FF),
      appBar: AppBar(
        title: const Text('Create & Assign Route',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF6A1B9A),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Select Zone Dropdown
            const Text('1. Select Collection Zone / Area',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedZone,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFF6A1B9A)),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              hint: const Text('Choose Target Zone'),
              items: _zones.map((zone) {
                return DropdownMenuItem<String>(value: zone, child: Text(zone));
              }).toList(),
              onChanged: (val) => setState(() => _selectedZone = val),
            ),
            const SizedBox(height: 16),

            // Select Shift
            const Text('2. Select Shift',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedShift,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.access_time, color: Color(0xFF6A1B9A)),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: _shifts.map((shift) {
                return DropdownMenuItem<String>(value: shift, child: Text(shift));
              }).toList(),
              onChanged: (val) => setState(() => _selectedShift = val!),
            ),
            const SizedBox(height: 16),

            // Generated Route Preview Box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6A1B9A).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF6A1B9A).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.alt_route, color: Color(0xFF6A1B9A)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Generated Route Name:',
                            style: TextStyle(fontSize: 11, color: Colors.grey)),
                        Text(
                          _generatedRouteName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Color(0xFF6A1B9A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Select Driver Dropdown
            const Text('3. Assign to Driver',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: _selectedDriverId,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.person, color: Color(0xFF6A1B9A)),
                fillColor: Colors.white,
                filled: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              hint: const Text('Choose Driver'),
              items: _drivers.map((driver) {
                return DropdownMenuItem<String>(
                  value: driver['id'],
                  child: Text(driver['name']!),
                );
              }).toList(),
              onChanged: (val) => setState(() => _selectedDriverId = val),
            ),
            const SizedBox(height: 16),

            // Schedule Date Picker
            const Text('4. Scheduled Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 6),
            InkWell(
              onTap: _presentDatePicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, color: Color(0xFF6A1B9A), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "${_selectedDate.toLocal()}".split(' ')[0],
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                    const Text('Change',
                        style: TextStyle(color: Color(0xFF6A1B9A), fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Select Pickups Section
            const Text('5. Select Pickup Requests',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pendingPickups.length,
              itemBuilder: (ctx, i) {
                final item = _pendingPickups[i];
                return Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300),
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: CheckboxListTile(
                    activeColor: const Color(0xFF6A1B9A),
                    title: Text(item['address'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    subtitle: Text('Waste Type: ${item['type']}'),
                    value: item['selected'],
                    onChanged: (val) {
                      setState(() {
                        item['selected'] = val;
                      });
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6A1B9A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isLoading ? null : _submitRoute,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Assign Route',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}