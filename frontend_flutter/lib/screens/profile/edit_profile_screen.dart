import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../models/user_model.dart';
import '../../services/profile_service.dart';
import 'map_picker_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel profile;

  const EditProfileScreen({super.key, required this.profile});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _service = ProfileService();
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _locationCtrl;
  late TextEditingController _restaurantNameCtrl;
  late TextEditingController _restaurantAddressCtrl;
  late TextEditingController _licenseCtrl;
  late TextEditingController _vehicleCtrl;

  LatLng? _selectedCoords;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _nameCtrl = TextEditingController(text: p.name);
    _phoneCtrl = TextEditingController(text: p.phone ?? '');
    _bioCtrl = TextEditingController(text: p.bio ?? '');
    _locationCtrl = TextEditingController(text: p.location ?? '');
    _restaurantNameCtrl =
        TextEditingController(text: p.restaurantName ?? '');
    _restaurantAddressCtrl =
        TextEditingController(text: p.restaurantAddress ?? '');
    _licenseCtrl = TextEditingController(text: p.licenseNumber ?? '');
    _vehicleCtrl = TextEditingController(text: p.vehicleType ?? '');

    if (p.locationCoordinates?.lat != null &&
        p.locationCoordinates?.lng != null) {
      _selectedCoords = LatLng(
        p.locationCoordinates!.lat!,
        p.locationCoordinates!.lng!,
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _bioCtrl.dispose();
    _locationCtrl.dispose();
    _restaurantNameCtrl.dispose();
    _restaurantAddressCtrl.dispose();
    _licenseCtrl.dispose();
    _vehicleCtrl.dispose();
    super.dispose();
  }

  bool get _needsMapPicker =>
      widget.profile.role == 'neighbour' ||
      widget.profile.role == 'restaurant_owner';

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final updated = await _service.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        locationCoordinates: _selectedCoords != null
            ? {
                'lat': _selectedCoords!.latitude,
                'lng': _selectedCoords!.longitude,
              }
            : null,
        restaurantName: _restaurantNameCtrl.text.trim().isNotEmpty
            ? _restaurantNameCtrl.text.trim()
            : null,
        restaurantAddress: _restaurantAddressCtrl.text.trim().isNotEmpty
            ? _restaurantAddressCtrl.text.trim()
            : null,
        licenseNumber: _licenseCtrl.text.trim().isNotEmpty
            ? _licenseCtrl.text.trim()
            : null,
        vehicleType: _vehicleCtrl.text.trim().isNotEmpty
            ? _vehicleCtrl.text.trim()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF2E7D32),
          ),
        );
        Navigator.pop(context, updated);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _loading ? null : _save,
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionHeader('Basic Information'),
              const SizedBox(height: 12),
              _buildField(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _phoneCtrl,
                label: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 12),
              _buildField(
                controller: _bioCtrl,
                label: 'Bio (optional)',
                icon: Icons.info_outline,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              _sectionHeader('Location'),
              const SizedBox(height: 12),
              _buildField(
                controller: _locationCtrl,
                label: 'Address / Area',
                icon: Icons.location_on,
              ),
              if (_needsMapPicker) ...[
                const SizedBox(height: 12),
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLat: _selectedCoords?.latitude,
                          initialLng: _selectedCoords?.longitude,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() => _selectedCoords = result);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: _selectedCoords != null
                            ? const Color(0xFF2E7D32)
                            : Colors.grey,
                        width: _selectedCoords != null ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.map,
                          color: _selectedCoords != null
                              ? const Color(0xFF2E7D32)
                              : Colors.grey,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Exact Location on Map',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500),
                              ),
                              Text(
                                _selectedCoords != null
                                    ? '${_selectedCoords!.latitude.toStringAsFixed(5)}, ${_selectedCoords!.longitude.toStringAsFixed(5)}'
                                    : 'Tap to select on map',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _selectedCoords != null
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              ],
              // Role-specific fields
              if (widget.profile.role == 'restaurant_owner') ...[
                const SizedBox(height: 24),
                _sectionHeader('Restaurant Information'),
                const SizedBox(height: 12),
                _buildField(
                  controller: _restaurantNameCtrl,
                  label: 'Restaurant Name',
                  icon: Icons.restaurant,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _restaurantAddressCtrl,
                  label: 'Restaurant Address',
                  icon: Icons.location_city,
                ),
              ],
              if (widget.profile.role == 'driver') ...[
                const SizedBox(height: 24),
                _sectionHeader('Driver Information'),
                const SizedBox(height: 12),
                _buildField(
                  controller: _vehicleCtrl,
                  label: 'Vehicle Type',
                  icon: Icons.local_shipping,
                ),
                const SizedBox(height: 12),
                _buildField(
                  controller: _licenseCtrl,
                  label: 'License Number',
                  icon: Icons.badge,
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _loading ? null : _save,
                  child: _loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF2E7D32),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }
}
