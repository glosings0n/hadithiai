import 'dart:async';
import 'dart:convert';
import 'dart:developer' as dev;
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:hadithi_ai/core/core.dart';
import 'package:record/record.dart';

enum LiveState { idle, connecting, connected, error }

class LiveAudioProvider with ChangeNotifier {
  final _audioRecorder = AudioRecorder();
  final _appSessionService = AppSessionService.instance;
  final _webSocketService = WebSocketService();
  final _playbackService = AudioPlaybackService();

  LiveState _state = LiveState.idle;
  LiveState get state => _state;

  String _statusMessage = 'Idle';
  String get statusMessage => _statusMessage;

  String? _sessionId;
  String? get sessionId => _sessionId;

  double _amplitude = 0.0;
  double get amplitude => _amplitude;

  bool _isAiSpeaking = false;
  bool get isAiSpeaking => _isAiSpeaking;

  String _lastTextChunk = '';
  String get lastTextChunk => _lastTextChunk;

  String? _latestImageUrl;
  String? get latestImageUrl => _latestImageUrl;

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  bool _isInterrupted = false;
  bool get isInterrupted => _isInterrupted;

  bool _isConversationPaused = false;
  bool get isConversationPaused => _isConversationPaused;

  bool _isMuted = false;
  bool get isMuted => _isMuted;

  StreamSubscription<Uint8List>? _recordSub;
  StreamSubscription<Map<String, dynamic>>? _socketSub;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  String? _activeWsUrl;
  bool _allowReconnect = false;
  bool _isReconnecting = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;
  bool _isDisposed = false;
  Future<void> _recorderOps = Future<void>.value();
  DateTime? _lastSpeechAt;
  DateTime? _lastUserSpeechVisualAt;
  Timer? _interruptedResetTimer;
  Timer? _interruptedRecoveryTimer;
  static const double _speechThreshold = 0.004;
  static const double _speechRmsThreshold = 0.0008;
  static const Duration _speechHangover = Duration(milliseconds: 700);
  DateTime? _lastAiAudioAt;
  static const Duration _aiSpeakingStaleTimeout = Duration(milliseconds: 6000);
  double _noiseFloorRms = 0.001;
  double _noiseFloorPeak = 0.006;
  bool _resumeRecordingAfterPause = false;
  int _incomingAudioChunkCounter = 0;
  int _outgoingAudioChunkCounter = 0;
  // 1600 bytes @ 16-bit mono = 800 samples ~= 50 ms at 16 kHz.
  // Lower latency than 100 ms chunks while keeping stable throughput.
  static const int _targetPcmChunkBytes = 1600;
  Uint8List _pcmCarry = Uint8List(0);
  bool _isStoryContextPrimed = false;
  DateTime? _lastPongAt;
  static const Duration _pongStaleTimeout = Duration(seconds: 55);
  String? _activeAgent;
  String? _agentState;
  bool _autoStoppedRecordingForAi = false;
  static const double _maxAdaptiveInputGain = 2.1;

  String? get activeAgent => _activeAgent;
  String? get agentState => _agentState;

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'LIVE AUDIO PROVIDER',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void _notifyIfMounted() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _cancelInterruptedRecovery() {
    _interruptedRecoveryTimer?.cancel();
    _interruptedRecoveryTimer = null;
  }

  void _scheduleInterruptedRecovery() {
    _cancelInterruptedRecovery();
    _interruptedRecoveryTimer = Timer(const Duration(seconds: 3), () {
      if (_isDisposed ||
          _state != LiveState.connected ||
          _isConversationPaused) {
        return;
      }
      if (!_isInterrupted || _isAiSpeaking) {
        return;
      }

      _trace(
        '_scheduleInterruptedRecovery: no user speech detected after interrupt, asking AI to continue story',
      );
      _statusMessage = 'Resuming story...';
      _isInterrupted = false;
      sendText(
        'Continue the same story context from where you stopped. Keep it short and child-friendly.',
      );
      _notifyIfMounted();
    });
  }

  Future<void> _runRecorderOp(Future<void> Function() op) {
    final chained = _recorderOps.then((_) => op()).catchError((
      Object _,
      StackTrace stackTrace,
    ) {
      // Keep the chain alive even if a prior operation failed.
    });
    _recorderOps = chained;
    return chained;
  }

