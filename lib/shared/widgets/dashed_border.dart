import 'package:flutter/widgets.dart';
import 'package:traccash/app/theme/app_spacing.dart';

/// Flutter has no dashed border, so the outline is drawn along a rounded
/// rectangle path. Used as a `foregroundPainter`.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final Radius radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    // Inset by half the stroke so the line sits inside the bounds.
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius((Offset.zero & size).deflate(0.5), radius),
      );
    for (final metric in outline.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(distance, distance + AppSizes.dash),
          paint,
        );
        distance += AppSizes.dash + AppSizes.dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
