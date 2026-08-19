import 'package:flutter/material.dart';

import '../../../utils/constants.dart';

class RoleDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;

  const RoleDropdown({
    super.key,
    required this.value,
    required this.onChanged,
  });

  String _displayName(String role) {
    switch (role) {
      case AppConstants.neighbour:
        return 'Neighbour';

      case AppConstants.restaurantOwner:
        return 'Restaurant Owner';

      case AppConstants.driver:
        return 'Garbage Collection Driver';

      case AppConstants.recyclingManager:
        return 'Recycling Center Manager';

      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: 'Select Role',
        prefixIcon: const Icon(
          Icons.person_outline,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: AppConstants.roles.map(
        (role) {
          return DropdownMenuItem<String>(
            value: role,
            child: Text(
              _displayName(role),
            ),
          );
        },
      ).toList(),
      onChanged: onChanged,
      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return 'Please select a role';
        }

        return null;
      },
    );
  }
}