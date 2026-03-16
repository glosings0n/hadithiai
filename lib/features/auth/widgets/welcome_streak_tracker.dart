import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class WelcomeStreakTracker extends StatelessWidget {
  const WelcomeStreakTracker({super.key});

  @override
  Widget build(BuildContext context) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final todayWeekday = DateTime.now().weekday;

    return Row(
      mainAxisAlignment: .spaceBetween,
      children: List.generate(days.length, (index) {
        final dayNumber = index + 1;
        final isPastDay = dayNumber < todayWeekday;
        final isToday = dayNumber == todayWeekday;

        return Column(
          spacing: 8,
          children: [
            Text(
              days[index],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.primary.withAlpha(200),
              ),
            ),
            if (isPastDay)
              const Icon(AppIcons.check, color: AppColors.primary)
            else if (isToday)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withAlpha(120),
                    width: 1.5,
                  ),
                  color: AppColors.primary.withAlpha(100),
                ),
                padding: const EdgeInsets.all(2),
                child: Image.asset(AppImages.logo, fit: .contain),
              )
            else
              Icon(
                AppIcons.circle,
                color: AppColors.textSecondary.withAlpha(77),
              ),
          ],
        );
      }),
    );
  }
}
