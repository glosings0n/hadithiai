import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';

enum NarrationTransition { none, starting, stopping }

class StoryNarrationProvider with ChangeNotifier {
  final AppSessionService _appSessionService = AppSessionService.instance;
  final AppPreferencesProvider _prefs = AppPreferencesProvider.instance;
  final WebSocketService _webSocketService = WebSocketService();
  final AudioPlaybackService _playbackService = AudioPlaybackService();

  StreamSubscription<Map<String, dynamic>>? _socketSub;

  bool _isReading = false;
  bool get isReading => _isReading;

  bool _isBusy = false;
  bool get isBusy => _isBusy;

  NarrationTransition _transition = NarrationTransition.none;
  NarrationTransition get transition => _transition;
  bool get isStarting => _transition == NarrationTransition.starting;
  bool get isStopping => _transition == NarrationTransition.stopping;

  String _statusMessage = 'Idle';
  String get statusMessage => _statusMessage;

  String? _sessionId;
  bool _isDisposed = false;

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'STORY NARRATION PROVIDER',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> startReading({
    required String title,
    required String content,
  }) async {
    if (_isBusy || _isReading || content.trim().isEmpty) {
      return;
    }

    _isBusy = true;
    _transition = NarrationTransition.starting;
    _statusMessage = 'Preparing narration';
    _safeNotify();

    try {
      await _playbackService.initialize();

      final session = await _appSessionService.ensureSession(
        language: _prefs.appLanguage,
        ageGroup: 'child',
      );
      _sessionId = session.sessionId;
      final wsUrl = session.websocketUrl;

      if (_sessionId == null || _sessionId!.isEmpty || wsUrl.isEmpty) {
        throw Exception('Missing session id or websocket url');
      }

      _socketSub = _webSocketService.messages.listen(_handleServerMessage);
      _webSocketService.connect(wsUrl);

      _webSocketService.sendSessionInit(_sessionId!);
      _webSocketService.sendControl(
        action: 'set_language',
        value: _prefs.appLanguage,
      );

      _isReading = true;
      _statusMessage = 'Reading';
      _safeNotify();

      _webSocketService.sendText(
        _buildReadOnlyPrompt(title: title, content: content),
      );
      _trace('startReading: text prompt sent (output-only mode)');
    } catch (e, stack) {
      _trace('startReading: failed', error: e, stackTrace: stack);
      _statusMessage = 'Narration is temporarily unavailable.';
    } finally {
      _transition = NarrationTransition.none;
      _isBusy = false;
      _safeNotify();
    }
  }

  void _handleServerMessage(Map<String, dynamic> msg) {
    final type = msg['type']?.toString() ?? 'unknown';

    if (type == 'session_created') {
      _trace('socket: session_created');
      return;
    }

    if (type == 'audio_chunk') {
      final encodedData = msg['data'] as String?;
      if (encodedData != null && encodedData.isNotEmpty) {
        try {
          _playbackService.add(base64Decode(encodedData));
        } catch (e, stack) {
          _trace(
            'socket: invalid narration audio_chunk base64',
            error: e,
            stackTrace: stack,
          );
        }
      }
      return;
    }

    if (type == 'turn_end') {
      _trace('socket: turn_end (narration complete)');
      unawaited(stopReading());
      return;
    }

    if (type == 'error') {
      _trace('socket: error ${msg['error']}');
      _statusMessage = 'Narration interrupted. Please try again.';
      unawaited(stopReading());
      return;
    }
  }

  Future<void> stopReading() async {
    if (!_isReading && !_isBusy && _sessionId == null) {
      return;
    }
    if (_isBusy && _transition == NarrationTransition.stopping) {
      return;
    }

    _trace('stopReading: begin');
    _isBusy = true;
    _transition = NarrationTransition.stopping;
    _isReading = false;
    _statusMessage = 'Stopping narration';
    _safeNotify();

    await _socketSub?.cancel();
    _socketSub = null;
    _webSocketService.disconnect();

    try {
      await _playbackService.stop();
    } catch (_) {}

    final sessionToDelete = _sessionId;
    _sessionId = null;
    if (sessionToDelete != null && sessionToDelete.isNotEmpty) {
      _trace(
        'stopReading: websocket closed, app session kept alive sessionId=$sessionToDelete',
      );
    }

    _trace('stopReading: complete');
    _transition = NarrationTransition.none;
    _isBusy = false;
    _statusMessage = 'Idle';
    _safeNotify();
  }

  String _buildReadOnlyPrompt({
    required String title,
    required String content,
  }) {
    final sessionContext = _appSessionService.dailyStoryContextBlock;

    return '''
Read the following story aloud in language "${_prefs.appLanguage}".
Output voice audio only.
  Start EXACTLY with this sentence:
  Hello, I'm Hadithi AI, and today's story is about: "$title"

  Then continue by reading the provided story text verbatim.
  Do not add, rewrite, summarize, continue, or invent anything beyond the intro sentence above.
Do not ask questions.
Do not wait for user input.
Do not start a conversation.
Do not generate an image.

$sessionContext

Title: $title

Story (read this exact text only):
$content
''';
  }

  void _safeNotify() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    unawaited(stopReading());
    _webSocketService.dispose();
    _playbackService.dispose();
    super.dispose();
  }
}
