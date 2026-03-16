import 'dart:ui';
import 'package:flutter/material.dart';

class GlassmorphicContainer extends StatelessWidget {
  final double width;
  final double height;
  final Widget child;
  final double borderRadius;
  final double blur;
  final Color color;
  final double opacity;

  const GlassmorphicContainer({
    super.key,
    required this.width,
    required this.height,
    required this.child,
    this.borderRadius = 20.0,
    this.blur = 10.0,
    this.color = Colors.white,
    this.opacity = 0.2,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: color.withAlpha((opacity * 255).round()),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withAlpha(51),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
