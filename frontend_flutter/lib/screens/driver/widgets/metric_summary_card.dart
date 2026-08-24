import 'package:flutter/material.dart';

/// A compact, tappable summary metric used on the driver dashboard.
class MetricSummaryCard extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final int count;
  final VoidCallback? onTap;

  const MetricSummaryCard({
    super.key,
    required this.iconWidget,
    required this.title,
    required this.count,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeCount = count.clamp(0, 999999);

    return Semantics(
      button: onTap != null,
      label: '$title: $safeCount',
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 126,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1F5F2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 26, child: Center(child: iconWidget)),
                const Spacer(),
                Text(
                  '$safeCount',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF0D2818),
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
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
