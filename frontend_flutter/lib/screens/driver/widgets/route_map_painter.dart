import 'package:flutter/material.dart';

class RouteMapPainter extends CustomPainter {
  final int completedStops;
  final int totalStops;

  RouteMapPainter({
    required this.completedStops,
    required this.totalStops,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 5 waypoints relative to container size
    final List<Offset> points = [
      Offset(size.width * 0.18, size.height * 0.50),
      Offset(size.width * 0.35, size.height * 0.72),
      Offset(size.width * 0.50, size.height * 0.30),
      Offset(size.width * 0.65, size.height * 0.74),
      Offset(size.width * 0.82, size.height * 0.38),
    ];

    // Background road grey line
    final greyPaint = Paint()
      ..color = const Color(0xFF8FA395)
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final roadPath = Path();
    roadPath.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      roadPath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(roadPath, greyPaint);

    // Completed green road line
    final greenPaint = Paint()
      ..color = const Color(0xFF2E7D32)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final completedPath = Path();
    completedPath.moveTo(points[0].dx, points[0].dy);
    final limit = completedStops.clamp(1, points.length);
    for (int i = 1; i < limit; i++) {
      completedPath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(completedPath, greenPaint);

    // Draw Pin Heads
    for (int i = 0; i < points.length; i++) {
      final pt = points[i];
      final isDone = i < completedStops;
      final pinColor = isDone ? const Color(0xFF2E7D32) : const Color(0xFF4A6B53);

      // Shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(pt.dx, pt.dy + 10), width: 12, height: 5),
        Paint()..color = Colors.black.withValues(alpha: 0.15),
      );

      // Pin Circle
      canvas.drawCircle(pt, 9, Paint()..color = pinColor);
      canvas.drawCircle(pt, 9, Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 2);

      // Inner center dot
      canvas.drawCircle(pt, 3.5, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant RouteMapPainter oldDelegate) =>
      oldDelegate.completedStops != completedStops ||
      oldDelegate.totalStops != totalStops;
}