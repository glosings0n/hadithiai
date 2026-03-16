import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:hadithi_ai/features/riddle/widgets/riddle_status_pill.dart';

class RiddleTopBar extends StatelessWidget {
  final int score;
  final int round;
  final bool showLiveBadge;

  const RiddleTopBar({
    super.key,
    required this.score,
    required this.round,
    required this.showLiveBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: BlobIconWrapper(
            size: 46,
            backgroundColor: AppColors.primary,
            child: const Icon(AppIcons.back, color: AppColors.background),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              RiddleStatusPill(
                icon: AppIcons.star,
                text: '$score pts',
                background: AppColors.warning.withAlpha(70),
              ),
              RiddleStatusPill(
                icon: AppIcons.target,
                text: 'Round $round',
                background: AppColors.primary.withAlpha(55),
              ),
              if (showLiveBadge)
                RiddleStatusPill(
                  icon: AppIcons.live,
                  text: 'Live',
                  background: AppColors.success.withAlpha(70),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
