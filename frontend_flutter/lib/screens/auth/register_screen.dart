import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../profile/map_picker_screen.dart';
import 'otp_verification_screen.dart';
import 'widgets/auth_button.dart';
import 'widgets/auth_text_field.dart';
import 'widgets/role_dropdown.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState
    extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController =
      TextEditingController();

  final emailController =
      TextEditingController();

  final passwordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  final phoneController =
      TextEditingController();

  final locationController =
      TextEditingController();

  final restaurantNameController =
      TextEditingController();

  String? selectedRole;
  LatLng? _selectedCoordinates;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    phoneController.dispose();
    locationController.dispose();
    restaurantNameController.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final authProvider =
        context.read<AuthProvider>();

    final success =
        await authProvider.register(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text,
      phone: phoneController.text.trim(),
      role: selectedRole!,
      location: locationController.text.trim(),
      locationCoordinates: _selectedCoordinates != null
          ? {
              'lat': _selectedCoordinates!.latitude,
              'lng': _selectedCoordinates!.longitude,
            }
          : null,
      restaurantName: selectedRole == 'restaurant_owner'
          ? restaurantNameController.text.trim()
          : null,
    );

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              OtpVerificationScreen(
            email: emailController.text.trim(),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            authProvider.error ??
                'Registration failed',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading =
        context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 20),

                const Icon(
                  Icons.recycling,
                  size: 70,
                ),

                const SizedBox(height: 20),

                const Text(
                  'Create your account',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                AuthTextField(
                  controller: nameController,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  icon: Icons.person,
                  validator: (value) =>
                      Validators.required(
                    value,
                    'Name',
                  ),
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  controller: emailController,
                  label: 'Email',
                  hint: 'Enter your email',
                  icon: Icons.email,
                  keyboardType:
                      TextInputType.emailAddress,
                  validator: Validators.email,
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  controller: passwordController,
                  label: 'Password',
                  hint: 'Enter password',
                  icon: Icons.lock,
                  obscureText: true,
                  validator:
                      Validators.password,
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  controller:
                      confirmPasswordController,
                  label: 'Confirm Password',
                  hint: 'Confirm password',
                  icon: Icons.lock_outline,
                  obscureText: true,
                  validator: (value) =>
                      Validators.confirmPassword(
                    value,
                    passwordController.text,
                  ),
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  controller: phoneController,
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  icon: Icons.phone,
                  keyboardType:
                      TextInputType.phone,
                  validator: (value) =>
                      Validators.required(
                    value,
                    'Phone number',
                  ),
                ),

                const SizedBox(height: 16),

                RoleDropdown(
                  value: selectedRole,
                  onChanged: (value) {
                    setState(() {
                      selectedRole = value;
                    });
                  },
                ),

                if (selectedRole == 'restaurant_owner') ...[
                  const SizedBox(height: 16),
                  AuthTextField(
                    controller: restaurantNameController,
                    label: 'Restaurant Name',
                    hint: 'Enter your restaurant name',
                    icon: Icons.restaurant,
                    validator: (value) =>
                        Validators.required(
                      value,
                      'Restaurant name',
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                AuthTextField(
                  controller: locationController,
                  label: selectedRole == 'restaurant_owner'
                      ? 'Restaurant Address'
                      : 'Living Address / Area',
                  hint: 'e.g. 142/A Kaduwela Road, Malabe',
                  icon: Icons.location_on,
                  validator: (value) =>
                      Validators.required(
                    value,
                    'Location',
                  ),
                ),

                const SizedBox(height: 12),

                // Interactive Map Location Picker
                InkWell(
                  onTap: () async {
                    final result = await Navigator.push<LatLng>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MapPickerScreen(
                          initialLat: _selectedCoordinates?.latitude,
                          initialLng: _selectedCoordinates?.longitude,
                        ),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _selectedCoordinates = result;
                        if (locationController.text.trim().isEmpty) {
                          locationController.text =
                              'Pinned (${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)})';
                        }
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedCoordinates != null
                          ? const Color(0xFFE8F5E9)
                          : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedCoordinates != null
                            ? const Color(0xFF2E7D32)
                            : Colors.grey.shade300,
                        width: _selectedCoordinates != null ? 1.8 : 1.0,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _selectedCoordinates != null
                              ? Icons.check_circle
                              : Icons.pin_drop_outlined,
                          color: _selectedCoordinates != null
                              ? const Color(0xFF2E7D32)
                              : const Color(0xFF1565C0),
                          size: 26,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedCoordinates != null
                                    ? 'Map Location Marked ✓'
                                    : (selectedRole == 'restaurant_owner'
                                        ? 'Mark Restaurant on Map'
                                        : 'Mark House on Map'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: _selectedCoordinates != null
                                      ? const Color(0xFF2E7D32)
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _selectedCoordinates != null
                                    ? '${_selectedCoordinates!.latitude.toStringAsFixed(5)}, ${_selectedCoordinates!.longitude.toStringAsFixed(5)}'
                                    : 'Tap to pinpoint on interactive map for waste routing',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _selectedCoordinates != null
                                      ? const Color(0xFF2E7D32)
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: _selectedCoordinates != null
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFF1565C0),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _selectedCoordinates != null ? 'Change' : 'Choose Map',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                AuthButton(
                  text: 'REGISTER',
                  loading: loading,
                  onPressed: _register,
                ),

                const SizedBox(height: 20),

                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Already have an account? Login',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}