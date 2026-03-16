import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class SettingsHeader extends StatelessWidget {
  final VoidCallback onBackTap;

  const SettingsHeader({super.key, required this.onBackTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        BlobIconWrapper(
          size: 42,
          backgroundColor: AppColors.primary,
          child: InkWell(
            onTap: onBackTap,
            child: const Icon(AppIcons.back, color: AppColors.background),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Settings',
            style: context.textTheme.headlineSmall?.copyWith(
              fontFamily: 'Fredoka',
              color: AppColors.primary,
              fontWeight: .bold,
            ),
          ),
        ),
      ],
    );
  }
}
