import 'package:flutter/material.dart';
import '../../../models/pickup_model.dart';

class ScheduleTimelineItem extends StatelessWidget {
  final PickupModel pickup;
  final bool isLast;
  final VoidCallback onTap;

  const ScheduleTimelineItem({
    super.key,
    required this.pickup,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = pickup.status == 'completed';
    final isAccepted = pickup.status == 'accepted';

    Color nodeColor;
    Widget nodeIcon;

    if (isCompleted) {
      nodeColor = const Color(0xFF22C55E); // Green
      nodeIcon = const Icon(Icons.check, size: 16, color: Colors.white);
    } else if (isAccepted) {
      nodeColor = const Color(0xFF2563EB); // Blue
      nodeIcon = const Icon(Icons.arrow_forward, size: 15, color: Colors.white);
    } else {
      nodeColor = const Color(0xFF94A3B8); // Grey
      nodeIcon = const Icon(Icons.access_time_filled, size: 15, color: Colors.white);
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Time Column
          SizedBox(
            width: 70,
            child: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                pickup.scheduledTime,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Node and Vertical Line
          Column(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: nodeColor,
                  shape: BoxShape.circle,
                ),
                child: Center(child: nodeIcon),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.5,
                    color: isCompleted ? const Color(0xFF60A5FA) : const Color(0xFFCBD5E1),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // 3. Right Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: onTap,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFF1F5F2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickup.status == 'accepted'
                            ? 'Accepted'
                            : pickup.status[0].toUpperCase() + pickup.status.substring(1),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pickup ${pickup.pickupNumber}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pickup.customerName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D2818),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pickup.wasteType,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pickup.weightKg.toInt()} kg',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}