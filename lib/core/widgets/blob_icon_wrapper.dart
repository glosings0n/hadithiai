import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class BlobIconWrapper extends StatelessWidget {
  final Widget child;
  final double size;
  final Color backgroundColor;

  const BlobIconWrapper({
    super.key,
    required this.child,
    required this.backgroundColor,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Custom organic background shape.
          CustomPaint(
            size: Size(size, size),
            painter: _BlobPainter(color: backgroundColor),
          ),
          // Icon/image content on top.
          child,
        ],
      ),
    );
  }
}

/// Painter that draws the soft organic blob shape.
class _BlobPainter extends CustomPainter {
  final Color color;

  _BlobPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    final w = size.width;
    final h = size.height;

    // Build the organic shape with cubic Bezier curves.
    // Control points are tuned for a slightly tilted, irregular silhouette.

    path.moveTo(w * 0.5, h * 0.05); // Top point (slightly offset).

    // Curve to the right (rounded, not perfectly circular).
    path.cubicTo(
      w * 0.85,
      h * 0.02, // Control point 1.
      w * 0.98,
      h * 0.35, // Control point 2.
      w * 0.92,
      h * 0.60, // End point (lower right).
    );

    // Curve down (slightly flattened shape).
    path.cubicTo(
      w * 0.88,
      h * 0.85,
      w * 0.65,
      h * 0.98,
      w * 0.45,
      h * 0.95, // End point (lower left).
    );

    // Curve to the left (smooth rise).
    path.cubicTo(
      w * 0.15,
      h * 0.90,
      w * 0.02,
      h * 0.65,
      w * 0.08,
      h * 0.40, // End point (upper left).
    );

    // Close the shape back to the starting point.
    path.cubicTo(
      w * 0.12,
      h * 0.15,
      w * 0.30,
      h * 0.08,
      w * 0.5,
      h * 0.05, // Back to start.
    );

    path.close();

    // Optional: slight rotation for a hand-placed feel.
    canvas.save();
    canvas.translate(w / 2, h / 2);
    canvas.rotate(-math.pi / 12); // Rotate by -15 degrees.
    canvas.translate(-w / 2, -h / 2);

    canvas.drawPath(path, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false; // No repaint needed for a static shape.
  }
}
