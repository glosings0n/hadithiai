import 'package:hadithi_ai/core/core.dart';
import 'package:hadithi_ai/features/host/host_screen.dart';
import 'package:flutter/material.dart';

import 'widgets/welcome_actions_section.dart';
import 'widgets/welcome_intro_section.dart';
import 'widgets/welcome_streak_tracker.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: .center,
          crossAxisAlignment: .center,
          children: [
            const Spacer(flex: 2),
            const WelcomeIntroSection(),
            const SizedBox(height: 32),
            const WelcomeStreakTracker(),
            const SizedBox(height: 16),
            Text(
              "If you don't read one day, you may lose your streak.",
              style: context.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary.withAlpha(150),
              ),
              textAlign: TextAlign.center,
            ),
            const Spacer(flex: 2),
            WelcomeActionsSection(
              onGetStarted: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HostScreen()),
                (_) => false,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
