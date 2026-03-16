import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class AppSettingTileContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;

  const AppSettingTileContainer({
    super.key,
    required this.child,
    this.margin,
    this.padding,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = AppRadii.md,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: AppSpacing.sm),
      padding:
          padding ??
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + AppSpacing.xxs,
            vertical: AppSpacing.sm + AppSpacing.xxs,
          ),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.background.withAlpha(170),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.primary.withAlpha(40),
        ),
      ),
      child: child,
    );
  }
}
