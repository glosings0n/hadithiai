import 'dart:developer' as dev;
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hadithi_ai/core/core.dart';

class AppSessionInfo {
  final String sessionId;
  final String websocketUrl;

  const AppSessionInfo({required this.sessionId, required this.websocketUrl});
}

class AppSessionService {
  AppSessionService._();

  static final AppSessionService instance = AppSessionService._();

  final ApiService _apiService = ApiService();

  AppSessionInfo? _currentSession;
  Future<AppSessionInfo>? _pendingCreation;
  bool _isTerminating = false;
  String? _dailyStoryTitle;
  String? _dailyStoryContent;
  String? _dailyStoryRegion;
  String? _dailyStorySummary;
  Timer? _preferencesDebounce;
  Map<String, String>? _lastPushedPreferences;
  List<String> _availableAgents = const <String>[];

  AppSessionInfo? get currentSession => _currentSession;
  List<String> get availableAgents => List<String>.from(_availableAgents);

  String get dailyStoryContextBlock {
    final title = _dailyStoryTitle?.trim();
    final content = _dailyStoryContent?.trim();
    final region = _dailyStoryRegion?.trim();
    final summary = _dailyStorySummary?.trim();

    final hasAny =
        (title != null && title.isNotEmpty) ||
        (content != null && content.isNotEmpty) ||
        (region != null && region.isNotEmpty) ||
        (summary != null && summary.isNotEmpty);

    if (!hasAny) {
      return '';
    }

    return '''
Session Story Context (source of truth for this app session):
- Title: ${title ?? 'Unknown'}
- Region: ${region ?? 'Unknown'}
- Summary: ${summary ?? 'Unknown'}

Story Text:
${content ?? ''}
''';
  }

  void setDailyStoryContext({
    required String title,
    required String content,
    String? region,
    String? summary,
  }) {
    _dailyStoryTitle = title;
    _dailyStoryContent = content;
    _dailyStoryRegion = region;
    _dailyStorySummary = summary;
    _trace(
      'setDailyStoryContext: title=$title region=${region ?? 'unknown'} hasSummary=${summary?.isNotEmpty == true}',
    );
  }

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'APP SESSION SERVICE',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<AppSessionInfo> ensureSession({
    String language = 'en',
    String ageGroup = 'child',
    String? region,
  }) async {
    final existing = _currentSession;
    if (existing != null) {
      _trace('ensureSession: reusing current sessionId=${existing.sessionId}');
      if (_availableAgents.isEmpty) {
        unawaited(refreshAgentCatalog());
      }
      return existing;
    }

    final pending = _pendingCreation;
    if (pending != null) {
      _trace('ensureSession: awaiting pending session creation');
      return pending;
    }

    _pendingCreation = _createSession(
      language: language,
      ageGroup: ageGroup,
      region: region,
    );

    try {
      final created = await _pendingCreation!;
      _currentSession = created;
      unawaited(refreshAgentCatalog());
      return created;
    } finally {
      _pendingCreation = null;
    }
  }

  Future<void> refreshAgentCatalog() async {
    try {
      final response = await _apiService.listAgents();
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        _trace(
          'refreshAgentCatalog: unexpected payload type=${data.runtimeType}',
        );
        return;
      }

      final agentsRaw = data['agents'];
      if (agentsRaw is! List) {
        _trace('refreshAgentCatalog: missing agents list');
        return;
      }

      final names = agentsRaw
          .whereType<Map<String, dynamic>>()
          .map((agent) => (agent['name'] ?? '').toString().trim())
          .where((name) => name.isNotEmpty)
          .toList(growable: false);

      _availableAgents = names;
      _trace('refreshAgentCatalog: discovered agents=$_availableAgents');

      const expected = <String>{
        'story_agent',
        'riddle_agent',
        'cultural_grounding',
        'visual_agent',
        'memory_context',
      };

      final missing = expected.difference(_availableAgents.toSet());
      if (missing.isNotEmpty) {
        _trace('refreshAgentCatalog: missing expected agents=$missing');
      }
    } catch (e, stack) {
      _trace('refreshAgentCatalog: failed', error: e, stackTrace: stack);
    }
  }

  Future<AppSessionInfo> _createSession({
    required String language,
    required String ageGroup,
    String? region,
  }) async {
    final response = await _apiService.createSession(
      language: language,
      ageGroup: ageGroup,
      region: region,
    );
    _trace(
      'ensureSession: createSession HTTP ${response.statusCode ?? 'unknown'}',
    );

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid createSession response payload');
    }

    final sessionId = data['session_id'] as String?;
    final websocketUrl = data['websocket_url'] as String?;

    if (sessionId == null || sessionId.isEmpty) {
      throw Exception('Missing session_id in createSession response');
    }

    final resolvedWsUrl =
        websocketUrl ?? '${ApiConstants.websocketUrl}?session_id=$sessionId';

    if (resolvedWsUrl.isEmpty) {
      throw Exception('Missing websocket_url in createSession response');
    }

    _trace('ensureSession: app session ready sessionId=$sessionId');
    return AppSessionInfo(sessionId: sessionId, websocketUrl: resolvedWsUrl);
  }

  Future<void> terminateSession() async {
    if (_isTerminating) {
      _trace('terminateSession: ignored already terminating');
      return;
    }

    final session = _currentSession;
    if (session == null) {
      _trace('terminateSession: skipped no active session');
      return;
    }

    _isTerminating = true;
    try {
      final response = await _apiService.deleteSession(session.sessionId);
      _trace(
        'terminateSession: deleteSession HTTP ${response.statusCode ?? 'unknown'}',
      );
      _currentSession = null;
    } on DioException catch (e, stack) {
      _trace(
        'terminateSession: deleteSession failed HTTP ${e.response?.statusCode ?? 'unknown'}',
        error: e,
        stackTrace: stack,
      );
    } catch (e, stack) {
      _trace('terminateSession: failed', error: e, stackTrace: stack);
    } finally {
      _preferencesDebounce?.cancel();
      _isTerminating = false;
    }
  }

  void schedulePreferencesUpdate({
    String? language,
    String ageGroup = 'child',
    String? region,
  }) {
    final session = _currentSession;
    if (session == null) {
      _trace('schedulePreferencesUpdate: skipped (no active session)');
      return;
    }

    final payload = <String, String>{
      'language': (language ?? 'en').trim(),
      'age_group': ageGroup.trim(),
    };
    final finalRegion = (region ?? _dailyStoryRegion ?? '').trim();
    if (finalRegion.isNotEmpty) {
      payload['region'] = finalRegion;
    }

    if (_lastPushedPreferences != null &&
        _lastPushedPreferences!.length == payload.length &&
        _lastPushedPreferences!.entries.every(
          (entry) => payload[entry.key] == entry.value,
        )) {
      _trace('schedulePreferencesUpdate: skipped duplicate payload');
      return;
    }

    _preferencesDebounce?.cancel();
    _preferencesDebounce = Timer(const Duration(milliseconds: 700), () async {
      try {
        final response = await _apiService.updateSessionPreferences(
          sessionId: session.sessionId,
          language: payload['language'],
          ageGroup: payload['age_group'],
          region: payload['region'],
        );
        _trace(
          'schedulePreferencesUpdate: pushed HTTP ${response.statusCode ?? 'unknown'} payload=$payload',
        );
        _lastPushedPreferences = Map<String, String>.from(payload);
      } catch (e, stack) {
        _trace(
          'schedulePreferencesUpdate: failed',
          error: e,
          stackTrace: stack,
        );
      }
    });
  }
}
