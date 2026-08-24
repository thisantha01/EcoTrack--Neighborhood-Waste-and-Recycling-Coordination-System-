import 'package:flutter/material.dart';

class DriverHeader extends StatelessWidget {
  final String driverName;
  final String subtitle;
  final bool isAvailable;
  final VoidCallback onToggleAvailability;

  const DriverHeader({
    super.key,
    required this.driverName,
    this.subtitle = "Ready for today's collection?",
    required this.isAvailable,
    required this.onToggleAvailability,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Color(0xFFD7EEDB),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good Morning, $driverName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0D2818),
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF4A6B53),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Semantics(
            button: true,
            label: isAvailable ? 'Set off duty' : 'Set available',
            child: GestureDetector(
              onTap: onToggleAvailability,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 58,
                    height: 32,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: isAvailable ? const Color(0xFF2E7D32) : const Color(0xFFB0BEC5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Align(
                      alignment: isAvailable ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isAvailable ? 'Available' : 'Off Duty',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1B4329),
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
