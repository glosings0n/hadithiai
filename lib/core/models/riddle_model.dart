class RiddleModel {
  final String id;
  final String question;
  final List<Map<String, bool>> choices;
  final String? tip;
  final String? help;
  final String? language;
  final bool showLiveBadge;

  const RiddleModel({
    required this.id,
    required this.question,
    required this.choices,
    this.tip,
    this.help,
    this.language,
    this.showLiveBadge = true,
  });

  bool get hasTip => tip != null && tip!.trim().isNotEmpty;
  bool get hasHelp => help != null && help!.trim().isNotEmpty;
  bool get hasChoices => choices.isNotEmpty;
  bool get hasSingleCorrectChoice =>
      choices.where((choice) => choice.values.firstOrNull == true).length == 1;

  Map<String, bool>? get correctChoice {
    for (final choice in choices) {
      if (choice.values.firstOrNull == true) return choice;
    }
    return null;
  }

  String? get correctAnswerText => correctChoice?.keys.firstOrNull;

  String get tipMessage =>
      hasTip ? 'Tip: ${tip!.trim()}' : 'Tip used: think in practical terms.';

  String get helpMessage => hasHelp
      ? 'Help: ${help!.trim()}'
      : 'Help used: eliminate impossible answers first.';

  RiddleModel copyWith({
    String? id,
    String? question,
    List<Map<String, bool>>? choices,
    String? tip,
    String? help,
    String? language,
    bool? showLiveBadge,
  }) {
    return RiddleModel(
      id: id ?? this.id,
      question: question ?? this.question,
      choices: choices ?? this.choices,
      tip: tip ?? this.tip,
      help: help ?? this.help,
      language: language ?? this.language,
      showLiveBadge: showLiveBadge ?? this.showLiveBadge,
    );
  }

  static RiddleModel? fromApiPayload(
    Map<String, dynamic> payload, {
    required String fallbackId,
  }) {
    final questionText = _extractQuestion(payload);
    final parsedChoices = _parseChoices(payload);

    if (questionText == null || questionText.isEmpty || parsedChoices == null) {
      return null;
    }

    return RiddleModel(
      id: (payload['id'] ?? payload['question_id'] ?? fallbackId).toString(),
      question: questionText,
      choices: parsedChoices,
      tip: _asNonEmptyString(payload['tip'] ?? payload['hint']),
      help: _asNonEmptyString(payload['help'] ?? payload['explanation']),
      language: _asNonEmptyString(payload['language']),
      showLiveBadge:
          (payload['live'] ?? payload['show_live_badge'] ?? true) == true,
    );
  }

  static String? _extractQuestion(Map<String, dynamic> payload) {
    return _asNonEmptyString(
      payload['question'] ?? payload['prompt'] ?? payload['riddle'],
    );
  }

  static List<Map<String, bool>>? _parseChoices(Map<String, dynamic> payload) {
    final answersRaw =
        payload['answers'] ?? payload['options'] ?? payload['choices'];

    if (answersRaw is! List) {
      return null;
    }

    final choices = <Map<String, bool>>[];

    for (var i = 0; i < answersRaw.length; i++) {
      final entry = answersRaw[i];

      if (entry is Map<String, dynamic>) {
        // Preferred API shape: {"answer text": true|false}
        if (entry.length == 1) {
          final onlyKey = entry.keys.first.toString().trim();
          final onlyValue = entry.values.first;
          if (onlyKey.isNotEmpty && onlyValue is bool) {
            choices.add(<String, bool>{onlyKey: onlyValue});
            continue;
          }
        }

        final text = _asNonEmptyString(
          entry['text'] ?? entry['label'] ?? entry['answer'],
        );
        final isCorrect =
            (entry['is_correct'] ?? entry['correct'] ?? false) == true;

        if (text != null) {
          choices.add(<String, bool>{text: isCorrect});
        }
        continue;
      }

      if (entry is String && entry.trim().isNotEmpty) {
        choices.add(<String, bool>{entry.trim(): false});
      }
    }

    if (choices.length != 4) {
      return null;
    }

    if (!choices.any((choice) => choice.values.firstOrNull == true)) {
      final correctIndex =
          (payload['correct_index'] as num?)?.toInt() ??
          (payload['correctOptionIndex'] as num?)?.toInt();
      final correctText =
          (payload['correct_text'] ??
                  payload['correctText'] ??
                  payload['answer'])
              ?.toString();

      for (var i = 0; i < choices.length; i++) {
        final answerText = choices[i].keys.first;
        final shouldBeCorrect =
            (correctIndex != null && i == correctIndex) ||
            (correctText != null && answerText == correctText);
        choices[i] = <String, bool>{answerText: shouldBeCorrect};
      }
    }

    if (choices.where((choice) => choice.values.firstOrNull == true).length !=
        1) {
      return null;
    }

    return choices;
  }

  static String? _asNonEmptyString(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}

extension _IterableFirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
