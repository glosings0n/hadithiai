import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class AppPillChip extends StatelessWidget {
  final IconData? icon;
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double iconSize;
  final TextStyle? textStyle;

  const AppPillChip({
    super.key,
    this.icon,
    required this.label,
    this.backgroundColor = AppColors.background,
    this.foregroundColor = AppColors.textPrimary,
    this.borderColor,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    this.borderRadius = AppRadii.pill,
    this.iconSize = 14,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.primary.withAlpha(60),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: iconSize, color: foregroundColor),
            const SizedBox(width: AppSpacing.xs + AppSpacing.xxs),
          ],
          Text(
            label,
            style:
                textStyle ??
                TextStyle(
                  color: foregroundColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
          ),
        ],
      ),
    );
  }
}
