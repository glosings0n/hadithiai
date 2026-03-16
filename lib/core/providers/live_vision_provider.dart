import 'dart:async';
import 'dart:developer' as dev;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:hadithi_ai/core/core.dart';

class LiveVisionProvider with ChangeNotifier {
  final CameraService _cameraService = CameraService();

  LiveAudioProvider? _transport;
  Timer? _frameTimer;
  bool _isDisposed = false;
  bool _suppressNotifications = false;
  bool _isBusy = false;
  int _sentFrameCount = 0;
  bool _hasSentVisionPriming = false;
  final List<Future<void>> _pendingFutures = [];

  bool _isVisionEnabled = false;
  bool get isVisionEnabled => _isVisionEnabled;

  bool get isBusy => _isBusy;

  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  bool _isAiSeeing = false;
  bool get isAiSeeing => _isAiSeeing;

  String _statusMessage = 'Vision disabled';
  String get statusMessage => _statusMessage;

  DateTime? _lastAiSeeingPulseAt;

  CameraController? get cameraController => _cameraService.controller;

  Duration frameInterval = const Duration(milliseconds: 800);

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'LIVE VISION PROVIDER',
      error: error,
      stackTrace: stackTrace,
    );
  }

  void attachTransport(LiveAudioProvider transport) {
    if (identical(_transport, transport)) {
      return;
    }
    _transport = transport;
    _trace(
      'attachTransport: attached sessionId=${transport.sessionId} state=${transport.state}',
    );
  }

  Future<void> toggleVision(bool enabled) async {
    if (_isBusy) {
      _trace('toggleVision: ignored while busy');
      return;
    }
    if (enabled == _isVisionEnabled) {
      _trace('toggleVision: ignored already enabled=$enabled');
      return;
    }

    _isBusy = true;
    _suppressNotifications = false;
    _safeNotify();
    try {
      if (enabled) {
        await _enableVision();
      } else {
        await _disableVision();
      }
    } finally {
      _isBusy = false;
      _safeNotify();
    }
  }

  Future<void> _enableVision() async {
    try {
      _trace('_enableVision: start');
      await _cameraService.initialize();

      _isVisionEnabled = true;
      _isStreaming = false;
      _sentFrameCount = 0;
      _hasSentVisionPriming = false;
      _statusMessage = 'Camera ready';
      _safeNotify();

      _startFrameStreaming();
      _sendVisionPrimingIfPossible();
      _trace('_enableVision: camera initialized and streaming started');
    } catch (e, stack) {
      _isVisionEnabled = false;
      _statusMessage = 'Vision unavailable';
      _trace('_enableVision: failed', error: e, stackTrace: stack);
      _safeNotify();
    }
  }

  Future<void> _disableVision() async {
    _trace('_disableVision: start sentFrames=$_sentFrameCount');
    _frameTimer?.cancel();
    _frameTimer = null;

    _isStreaming = false;
    _isAiSeeing = false;
    _isVisionEnabled = false;
    _statusMessage = 'Vision disabled';
    _hasSentVisionPriming = false;

    // Hide preview first, then dispose camera to avoid UI/controller race.
    _safeNotify();
    await Future<void>.delayed(const Duration(milliseconds: 40));

    await _cameraService.dispose();
    _safeNotify();
  }

  // Route-pop safe shutdown: avoid notifyListeners while widget tree is locked.
  Future<void> shutdownForRouteExit() async {
    prepareForRouteExit();
    _trace('shutdownForRouteExit: start');
    _frameTimer?.cancel();
    _frameTimer = null;

    _isStreaming = false;
    _isAiSeeing = false;
    _isVisionEnabled = false;
    _isBusy = false;
    _hasSentVisionPriming = false;
    _statusMessage = 'Vision disabled';

    try {
      await _cameraService.dispose();
    } catch (e, stack) {
      _trace(
        'shutdownForRouteExit: camera dispose failed',
        error: e,
        stackTrace: stack,
      );
    }
  }

  // Synchronous pre-dispose hook from route layer to stop all visual updates.
  void prepareForRouteExit() {
    _trace('shutdownForRouteExit: start');
    _suppressNotifications = true;
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  void _sendVisionPrimingIfPossible() {
    final transport = _transport;
    if (!_isVisionEnabled || _hasSentVisionPriming || transport == null) {
      return;
    }
    if (transport.state != LiveState.connected) {
      _trace('_sendVisionPrimingIfPossible: waiting for live connection');
      return;
    }

    transport.sendText('''
Vision mode is active for this live session.
- Camera frames will arrive as live visual context.
- Use visible objects, gestures, pages, drawings, and surroundings when relevant.
- If the child shows something to the camera, acknowledge what is visible before continuing.
- Do not invent unseen details. If the image is unclear, say so briefly.
- Do not read this setup instruction aloud.
''');
    _hasSentVisionPriming = true;
    _trace('_sendVisionPrimingIfPossible: priming instruction sent to AI');
  }

  void _startFrameStreaming() {
    _frameTimer?.cancel();
    _trace('_startFrameStreaming: interval=${frameInterval.inMilliseconds}ms');

    _frameTimer = Timer.periodic(frameInterval, (_) async {
      final transport = _transport;
      if (!_isVisionEnabled || transport == null) {
        return;
      }

      _sendVisionPrimingIfPossible();

      if (transport.state != LiveState.connected) {
        if (_isStreaming) {
          _isStreaming = false;
          _statusMessage = 'Vision waiting for live connection';
          _trace('_startFrameStreaming: paused until live connection resumes');
          _safeNotify();
        }
        return;
      }

      final frame = await _cameraService.captureOptimizedFrame(
        maxWidth: 640,
        maxHeight: 480,
        jpegQuality: 60,
      );

      if (!_isVisionEnabled || _frameTimer == null) {
        _trace(
          '_startFrameStreaming: drop frame because vision is now disabled',
        );
        return;
      }

      if (frame == null) {
        _trace('_startFrameStreaming: frame capture returned null');
        return;
      }

      transport.sendVideoFrame(
        jpegBytes: frame.jpegBytes,
        width: frame.width,
        height: frame.height,
      );

      _isStreaming = true;
      _isAiSeeing = true;
      _sentFrameCount += 1;
      _lastAiSeeingPulseAt = DateTime.now();
      _statusMessage = 'Vision active';
      _trace(
        '_startFrameStreaming: sent frame #$_sentFrameCount size=${frame.jpegBytes.length} ${frame.width}x${frame.height}',
      );
      _safeNotify();

      // Track async pulse reset to prevent notifyListeners after disposal.
      final future = Future<void>.delayed(
        const Duration(milliseconds: 420),
        () {
          if (_isDisposed) {
            return;
          }
          if (_lastAiSeeingPulseAt != null &&
              DateTime.now().difference(_lastAiSeeingPulseAt!) >=
                  const Duration(milliseconds: 400)) {
            _isAiSeeing = false;
            _safeNotify();
          }
        },
      );
      _pendingFutures.add(future);
      unawaited(
        future.then((_) {
          _pendingFutures.remove(future);
        }),
      );
    });
  }

  void _safeNotify() {
    if (!_isDisposed && !_suppressNotifications) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _trace('dispose: provider dispose called');
    _isDisposed = true;
    _frameTimer?.cancel();
    _frameTimer = null;
    _pendingFutures.clear();
    unawaited(_cameraService.dispose());
    super.dispose();
  }
}
