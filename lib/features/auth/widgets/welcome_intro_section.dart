import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:intl/intl.dart';

class WelcomeIntroSection extends StatelessWidget {
  const WelcomeIntroSection({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, d MMMM y').format(now);

    final textTheme = context.textTheme;

    return Column(
      children: [
        Text(
          'HadithiAI',
          style: textTheme.displaySmall?.copyWith(
            fontFamily: 'Hanalei',
            color: AppColors.primary,
            fontWeight: .bold,
            fontSize: 60,
          ),
        ),
        Text(
          '${now.day}',
          style: textTheme.displaySmall?.copyWith(
            fontFamily: 'Hanalei',
            color: AppColors.primary,
            fontWeight: .bold,
            fontSize: 120,
          ),
        ),
        Text(
          formattedDate,
          style: textTheme.headlineSmall?.copyWith(
            fontFamily: 'Hanalei',
            color: AppColors.primary.withAlpha(200),
          ),
          textAlign: .center,
        ),
        const SizedBox(height: 8),
        Text(
          'Stay consistent and keep your reading streak alive!',
          style: textTheme.bodyMedium,
          textAlign: .center,
        ),
      ],
    );
  }
}
