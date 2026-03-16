import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class RiddleStatusPill extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color background;

  const RiddleStatusPill({
    super.key,
    required this.icon,
    required this.text,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return AppPillChip(
      icon: icon,
      label: text,
      backgroundColor: background,
      foregroundColor: AppColors.textPrimary,
      borderColor: AppColors.primary.withAlpha(60),
      iconSize: 14,
      textStyle: const TextStyle(
        color: AppColors.textPrimary,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm + AppSpacing.xxs,
        vertical: AppSpacing.sm,
      ),
    );
  }
}
