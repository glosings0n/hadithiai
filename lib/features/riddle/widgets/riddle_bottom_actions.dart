import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:hadithi_ai/features/riddle/widgets/riddle_action_button.dart';

class RiddleBottomActions extends StatelessWidget {
  final bool tipUsedThisRound;
  final bool helpUsedThisRound;
  final bool canUseTip;
  final bool canUseHelp;
  final bool canGoNext;
  final VoidCallback onTip;
  final VoidCallback onHelp;
  final VoidCallback onNext;

  const RiddleBottomActions({
    super.key,
    required this.tipUsedThisRound,
    required this.helpUsedThisRound,
    required this.canUseTip,
    required this.canUseHelp,
    required this.canGoNext,
    required this.onTip,
    required this.onHelp,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: RiddleActionButton(
            icon: AppIcons.lightBulb,
            text: tipUsedThisRound ? 'Tip Used' : 'Tip (-1)',
            color: canUseTip
                ? AppColors.warning
                : AppColors.textSecondary.withAlpha(120),
            enabled: canUseTip,
            onTap: onTip,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RiddleActionButton(
            icon: AppIcons.help,
            text: helpUsedThisRound ? 'Help Used' : 'Help (-1)',
            color: canUseHelp
                ? AppColors.secondary
                : AppColors.textSecondary.withAlpha(120),
            enabled: canUseHelp,
            onTap: onHelp,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RiddleActionButton(
            icon: AppIcons.next,
            text: 'Next',
            color: AppColors.primary,
            enabled: canGoNext,
            onTap: onNext,
          ),
        ),
      ],
    );
  }
}
