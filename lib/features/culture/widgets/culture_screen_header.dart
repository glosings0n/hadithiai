import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class CultureScreenHeader extends StatelessWidget {
  final VoidCallback onBackTap;

  const CultureScreenHeader({super.key, required this.onBackTap});

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
            'Cultural Grounding',
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
