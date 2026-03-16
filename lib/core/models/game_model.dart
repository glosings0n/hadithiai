import 'riddle_model.dart';

class GameModel {
  final RiddleModel? currentRiddle;
  final int score;
  final int round;
  final bool tipUsedThisRound;
  final bool helpUsedThisRound;
  final String? selectedChoiceKey;
  final bool isAnswerLocked;
  final String statusMessage;
  final String? errorMessage;

  const GameModel({
    this.currentRiddle,
    this.score = 0,
    this.round = 1,
    this.tipUsedThisRound = false,
    this.helpUsedThisRound = false,
    this.selectedChoiceKey,
    this.isAnswerLocked = false,
    this.statusMessage = 'Ready for a brainy riddle challenge?',
    this.errorMessage,
  });

  static const initial = GameModel();

  GameModel copyWith({
    RiddleModel? currentRiddle,
    int? score,
    int? round,
    bool? tipUsedThisRound,
    bool? helpUsedThisRound,
    String? selectedChoiceKey,
    bool clearSelectedChoiceKey = false,
    bool? isAnswerLocked,
    String? statusMessage,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return GameModel(
      currentRiddle: currentRiddle ?? this.currentRiddle,
      score: score ?? this.score,
      round: round ?? this.round,
      tipUsedThisRound: tipUsedThisRound ?? this.tipUsedThisRound,
      helpUsedThisRound: helpUsedThisRound ?? this.helpUsedThisRound,
      selectedChoiceKey: clearSelectedChoiceKey
          ? null
          : selectedChoiceKey ?? this.selectedChoiceKey,
      isAnswerLocked: isAnswerLocked ?? this.isAnswerLocked,
      statusMessage: statusMessage ?? this.statusMessage,
      errorMessage: clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }
}
