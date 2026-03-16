import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:hadithi_ai/features/riddle/widgets/riddle_answers_grid.dart';
import 'package:hadithi_ai/features/riddle/widgets/riddle_bottom_actions.dart';
import 'package:hadithi_ai/features/riddle/widgets/riddle_loading_shimmer.dart';
import 'package:hadithi_ai/features/riddle/widgets/riddle_question_panel.dart';
import 'package:hadithi_ai/features/riddle/widgets/riddle_top_bar.dart';
import 'package:provider/provider.dart';

class RiddleScreen extends StatelessWidget {
  const RiddleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RiddleProvider>(
      builder: (context, provider, _) {
        return AppScaffold(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  RiddleTopBar(
                    score: provider.score,
                    round: provider.round,
                    showLiveBadge:
                        provider.currentQuestion?.showLiveBadge == true,
                  ),
                  const SizedBox(height: 16),
                  if (provider.state == RiddleLoadState.loading)
                    const Expanded(child: RiddleLoadingShimmer())
                  else ...[
                    RiddleQuestionPanel(
                      state: provider.state,
                      question: provider.currentQuestion?.question,
                      statusMessage: provider.statusMessage,
                      errorMessage: provider.errorMessage,
                      onRetry: provider.retry,
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: RiddleAnswersGrid(
                        state: provider.state,
                        choices:
                            provider.currentQuestion?.choices ??
                            const <Map<String, bool>>[],
                        selectedChoiceKey: provider.selectedChoiceKey,
                        isAnswerLocked: provider.isAnswerLocked,
                        onSelectAnswer: provider.selectAnswer,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  RiddleBottomActions(
                    tipUsedThisRound: provider.tipUsedThisRound,
                    helpUsedThisRound: provider.helpUsedThisRound,
                    canUseTip:
                        provider.state != RiddleLoadState.loading &&
                        provider.canUseTip,
                    canUseHelp:
                        provider.state != RiddleLoadState.loading &&
                        provider.canUseHelp,
                    canGoNext:
                        provider.state != RiddleLoadState.loading &&
                        !provider.isCheckingAnswer,
                    onTip: provider.useTip,
                    onHelp: provider.useHelp,
                    onNext: provider.loadNextQuestion,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
