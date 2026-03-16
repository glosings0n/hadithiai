import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/styles/app_colors.dart';

class AppSpacing {
  static const double xxs = 2;
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;

  static const EdgeInsets screenPadding = EdgeInsets.fromLTRB(
    AppSpacing.xl,
    AppSpacing.md,
    AppSpacing.xl,
    AppSpacing.md,
  );
}

class AppRadii {
  static const double sm = 10;
  static const double md = 14;
  static const double lg = 20;
  static const double xl = 24;
  static const double pill = 999;
}

class AppShadows {
  static List<BoxShadow> soft({
    Color color = AppColors.textPrimary,
    double opacity = 0.08,
    double blurRadius = 12,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 4),
  }) {
    return [
      BoxShadow(
        color: color.withAlpha((255 * opacity).round()),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
    ];
  }

  static List<BoxShadow> glow({
    Color color = AppColors.primary,
    double opacity = 0.14,
    double blurRadius = 18,
    double spreadRadius = 1,
  }) {
    return [
      BoxShadow(
        color: color.withAlpha((255 * opacity).round()),
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
      ),
    ];
  }
}