  double _adaptiveInputRms(double rms) {
    final noiseBase = _noiseFloorRms.clamp(0.0002, 0.02);
    final gain = (0.0032 / noiseBase).clamp(1.0, _maxAdaptiveInputGain);
    return (rms * gain).clamp(0.0, 1.0);
  }

  Future<void> _clearGeneratedAiAudioTail() async {
    try {
      await _playbackService.clearGeneratedAudio();
    } catch (e, stack) {
      _trace(
        '_clearGeneratedAiAudioTail: ignored playback clear error',
        error: e,
        stackTrace: stack,
      );
    }
  }

  void _sendAudioChunkFramed(Uint8List chunk) {
    if (chunk.isEmpty) return;

    final merged = Uint8List(_pcmCarry.length + chunk.length)
      ..setRange(0, _pcmCarry.length, _pcmCarry)
      ..setRange(_pcmCarry.length, _pcmCarry.length + chunk.length, chunk);

    var offset = 0;
    while (merged.length - offset >= _targetPcmChunkBytes) {
      final frame = Uint8List.sublistView(
        merged,
        offset,
        offset + _targetPcmChunkBytes,
      );
      _webSocketService.sendAudio(frame);

      _outgoingAudioChunkCounter += 1;
      if (_outgoingAudioChunkCounter == 1 ||
          _outgoingAudioChunkCounter % 25 == 0) {
        _trace(
          '_startRecordingStream: outgoing audio_chunk #$_outgoingAudioChunkCounter bytes=${frame.length}',
        );
      }

      offset += _targetPcmChunkBytes;
    }

    if (offset < merged.length) {
      _pcmCarry = Uint8List.fromList(merged.sublist(offset));
    } else {
      _pcmCarry = Uint8List(0);
    }
  }

  bool get isUserSpeaking {
    if (_state != LiveState.connected) return false;
    if (_isConversationPaused || !_isRecording) return false;
    if (_amplitude >= 0.035) return true;
    if (_lastUserSpeechVisualAt == null) return false;

    return DateTime.now().difference(_lastUserSpeechVisualAt!) <=
        const Duration(milliseconds: 450);
  }

  Future<void> startLiveSession() async {
    if (_state == LiveState.connecting || _state == LiveState.connected) return;

    _trace('startLiveSession: begin');
    _state = LiveState.connecting;
    _statusMessage = 'Connecting to live story...';
    _notifyIfMounted();

    try {
      await _playbackService.initialize();

      final preferredLanguage = PreferenceHelpers.ensureSupportedLanguage(
        AppPreferencesProvider.instance.appLanguage,
      );

      final session = await _appSessionService.ensureSession(
        language: preferredLanguage,
        ageGroup: 'child',
      );
      _sessionId = session.sessionId;
      final wsUrl = session.websocketUrl;
      if (_sessionId == null || wsUrl.isEmpty) {
        throw Exception('Session ID or websocket URL missing');
      }
      _trace('startLiveSession: sessionId=$_sessionId wsUrl=$wsUrl');

      _activeWsUrl = wsUrl;
      _allowReconnect = true;
      _reconnectAttempts = 0;
      _isReconnecting = false;

      _webSocketService.connect(wsUrl);
      _trace('startLiveSession: websocket connect requested');

      _socketSub = _webSocketService.messages.listen(
        _handleServerMessage,
        onError: (error, stack) {
          _trace(
            'Socket stream error: $error',
            error: error,
            stackTrace: stack,
          );
          _setErrorState(_friendlyLiveError(error));
        },
      );

      _startPing();

      _playbackService.start();
      _state = LiveState.connected;
      _statusMessage = 'Connected';
      _isInterrupted = false;
      _isConversationPaused = false;
      _isMuted = false;
      _incomingAudioChunkCounter = 0;
      _outgoingAudioChunkCounter = 0;
      _isStoryContextPrimed = false;
      _lastPongAt = DateTime.now();
      _trace('startLiveSession: provider state connected, starting recorder');

      if (_sessionId != null && _sessionId!.isNotEmpty) {
        _webSocketService.sendSessionInit(_sessionId!);
        _trace('startLiveSession: session_init sent for sessionId=$_sessionId');
      }

      await _startRecordingStream();
      _trace('startLiveSession: recorder stream active');
    } on DioException catch (e) {
      _trace('startLiveSession: DioException ${e.type} ${e.message}');
      _setErrorState(_mapDioExceptionMessage(e));
    } catch (e) {
      _trace('startLiveSession: Exception $e');
      _setErrorState(_friendlyLiveError(e));
    }
    _notifyIfMounted();
  }

