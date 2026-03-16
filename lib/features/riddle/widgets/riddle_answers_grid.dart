import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

class RiddleAnswersGrid extends StatelessWidget {
  final RiddleLoadState state;
  final List<Map<String, bool>> choices;
  final String? selectedChoiceKey;
  final bool isAnswerLocked;
  final ValueChanged<String> onSelectAnswer;

  const RiddleAnswersGrid({
    super.key,
    required this.state,
    required this.choices,
    required this.selectedChoiceKey,
    required this.isAnswerLocked,
    required this.onSelectAnswer,
  });

  static const List<Color> _choiceColors = <Color>[
    Color(0xFFEFAE58),
    Color(0xFF89A7E0),
    Color(0xFF8BC37A),
    Color(0xFFD18AC5),
  ];

  @override
  Widget build(BuildContext context) {
    if (choices.isEmpty || state != RiddleLoadState.ready) {
      return const SizedBox.shrink();
    }

    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: choices.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.05,
      ),
      itemBuilder: (context, index) {
        final choice = choices[index];
        final choiceKey = choice.keys.first;
        final isCorrect = choice.values.first;
        final isSelected = selectedChoiceKey == choiceKey;
        final isCorrectReveal = isAnswerLocked && isCorrect;
        final isWrongReveal = isAnswerLocked && isSelected && !isCorrect;

        final cardColor = isCorrectReveal
            ? AppColors.success
            : isWrongReveal
            ? AppColors.error
            : _choiceColors[index % _choiceColors.length];

        return MainGridCard(
          label: choiceKey,
          icon: isCorrectReveal
              ? AppIcons.check
              : isWrongReveal
              ? AppIcons.close
              : AppIcons.puzzle,
          iconSize: 34,
          iconColor: AppColors.background,
          backgroundColor: cardColor,
          onTap: () => onSelectAnswer(choiceKey),
        );
      },
    );
  }
}
