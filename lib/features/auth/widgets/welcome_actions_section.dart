import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class WelcomeActionsSection extends StatelessWidget {
  final VoidCallback onGetStarted;

  const WelcomeActionsSection({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 24,
      children: [
        MainAppButton(
          text: 'Get Started',
          color: AppColors.primary,
          onTap: onGetStarted,
        ),
        const Icon(AppIcons.share, color: AppColors.primary),
      ],
    );
  }
}
