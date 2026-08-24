import 'package:flutter/material.dart';
import 'route_map_painter.dart';

class RouteProgressCard extends StatelessWidget {
  final int completedStops;
  final int totalStops;
  final VoidCallback onViewRoute;

  const RouteProgressCard({
    super.key,
    required this.completedStops,
    required this.totalStops,
    required this.onViewRoute,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalStops > 0 ? (completedStops / totalStops).clamp(0.0, 1.0) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title & Stop Counter
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Current Route',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0D2818),
              ),
            ),
            Text(
              '$completedStops/$totalStops stops',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Green Progress Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 9,
            backgroundColor: const Color(0xFFE2EBE5),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2E7D32)),
          ),
        ),
        const SizedBox(height: 12),

        // Route Graphic Box
        Container(
          height: 118,
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8E4)),
          ),
          child: CustomPaint(
            painter: RouteMapPainter(
              completedStops: completedStops,
              totalStops: totalStops,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // View Route Button
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: onViewRoute,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: const Text(
              'View Route',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}