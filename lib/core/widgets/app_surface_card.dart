import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class AppSurfaceCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final double borderRadius;
  final bool useGlass;
  final double blurSigmaX;
  final double blurSigmaY;
  final List<BoxShadow>? boxShadow;

  const AppSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.color,
    this.borderColor,
    this.borderWidth = 1,
    this.borderRadius = AppRadii.xl,
    this.useGlass = true,
    this.blurSigmaX = 10,
    this.blurSigmaY = 10,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final decoration = BoxDecoration(
      color: color ?? AppColors.glassmorphismColor,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: borderColor ?? Colors.white.withAlpha(51),
        width: borderWidth,
      ),
      boxShadow: boxShadow,
    );

    Widget cardContent = Container(
      padding: padding,
      decoration: decoration,
      child: child,
    );

    if (useGlass) {
      cardContent = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigmaX, sigmaY: blurSigmaY),
        child: cardContent,
      );
    }

    cardContent = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: cardContent,
    );

    if (onTap != null) {
      cardContent = GestureDetector(onTap: onTap, child: cardContent);
    }

    if (margin != null) {
      return Container(margin: margin, child: cardContent);
    }

    return cardContent;
  }
}
