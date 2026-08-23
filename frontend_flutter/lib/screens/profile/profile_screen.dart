import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/profile_service.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ProfileService _service = ProfileService();
  UserModel? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final profile = await _service.getProfile();
      setState(() => _profile = profile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      setState(() => _loading = false);
    }
  }

  String _roleLabel(String role) {
    final map = {
      'neighbour': 'Neighbour',
      'restaurant_owner': 'Restaurant Owner',
      'driver': 'Driver',
      'recycling_manager': 'Recycling Manager',
    };
    return map[role] ?? role;
  }

  Color _roleColor(String role) {
    final map = {
      'neighbour': const Color(0xFF2E7D32),
      'restaurant_owner': const Color(0xFFE65100),
      'driver': const Color(0xFF1565C0),
      'recycling_manager': const Color(0xFF6A1B9A),
    };
    return map[role] ?? Colors.grey;
  }

  IconData _roleIcon(String role) {
    final map = {
      'neighbour': Icons.home,
      'restaurant_owner': Icons.restaurant,
      'driver': Icons.local_shipping,
      'recycling_manager': Icons.recycling,
    };
    return map[role] ?? Icons.person;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        title: const Text('My Profile',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _profile == null
                ? null
                : () async {
                    final updated = await Navigator.push<UserModel>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            EditProfileScreen(profile: _profile!),
                      ),
                    );
                    if (updated != null) {
                      setState(() => _profile = updated);
                    }
                  },
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E7D32)))
          : _profile == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Unable to load profile'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                          onPressed: _load, child: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  color: const Color(0xFF2E7D32),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        // Header
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _roleColor(_profile!.role),
                                _roleColor(_profile!.role).withAlpha(200),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Avatar
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: Colors.white, width: 3),
                                  color: Colors.white.withAlpha(50),
                                ),
                                child: _profile!.profilePicture != null
                                    ? ClipOval(
                                        child: Image.network(
                                          _profile!.profilePicture!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              _avatarPlaceholder(
                                                  _profile!.name),
                                        ),
                                      )
                                    : _avatarPlaceholder(_profile!.name),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _profile!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _roleIcon(_profile!.role),
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _roleLabel(_profile!.role),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 14),
                                  ),
                                ],
                              ),
                              if (_profile!.bio != null &&
                                  _profile!.bio!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _profile!.bio!,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 13),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Info cards
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _infoCard(
                                'Contact Information',
                                Icons.contact_mail,
                                [
                                  _infoRow(Icons.email, 'Email',
                                      _profile!.email),
                                  if (_profile!.phone != null &&
                                      _profile!.phone!.isNotEmpty)
                                    _infoRow(Icons.phone, 'Phone',
                                        _profile!.phone!),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (_profile!.location != null &&
                                  _profile!.location!.isNotEmpty)
                                _infoCard(
                                  'Location',
                                  Icons.location_on,
                                  [
                                    _infoRow(Icons.place, 'Address',
                                        _profile!.location!),
                                    if (_profile!.locationCoordinates?.lat !=
                                            null &&
                                        (_profile!.role == 'neighbour' ||
                                            _profile!.role ==
                                                'restaurant_owner'))
                                      _infoRow(
                                        Icons.map,
                                        'Coordinates',
                                        '${_profile!.locationCoordinates!.lat!.toStringAsFixed(5)}, ${_profile!.locationCoordinates!.lng!.toStringAsFixed(5)}',
                                      ),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              // Role-specific info
                              if (_profile!.role == 'restaurant_owner' &&
                                  (_profile!.restaurantName?.isNotEmpty ??
                                      false))
                                _infoCard(
                                  'Restaurant Info',
                                  Icons.restaurant,
                                  [
                                    _infoRow(Icons.storefront, 'Name',
                                        _profile!.restaurantName!),
                                    if (_profile!.restaurantAddress
                                            ?.isNotEmpty ??
                                        false)
                                      _infoRow(Icons.location_on, 'Address',
                                          _profile!.restaurantAddress!),
                                  ],
                                ),
                              if (_profile!.role == 'driver' &&
                                  (_profile!.vehicleType?.isNotEmpty ?? false))
                                _infoCard(
                                  'Driver Info',
                                  Icons.local_shipping,
                                  [
                                    _infoRow(Icons.directions_car,
                                        'Vehicle Type', _profile!.vehicleType!),
                                    if (_profile!.licenseNumber?.isNotEmpty ??
                                        false)
                                      _infoRow(Icons.badge, 'License Number',
                                          _profile!.licenseNumber!),
                                  ],
                                ),
                              const SizedBox(height: 12),
                              // Logout
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  icon: const Icon(Icons.logout,
                                      color: Colors.red),
                                  label: const Text('Logout',
                                      style: TextStyle(color: Colors.red)),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.red),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    await context
                                        .read<AuthProvider>()
                                        .logout();
                                    if (mounted) {
                                      Navigator.pushNamedAndRemoveUntil(
                                          context, '/login', (r) => false);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _avatarPlaceholder(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 36,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF2E7D32), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
