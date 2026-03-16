import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class SettingsSectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<Widget> children;

  const SettingsSectionCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphicCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md + AppSpacing.xxs),
      borderRadius: AppRadii.xl,
      boxShadow: AppShadows.soft(color: AppColors.primary, opacity: 0.06),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            title,
            style: context.textTheme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: context.textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + AppSpacing.xxs),
          ...children,
        ],
      ),
    );
  }
}
