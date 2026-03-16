import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/widgets.dart';
import 'package:hadithi_ai/core/core.dart';

class AppSessionProvider with ChangeNotifier, WidgetsBindingObserver {
  final AppSessionService _appSessionService = AppSessionService.instance;

  bool _isInitializing = false;
  bool get isInitializing => _isInitializing;

  bool _isReady = false;
  bool get isReady => _isReady;

  String? _sessionId;
  String? get sessionId => _sessionId;

  bool _started = false;

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'APP SESSION PROVIDER',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> launch() async {
    if (_started) {
      return;
    }
    _started = true;
    _isInitializing = true;
    notifyListeners();

    WidgetsBinding.instance.addObserver(this);

    try {
      final session = await _appSessionService.ensureSession();
      _sessionId = session.sessionId;
      _isReady = true;
      _trace('launch: app session started sessionId=$_sessionId');
    } catch (e, stack) {
      _trace(
        'launch: failed to start app session',
        error: e,
        stackTrace: stack,
      );
      _isReady = false;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      unawaited(_appSessionService.terminateSession());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_appSessionService.terminateSession());
    super.dispose();
  }
}