  String _mapDioExceptionMessage(DioException e) {
    final statusCode = e.response?.statusCode;

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'API timeout. Verify network connectivity and backend availability.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to reach API. Verify internet access and backend URL.';
    }

    if (e.type == DioExceptionType.badResponse) {
      return 'API HTTP error ${statusCode ?? 'unknown'}';
    }

    return 'API error: ${e.error ?? e.message ?? 'unknown'}';
  }

  String _friendlyLiveError(Object? rawError) {
    final text = rawError?.toString().toLowerCase() ?? '';

    if (text.contains('timed out')) {
      return 'The live service is taking too long. Please try again.';
    }
    if (text.contains('1008') || text.contains('operation not supported')) {
      return 'Live session expired. Reconnecting...';
    }
    if (text.contains('session not found')) {
      return 'Session expired. Reconnecting...';
    }
    if (text.contains('socket') || text.contains('websocket')) {
      return 'Connection issue. Trying to reconnect...';
    }
    return 'Live service temporarily unavailable. Please try again.';
  }

  void _setErrorState(String message) {
    _trace('_setErrorState: $message');
    _state = LiveState.error;
    _statusMessage = message;
    _isAiSpeaking = false;
    _isRecording = false;
    _isInterrupted = false;
    _amplitude = 0.0;
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  void _startPing() {
    _pingTimer?.cancel();
    _trace('_startPing: timer started');
    _pingTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (_state == LiveState.connected && _webSocketService.isConnected) {
        if (_lastPongAt != null &&
            DateTime.now().difference(_lastPongAt!) > _pongStaleTimeout &&
            _allowReconnect) {
          _trace('_startPing: pong stale, forcing reconnect');
          _webSocketService.disconnect();
          _reconnectSocket();
          return;
        }
        _webSocketService.sendPing();
        _trace('_startPing: ping sent');
      }
    });
  }

  Future<void> _reconnectSocket() async {
    if (!_allowReconnect || _isDisposed || _activeWsUrl == null) return;
    if (_isReconnecting) return;
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      _setErrorState('WebSocket reconnection failed');
      return;
    }

    _isReconnecting = true;
    _state = LiveState.connecting;
    _reconnectAttempts += 1;
    final delaySeconds = _reconnectAttempts;
    _statusMessage =
        'Reconnecting... ($_reconnectAttempts/$_maxReconnectAttempts)';
    _trace(
      '_reconnectSocket: scheduling reconnect attempt $_reconnectAttempts',
    );
    if (!_isDisposed) {
      notifyListeners();
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(Duration(seconds: delaySeconds), () {
      if (!_allowReconnect || _isDisposed || _activeWsUrl == null) {
        _isReconnecting = false;
        return;
      }

      _webSocketService.connect(_activeWsUrl!);
      _trace('_reconnectSocket: reconnect requested to $_activeWsUrl');
      _isReconnecting = false;
    });
  }

  void _handleServerMessage(Map<String, dynamic> msg) {
    final eventType = msg['type']?.toString() ?? 'unknown';
    if (eventType != 'audio_chunk') {
      _trace('_handleServerMessage: type=$eventType payload=$msg');
    }

    switch (msg['type']) {
      case 'session_created':
        _sessionId = msg['session_id'] as String? ?? _sessionId;
        _statusMessage = 'Session ready';
        _reconnectAttempts = 0;
        _isReconnecting = false;
        _lastPongAt = DateTime.now();
        _sendLanguageControl();
        _primeStoryContextForLiveSession();
        break;
      case 'audio_chunk':
        _incomingAudioChunkCounter += 1;
        if (_incomingAudioChunkCounter == 1 ||
            _incomingAudioChunkCounter % 25 == 0) {
          _trace(
            '_handleServerMessage: audio_chunk #$_incomingAudioChunkCounter muted=$_isMuted paused=$_isConversationPaused',
          );
        }
        if (_isConversationPaused) {
          _isAiSpeaking = false;
          _statusMessage = 'Conversation paused';
          break;
        }

        _isAiSpeaking = true;
        _lastAiAudioAt = DateTime.now();
        _isInterrupted = false;
        _cancelInterruptedRecovery();
        _statusMessage = _isMuted ? 'AI speaking (muted)' : 'AI speaking...';

        // Half-duplex flow: once AI starts speaking, pause mic capture to avoid
        // accidental barge-in and phantom "interrupted" events from ambient noise.
        if (_isRecording &&
            !_isConversationPaused &&
            !_autoStoppedRecordingForAi) {
          _autoStoppedRecordingForAi = true;
          unawaited(_stopRecordingStream());
        }

        final encodedData = msg['data'] as String?;
        if (!_isConversationPaused &&
            !_isMuted &&
            encodedData != null &&
            encodedData.isNotEmpty) {
          try {
            _playbackService.add(base64Decode(encodedData));
          } catch (e, stack) {
            _trace(
              '_handleServerMessage: invalid audio_chunk base64',
              error: e,
              stackTrace: stack,
            );
          }
        }
        break;
      case 'text_chunk':
        _lastTextChunk = (msg['data'] as String?)?.trim() ?? '';
        break;
      case 'image_ready':
        _latestImageUrl = msg['url'] as String?;
        break;
      case 'agent_state':
        _activeAgent = msg['agent'] as String?;
        _agentState = msg['state'] as String?;
        _statusMessage = _agentState != null && _agentState!.isNotEmpty
            ? 'AI ${_agentState!}'
            : _statusMessage;
        break;
      case 'turn_end':
        _isAiSpeaking = false;
        _lastAiAudioAt = null;
        _isInterrupted = false;
        _autoStoppedRecordingForAi = false;
        _cancelInterruptedRecovery();
        _statusMessage = _isConversationPaused
            ? 'Conversation paused'
            : 'Listening';
        // Auto-resume recording if we auto-stopped for AI speaking.
        if (!_isRecording && !_isConversationPaused && !_isMuted) {
          unawaited(_startRecordingStream());
        }
        break;
      case 'interrupted':
        _isAiSpeaking = false;
        _lastAiAudioAt = null;
        _isInterrupted = true;
        _autoStoppedRecordingForAi = false;
        _statusMessage = 'Interrupted - speak now';
        unawaited(_clearGeneratedAiAudioTail());
        _scheduleInterruptedReset();
        _scheduleInterruptedRecovery();
        // Auto-resume recording so user can speak immediately.
        if (!_isRecording && !_isConversationPaused && !_isMuted) {
          unawaited(_startRecordingStream());
        }
        break;
      case 'pong':
        _lastPongAt = DateTime.now();
        break;
      case 'disconnected':
        _isAiSpeaking = false;
        _lastAiAudioAt = null;
        _isInterrupted = false;
        _cancelInterruptedRecovery();
        if (_allowReconnect) {
          _reconnectSocket();
        } else {
          _state = LiveState.idle;
          _statusMessage = 'Disconnected';
          _isRecording = false;
          _amplitude = 0.0;
        }
        break;
      case 'error':
        final source = msg['source'] as String?;
        final rawError = msg['error'];
        final rawText = rawError?.toString().toLowerCase() ?? '';
        _trace('_handleServerMessage: Server Error: $rawError');

        final recoverable =
            source == 'socket' ||
            rawText.contains('timed out') ||
            rawText.contains('1008') ||
            rawText.contains('session not found') ||
            rawText.contains('operation not supported');

        if (recoverable && _allowReconnect) {
          _statusMessage = _friendlyLiveError(rawError);
          _reconnectSocket();
        } else {
          _setErrorState(_friendlyLiveError(rawError));
        }
        _cancelInterruptedRecovery();
        break;
    }

    _notifyIfMounted();
  }

  void _sendLanguageControl() {
    final appLanguage = AppPreferencesProvider.instance.appLanguage.trim();
    if (appLanguage.isEmpty || _state != LiveState.connected) {
      return;
    }
    _webSocketService.sendControl(action: 'set_language', value: appLanguage);
    _trace('_sendLanguageControl: set_language=$appLanguage');
  }

  void _primeStoryContextForLiveSession() {
    if (_isStoryContextPrimed) {
      return;
    }

    final contextBlock = _appSessionService.dailyStoryContextBlock;
    if (contextBlock.trim().isEmpty) {
      _trace('_primeStoryContextForLiveSession: skipped (no story context)');
      return;
    }

    _isStoryContextPrimed = true;
    _webSocketService.sendText('''
Session setup context (do not narrate this back):
$contextBlock

Instruction:
- Use this as the primary story context for this live session.
- Keep answers aligned with this story world unless user explicitly changes topic.
- Do not read this setup message aloud.
''');
    _trace(
      '_primeStoryContextForLiveSession: story context sent to live model',
    );
  }

  Future<void> _startRecordingStream() async {
    await _runRecorderOp(() async {
      if (_isRecording) return;

      final hasPermission = await _audioRecorder.hasPermission();
      _trace('_startRecordingStream: micPermission=$hasPermission');
      if (!hasPermission) {
        _setErrorState('Microphone permission denied');
        return;
      }

      const config = RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      );

      final stream = await _audioRecorder.startStream(config);
      _trace('_startRecordingStream: stream started (16k PCM mono)');
      _isRecording = true;
      _recordSub = stream.listen(
        (data) {
          if (_state != LiveState.connected || !_webSocketService.isConnected) {
            return;
          }

          // If backend misses turn_end, recover AI turn automatically.
          if (_isAiSpeaking &&
              _lastAiAudioAt != null &&
              DateTime.now().difference(_lastAiAudioAt!) >
                  _aiSpeakingStaleTimeout) {
            _isAiSpeaking = false;
            _lastAiAudioAt = null;
            _autoStoppedRecordingForAi = false;
            _statusMessage = _isConversationPaused
                ? 'Conversation paused'
                : 'Listening';
            _trace('_startRecordingStream: recovered stale AI speaking state');
          }

          if (_isConversationPaused) {
            _amplitude = 0.0;
            return;
          }

          // When muted: keep the stream alive for noise-floor tracking but suppress
          // mic send, barge-in interrupts, and amplitude so the AI plays undisturbed.
          if (_isMuted) {
            _amplitude = 0.0;
            return;
          }

          final chunk = Uint8List.fromList(data);
          final metrics = _analyzeChunk(chunk);
          final speechDetected = _isSpeech(
            metrics,
            peakThreshold: _speechThreshold,
            rmsThreshold: _speechRmsThreshold,
          );
          final adaptiveRms = _adaptiveInputRms(metrics.rms);

          // Continuously adapt to background noise so only clear user speech can barge-in.
          if (!_isAiSpeaking && !speechDetected) {
            _noiseFloorRms = ((_noiseFloorRms * 0.96) + (metrics.rms * 0.04))
                .clamp(0.0002, 0.02);
            _noiseFloorPeak = ((_noiseFloorPeak * 0.96) + (metrics.peak * 0.04))
                .clamp(0.002, 0.08);
          }

          if (adaptiveRms >= _speechRmsThreshold * 0.8) {
            _lastUserSpeechVisualAt = DateTime.now();
          }

          // Strict turn-taking: while AI is speaking, never send mic frames.
          if (_isAiSpeaking) {
            _updateAmplitude(adaptiveRms);
            return;
          }

          if (speechDetected) {
            _lastSpeechAt = DateTime.now();
            _lastUserSpeechVisualAt = DateTime.now();

            _isInterrupted = false;
            _cancelInterruptedRecovery();
          }

          // During user turn, stream only during speech windows plus a short hangover.
          if (!_isAiSpeaking) {
            final now = DateTime.now();
            final shouldSend =
                speechDetected ||
                adaptiveRms >= (_noiseFloorRms * 1.35) ||
                (_lastSpeechAt != null &&
                    now.difference(_lastSpeechAt!) <= _speechHangover);

            if (shouldSend) {
              _sendAudioChunkFramed(chunk);
            }
            _statusMessage = speechDetected ? 'User speaking...' : 'Listening';
          }

          _updateAmplitude(adaptiveRms);
        },
        onError: (error, stack) {
          _trace(
            'Recorder stream error: $error',
            error: error,
            stackTrace: stack,
          );
          _setErrorState('Recorder stream error: $error');
        },
        cancelOnError: false,
      );
      _notifyIfMounted();
    });
  }

  Future<void> _stopRecordingStream() async {
    await _runRecorderOp(() async {
      if (!_isRecording) return;

      _trace('_stopRecordingStream: stopping recorder stream');

      await _recordSub?.cancel();
      _recordSub = null;
      await _audioRecorder.stop();
      _isRecording = false;
      _isInterrupted = false;
      _lastSpeechAt = null;
      _lastUserSpeechVisualAt = null;
      _noiseFloorRms = 0.001;
      _noiseFloorPeak = 0.006;
      _pcmCarry = Uint8List(0);
      _amplitude = 0.0;
      if (_state == LiveState.connected && !_isConversationPaused) {
        _statusMessage = 'Mic paused';
      }
      _trace('_stopRecordingStream: stopped');
      _notifyIfMounted();
    });
  }

  Future<void> toggleRecording() async {
    if (_state != LiveState.connected) return;
    _trace('toggleRecording: current isRecording=$_isRecording');

    if (_isRecording) {
      await _stopRecordingStream();
    } else {
      await _startRecordingStream();
      _statusMessage = 'Listening';
      _notifyIfMounted();
    }
    _trace(
      'toggleRecording: new isRecording=$_isRecording status=$_statusMessage',
    );
  }

  void _updateAmplitude(double rms) {
    if (rms <= 0) {
      _amplitude = 0.0;
      return;
    }

    // Boost low RMS values so voice activity is visible in UI/pulse.
    final boosted = (rms * 10.0).clamp(0.0, 1.0);
    _amplitude = (_amplitude * 0.65) + (boosted * 0.35);
  }

  ({double peak, double rms}) _analyzeChunk(Uint8List chunk) {
    if (chunk.length < 2) {
      return (peak: 0.0, rms: 0.0);
    }

    var peak = 0.0;
    var sumSquares = 0.0;
    var sampleCount = 0;
    for (var i = 0; i + 1 < chunk.length; i += 2) {
      final sample = (chunk[i] & 0xFF) | (chunk[i + 1] << 8);
      final signedSample = sample > 32767 ? sample - 65536 : sample;
      final normalizedSigned = signedSample / 32768.0;
      final normalized = normalizedSigned.abs();
      sumSquares += normalizedSigned * normalizedSigned;
      sampleCount += 1;
      if (normalized > peak) {
        peak = normalized;
      }
    }

    if (sampleCount == 0) {
      return (peak: 0.0, rms: 0.0);
    }

    final rms = (sumSquares / sampleCount).clamp(0.0, 1.0);
    return (peak: peak, rms: rms);
  }

  bool _isSpeech(
    ({double peak, double rms}) metrics, {
    required double peakThreshold,
    required double rmsThreshold,
  }) {
    return metrics.peak >= peakThreshold && metrics.rms >= rmsThreshold;
  }

  void _scheduleInterruptedReset() {
    _interruptedResetTimer?.cancel();
    _interruptedResetTimer = Timer(const Duration(seconds: 2), () {
      if (_isDisposed) {
        return;
      }

      if (_isInterrupted && !_isAiSpeaking && _state == LiveState.connected) {
        _isInterrupted = false;
        _statusMessage = _isConversationPaused
            ? 'Conversation paused'
            : 'Listening';
        if (!_isDisposed) {
          notifyListeners();
        }
      }
    });
  }

  void sendText(String text) {
    if (_state != LiveState.connected) {
      _trace('sendText: skipped state=$_state');
      return;
    }
    _trace('sendText: chars=${text.length}');
    _webSocketService.sendText(text);
  }

  void sendControl({required String action, required String value}) {
    if (_state != LiveState.connected || !_webSocketService.isConnected) {
      _trace('sendControl: skipped state=$_state action=$action');
      return;
    }
    _webSocketService.sendControl(action: action, value: value);
    _trace('sendControl: action=$action value=$value');
  }

  void sendVideoFrame({
    required Uint8List jpegBytes,
    required int width,
    required int height,
  }) {
    if (_state != LiveState.connected || !_webSocketService.isConnected) {
      _trace(
        'sendVideoFrame: skipped state=$_state socket=${_webSocketService.isConnected}',
      );
      return;
    }
    _trace(
      'sendVideoFrame: forwarding bytes=${jpegBytes.length} ${width}x$height sessionId=$_sessionId',
    );
    _webSocketService.sendVideoFrame(
      jpegBytes: jpegBytes,
      width: width,
      height: height,
    );
  }

  void interruptAi() {
    if (_state != LiveState.connected) return;
    _trace('interruptAi: manual interrupt sent');
    _webSocketService.sendInterrupt();
    _isAiSpeaking = false;
    _isInterrupted = true;
    _autoStoppedRecordingForAi = false;
    _statusMessage = 'Interrupt sent - speak now';
    unawaited(_clearGeneratedAiAudioTail());
    _scheduleInterruptedReset();
    _scheduleInterruptedRecovery();
    _notifyIfMounted();
  }

  Future<void> toggleConversationPause() async {
    if (_state != LiveState.connected) return;
    _trace(
      'toggleConversationPause: before paused=$_isConversationPaused recording=$_isRecording ai=$_isAiSpeaking',
    );

    _isConversationPaused = !_isConversationPaused;
    if (_isConversationPaused) {
      _resumeRecordingAfterPause = _isRecording;
      _webSocketService.sendInterrupt();
      _isAiSpeaking = false;
      _isInterrupted = false;
      _autoStoppedRecordingForAi = false;
      await _stopRecordingStream();
      await _clearGeneratedAiAudioTail();
      _cancelInterruptedRecovery();
      try {
        await _playbackService.stop();
      } catch (_) {}
      _statusMessage = 'Conversation paused';
      _amplitude = 0.0;
    } else {
      try {
        await _playbackService.start();
      } catch (_) {}

      if (_resumeRecordingAfterPause && !_isRecording) {
        await _startRecordingStream();
      }
      _resumeRecordingAfterPause = false;

      _statusMessage = _isRecording ? 'Listening' : 'Mic paused';
      _cancelInterruptedRecovery();
    }

    _trace(
      'toggleConversationPause: after paused=$_isConversationPaused recording=$_isRecording ai=$_isAiSpeaking status=$_statusMessage',
    );

    _notifyIfMounted();
  }

  Future<void> toggleMute() async {
    if (_state != LiveState.connected) return;

    _isMuted = !_isMuted;
    _trace(
      'toggleMute: isMuted=$_isMuted aiSpeaking=$_isAiSpeaking paused=$_isConversationPaused',
    );
    if (_isMuted) {
      _statusMessage = _isAiSpeaking ? 'AI speaking (muted)' : 'Muted';
    } else {
      _statusMessage = _isConversationPaused
          ? 'Conversation paused'
          : _isAiSpeaking
          ? 'AI speaking...'
          : 'Listening';
    }

    _notifyIfMounted();
  }

  Future<void> endSession() async {
    _trace('endSession: begin');
    _allowReconnect = false;
    _activeWsUrl = null;
    _isReconnecting = false;
    _reconnectAttempts = 0;
    _autoStoppedRecordingForAi = false;

    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _interruptedResetTimer?.cancel();
    _interruptedResetTimer = null;
    _cancelInterruptedRecovery();

    _pingTimer?.cancel();
    _pingTimer = null;

    await _recordSub?.cancel();
    _recordSub = null;

    await _socketSub?.cancel();
    _socketSub = null;

    if (await _audioRecorder.isRecording()) {
      await _audioRecorder.stop();
    }

    _webSocketService.disconnect();

    try {
      await _playbackService.stop();
    } catch (_) {}

    if (_sessionId != null && _sessionId!.isNotEmpty) {
      _trace(
        'endSession: websocket closed, app session kept alive sessionId=$_sessionId',
      );
    }
    _sessionId = null;

    _isRecording = false;
    _isAiSpeaking = false;
    _isInterrupted = false;
    _isConversationPaused = false;
    _isMuted = false;
    _lastSpeechAt = null;
    _lastUserSpeechVisualAt = null;
    _lastAiAudioAt = null;
    _noiseFloorRms = 0.001;
    _noiseFloorPeak = 0.006;
    _pcmCarry = Uint8List(0);
    _resumeRecordingAfterPause = false;
    _lastTextChunk = '';
    _latestImageUrl = null;
    _activeAgent = null;
    _agentState = null;
    _lastPongAt = null;
    _amplitude = 0.0;
    _state = LiveState.idle;
    _statusMessage = 'Idle';

    _notifyIfMounted();
    _trace('endSession: complete');
  }

  @override
  void dispose() {
    _trace('dispose: provider dispose called');
    _isDisposed = true;
    _allowReconnect = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _interruptedResetTimer?.cancel();
    _cancelInterruptedRecovery();
    _recordSub?.cancel();
    _socketSub?.cancel();
    _audioRecorder.dispose();
    _webSocketService.disconnect();
    _playbackService.dispose();
    super.dispose();
  }
}
