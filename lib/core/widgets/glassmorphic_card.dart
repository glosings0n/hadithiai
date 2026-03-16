import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double borderRadius;
  final double blurSigmaX;
  final double blurSigmaY;
  final List<BoxShadow>? boxShadow;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.color,
    this.borderColor,
    this.borderRadius = AppRadii.xl,
    this.blurSigmaX = 10,
    this.blurSigmaY = 10,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      onTap: onTap,
      margin: margin,
      padding: padding,
      color: color ?? AppColors.glassmorphismColor,
      borderColor: borderColor,
      borderRadius: borderRadius,
      blurSigmaX: blurSigmaX,
      blurSigmaY: blurSigmaY,
      boxShadow: boxShadow,
      child: child,
    );
  }
}
