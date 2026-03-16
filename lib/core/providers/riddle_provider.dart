import 'dart:async';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/providers/app_preferences_provider.dart';
import 'package:hadithi_ai/core/models/models.dart';
import 'package:hadithi_ai/core/services/api_service.dart';

enum RiddleLoadState { idle, loading, ready, error }

class RiddleProvider with ChangeNotifier {
  final AppPreferencesProvider _prefs = AppPreferencesProvider.instance;
  final ApiService _apiService = ApiService();
  bool _launchStarted = false;
  bool _isCheckingAnswer = false;
  bool _isDisposed = false;
  Timer? _autoNextTimer;
  final Set<String> _servedRiddleSignatures = <String>{};
  static const int _maxUniqueFetchAttempts = 4;
  static const Duration _autoNextDelay = Duration(milliseconds: 1800);

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'RIDDLE PROVIDER',
      error: error,
      stackTrace: stackTrace,
    );
  }

  static const int _pointsPerQuestion = 5;
  static const int _tipCost = 1;
  static const int _helpCost = 1;

  RiddleLoadState _state = RiddleLoadState.idle;
  RiddleLoadState get state => _state;

  GameModel _game = GameModel.initial;

  RiddleModel? get currentQuestion => _game.currentRiddle;
  int get score => _game.score;
  int get round => _game.round;
  bool get tipUsedThisRound => _game.tipUsedThisRound;
  bool get helpUsedThisRound => _game.helpUsedThisRound;
  String? get selectedChoiceKey => _game.selectedChoiceKey;
  bool get isAnswerLocked => _game.isAnswerLocked;
  String get statusMessage => _game.statusMessage;
  String? get errorMessage => _game.errorMessage;
  bool get isCheckingAnswer => _isCheckingAnswer;

  bool get canUseTip =>
      _state == RiddleLoadState.ready &&
      !_game.tipUsedThisRound &&
      !_game.isAnswerLocked &&
      !_isCheckingAnswer;

  bool get canUseHelp =>
      _state == RiddleLoadState.ready &&
      !_game.helpUsedThisRound &&
      !_game.isAnswerLocked &&
      !_isCheckingAnswer;

  RiddleProvider() {
    _trace('RiddleProvider: initialized');
    launch();
  }

  Future<void> launch() async {
    if (_launchStarted) {
      _trace('launch: ignored, already started');
      return;
    }
    _launchStarted = true;
    _trace('launch: preloading first riddle round');
    await loadFirstQuestion();
  }

  Future<void> loadFirstQuestion() async {
    _trace('loadFirstQuestion: resetting round to 1');
    _autoNextTimer?.cancel();
    _servedRiddleSignatures.clear();
    _game = _game.copyWith(round: 1);
    await _loadQuestion();
  }

  Future<void> loadNextQuestion() async {
    if (_state == RiddleLoadState.loading || _isCheckingAnswer) {
      _trace('loadNextQuestion: ignored because state is loading');
      return;
    }
    _autoNextTimer?.cancel();
    final nextRound = _game.round + 1;
    _game = _game.copyWith(round: nextRound);
    _trace('loadNextQuestion: moved to round=$nextRound');
    await _loadQuestion();
  }

  Future<void> retry() async {
    _trace('retry: retry requested on round=${_game.round}');
    await _loadQuestion();
  }

  void useTip() {
    if (!canUseTip) {
      _trace('useTip: ignored canUseTip=false');
      return;
    }
    _game = _game.copyWith(
      tipUsedThisRound: true,
      score: (_game.score - _tipCost).clamp(0, 1 << 31),
      statusMessage:
          _game.currentRiddle?.tipMessage ??
          'Tip used: think about objects used every day at home.',
    );
    _trace('useTip: applied tipCost=$_tipCost newScore=${_game.score}');
    notifyListeners();
  }

  void useHelp() {
    if (!canUseHelp) {
      _trace('useHelp: ignored canUseHelp=false');
      return;
    }
    _game = _game.copyWith(
      helpUsedThisRound: true,
      score: (_game.score - _helpCost).clamp(0, 1 << 31),
      statusMessage:
          _game.currentRiddle?.helpMessage ??
          'Help used: remove impossible answers and compare what remains.',
    );
    _trace('useHelp: applied helpCost=$_helpCost newScore=${_game.score}');
    notifyListeners();
  }

  void selectAnswer(String choiceKey) {
    if (_game.currentRiddle == null ||
        _game.isAnswerLocked ||
        _isCheckingAnswer) {
      _trace(
        'selectAnswer: ignored currentQuestionNull=${_game.currentRiddle == null} isAnswerLocked=${_game.isAnswerLocked} isChecking=$_isCheckingAnswer',
      );
      return;
    }

    final question = _game.currentRiddle!;
    _game = _game.copyWith(selectedChoiceKey: choiceKey, isAnswerLocked: true);
    _trace('selectAnswer: selectedChoiceKey=$choiceKey');

    final selected = question.choices.firstWhere(
      (choice) => choice.keys.first == choiceKey,
      orElse: () => const <String, bool>{'': false},
    );
    final isCorrectLocal = selected.values.first;

    if (isCorrectLocal) {
      _game = _game.copyWith(
        score: _game.score + _pointsPerQuestion,
        statusMessage: 'Good choice. Checking answer...',
      );
      _trace(
        'selectAnswer: local correct=true pointsAdded=$_pointsPerQuestion newScore=${_game.score}',
      );
    } else {
      _game = _game.copyWith(statusMessage: 'Checking your answer...');
      _trace('selectAnswer: local correct=false score=${_game.score}');
    }

    _isCheckingAnswer = true;
    notifyListeners();
    unawaited(_verifyAnswerWithServer(choiceKey, isCorrectLocal));
  }

  Future<void> _verifyAnswerWithServer(
    String selectedAnswer,
    bool localCorrect,
  ) async {
    final question = _game.currentRiddle;
    if (question == null) {
      _isCheckingAnswer = false;
      notifyListeners();
      return;
    }

    try {
      final result = await _apiService
          .verifyRiddleAnswer(
            riddleId: question.id,
            selectedAnswer: selectedAnswer,
          )
          .timeout(
            const Duration(seconds: 4),
            onTimeout: () => <String, dynamic>{
              'correct': localCorrect,
              'correct_answer': question.correctAnswerText,
              'explanation': '',
            },
          );

      final serverCorrect = result['correct'] == true;
      final correctAnswer = (result['correct_answer']?.toString() ?? '').trim();
      final explanation = (result['explanation']?.toString() ?? '').trim();

      if (serverCorrect != localCorrect) {
        if (serverCorrect) {
          _game = _game.copyWith(score: _game.score + _pointsPerQuestion);
        } else if (localCorrect) {
          _game = _game.copyWith(
            score: (_game.score - _pointsPerQuestion).clamp(0, 1 << 31),
          );
        }
      }

      final status = serverCorrect
          ? 'Great job! +$_pointsPerQuestion points. Tap Next Riddle to continue.'
          : (correctAnswer.isNotEmpty
                ? 'Nice try! Correct answer: $correctAnswer.'
                : 'Nice try! Keep going, you can still win this game.');

      _game = _game.copyWith(
        statusMessage: explanation.isNotEmpty ? '$status $explanation' : status,
      );
      _trace(
        '_verifyAnswerWithServer: verified correct=$serverCorrect answer=$correctAnswer',
      );
    } on DioException catch (e, stack) {
      _trace(
        '_verifyAnswerWithServer: failed HTTP ${e.response?.statusCode ?? 'unknown'}',
        error: e,
        stackTrace: stack,
      );
      _game = _game.copyWith(
        statusMessage: localCorrect
            ? 'Great job! +$_pointsPerQuestion points. (Server verify unavailable)'
            : 'Nice try! (Server verify unavailable)',
      );
    } catch (e, stack) {
      _trace('_verifyAnswerWithServer: failed', error: e, stackTrace: stack);
    } finally {
      _isCheckingAnswer = false;
      notifyListeners();
      _scheduleAutoNextRound();
    }
  }

  void _scheduleAutoNextRound() {
    _autoNextTimer?.cancel();
    _autoNextTimer = Timer(_autoNextDelay, () {
      if (_isDisposed) {
        return;
      }
      if (_state != RiddleLoadState.ready || _isCheckingAnswer) {
        return;
      }
      if (_game.currentRiddle == null || !_game.isAnswerLocked) {
        return;
      }
      unawaited(loadNextQuestion());
    });
  }

  String _signatureOf(RiddleModel question) =>
      '${question.id.trim().toLowerCase()}::${question.question.trim().toLowerCase()}';

  Future<RiddleModel?> _fetchUniqueQuestion() async {
    RiddleModel? fallback;

    for (var attempt = 1; attempt <= _maxUniqueFetchAttempts; attempt++) {
      final question = await _apiService.generateRiddle(
        culture: _prefs.riddleCulture,
        difficulty: _prefs.riddleDifficulty,
        language: _prefs.riddleLanguage,
      );

      if (question == null) {
        _trace('_fetchUniqueQuestion: null payload attempt=$attempt');
        continue;
      }

      final signature = _signatureOf(question);
      if (!_servedRiddleSignatures.contains(signature)) {
        _servedRiddleSignatures.add(signature);
        _trace(
          '_fetchUniqueQuestion: unique accepted attempt=$attempt id=${question.id}',
        );
        return question;
      }

      fallback ??= question;
      _trace(
        '_fetchUniqueQuestion: duplicate question retry attempt=$attempt id=${question.id}',
      );
      await Future<void>.delayed(const Duration(milliseconds: 140));
    }

    if (fallback != null) {
      final signature = _signatureOf(fallback);
      _servedRiddleSignatures.add(signature);
      _trace(
        '_fetchUniqueQuestion: fallback duplicate used after retries id=${fallback.id}',
      );
    }
    return fallback;
  }

  Future<void> _loadQuestion() async {
    _trace('_loadQuestion: begin round=${_game.round}');
    _state = RiddleLoadState.loading;
    _game = _game.copyWith(
      statusMessage: 'Summoning a new riddle...',
      tipUsedThisRound: false,
      helpUsedThisRound: false,
      isAnswerLocked: false,
      clearSelectedChoiceKey: true,
      clearErrorMessage: true,
    );
    notifyListeners();

    try {
      final question = await _fetchUniqueQuestion();

      if (question == null) {
        _trace('_loadQuestion: generateRiddle returned null');
        throw Exception('Invalid riddle payload format');
      }

      _game = _game.copyWith(
        currentRiddle: question,
        statusMessage:
            'Round ${_game.round}: pick the best answer. Correct answer = +$_pointsPerQuestion points.',
        clearErrorMessage: true,
      );
      _state = RiddleLoadState.ready;
      _isCheckingAnswer = false;
      _trace(
        '_loadQuestion: ready questionId=${question.id} choices=${question.choices.length} showLive=${question.showLiveBadge}',
      );
    } on DioException catch (e, stack) {
      _state = RiddleLoadState.error;
      _isCheckingAnswer = false;
      _game = _game.copyWith(
        errorMessage: 'Could not load riddle right now. Please retry.',
        statusMessage: 'No riddle yet. Check your connection and try again.',
      );
      _trace(
        '_loadQuestion: failed HTTP ${e.response?.statusCode ?? 'unknown'}',
        error: e,
        stackTrace: stack,
      );
    } catch (e, stack) {
      _state = RiddleLoadState.error;
      _isCheckingAnswer = false;
      _game = _game.copyWith(
        errorMessage: 'Could not load riddle right now. Please retry.',
        statusMessage: 'No riddle yet. Check your connection and try again.',
      );
      _trace('_loadQuestion: failed with error', error: e, stackTrace: stack);
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _autoNextTimer?.cancel();
    super.dispose();
  }
}
