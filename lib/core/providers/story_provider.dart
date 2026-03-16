import 'dart:async';
import 'dart:developer' as dev;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hadithi_ai/core/core.dart';

class StoryProvider with ChangeNotifier {
  final AppSessionService _appSessionService = AppSessionService.instance;
  final AppPreferencesProvider _prefs = AppPreferencesProvider.instance;
  final ApiService _apiService = ApiService();

  List<StoryModel> _stories = [];
  StoryModel? _selectedStory;
  StoryModel? _todayStoryMeta;
  bool _isFetchingTodayContent = false;
  bool _isDisposed = false;
  List<StoryModel> _libraryStories = [];
  bool _launchStarted = false;

  List<StoryModel> get stories => _stories;
  List<StoryModel> get libraryStories => _libraryStories;
  StoryModel? get selectedStory => _selectedStory;
  bool get isFetchingTodayContent => _isFetchingTodayContent;
  StoryModel? get todayStoryMeta => _todayStoryMeta;

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'STORY PROVIDER',
      error: error,
      stackTrace: stackTrace,
    );
  }

  StoryProvider() {
    _trace('StoryProvider: initialized');
    launch();
  }

  Future<void> launch() async {
    if (_launchStarted) {
      _trace('launch: ignored, already started');
      return;
    }
    _launchStarted = true;

    _trace('launch: preparing today story from mock catalog');
    await _prepareTodayStory();
  }

  void loadStories() {
    _trace('loadStories: ensuring today story entry exists');
    if (_stories.isEmpty) {
      unawaited(_prepareTodayStory());
    }
    _trace('loadStories: loaded count=${_stories.length}');
    notifyListeners();
  }

  Future<void> refreshCatalog({bool forceRemote = true}) async {
    _trace('refreshCatalog: forceRemote=$forceRemote');
    await _prepareTodayStory(forceRemote: forceRemote);
  }

  void selectStory(StoryModel story) {
    _selectedStory = story;
    _trace('selectStory: selected id=${story.id} title=${story.title}');
    notifyListeners();
  }

  Future<void> _prepareTodayStory({bool forceRemote = false}) async {
    final appLanguage = _prefs.appLanguage.trim().isEmpty
        ? 'en'
        : _prefs.appLanguage.trim();
    final allDaily = StoryMockData.getDailyStories()
        .map((story) => story.copyWith(language: appLanguage))
        .toList(growable: false);
    final now = DateTime.now();
    final month = DateFormat('MMM').format(now);

    // Find today's story in mock data
    final todayEntry = allDaily.firstWhere(
      (entry) => entry.month == month && entry.day == now.day,
      orElse: () => allDaily.first,
    );

    // Stage 1: immediately show the mock calendar
    _publishCatalog(catalog: allDaily, todayStoryMeta: todayEntry);

    // Stage 2: fetch today's content from daystory endpoint
    await _fetchTodayStoryContent(todayEntry);
  }

  Future<void> _fetchTodayStoryContent(StoryModel todayEntry) async {
    if (_isDisposed) return;

    _isFetchingTodayContent = true;
    _notifyIfMounted();

    try {
      _trace(
        'content: fetching story content and image id=${todayEntry.id} title=${todayEntry.title} language=${todayEntry.language} region=${todayEntry.region}',
      );

      final contentFuture = _apiService
          .getStoryDaystoryContent(
            story: todayEntry,
            language: todayEntry.language,
          )
          .catchError((error, stack) {
            _trace(
              'content: daystory content request failed; continuing with image',
              error: error,
              stackTrace: stack is StackTrace ? stack : null,
            );
            return '';
          });

      final imageFuture = _apiService
          .getStoryDaystoryImage(
            story: todayEntry,
            language: todayEntry.language,
          )
          .catchError((error, stack) {
            _trace(
              'content: daystory image request failed; continuing with content',
              error: error,
              stackTrace: stack is StackTrace ? stack : null,
            );
            return '';
          });

      final results = await Future.wait<String>([contentFuture, imageFuture]);
      final content = results[0];
      final imageUrl = results[1];

      if (_isDisposed) return;

      _trace(
        'content: received story content chars=${content.length} image_url_length=${imageUrl.length}',
      );

      _updateTodayStory(content: content, imageUrl: imageUrl);
    } catch (e, stack) {
      _trace(
        'content: failed to fetch story content/image',
        error: e,
        stackTrace: stack,
      );
    } finally {
      _isFetchingTodayContent = false;
      _notifyIfMounted();
    }
  }

  void _publishCatalog({
    required List<StoryModel> catalog,
    StoryModel? todayStoryMeta,
  }) {
    final now = DateTime.now();
    final month = DateFormat('MMM').format(now);

    final selected = catalog.firstWhere(
      (entry) => entry.month == month && entry.day == now.day,
      orElse: () => catalog.first,
    );

    _todayStoryMeta = todayStoryMeta ?? selected;

    var todayStory = selected.copyWith(
      content: selected.content,
      imageUrl: selected.imageUrl,
    );

    _stories = [
      todayStory,
      ...catalog.where((story) => !_sameDay(story, todayStory)),
    ];
    _libraryStories = catalog
        .map((story) => _sameDay(story, todayStory) ? todayStory : story)
        .toList(growable: false);

    _appSessionService.setDailyStoryContext(
      title: todayStory.title,
      content: todayStory.content,
      region: selected.region,
      summary: selected.summary,
    );

    _notifyIfMounted();
  }

  bool _sameDay(StoryModel a, StoryModel b) =>
      a.day == b.day && a.month == b.month;

  void _updateTodayStory({String? content, String? imageUrl}) {
    if (_stories.isEmpty) return;

    final current = _stories.first;
    _stories[0] = current.copyWith(
      content: content ?? current.content,
      imageUrl: imageUrl ?? current.imageUrl,
    );

    final updated = _stories[0];
    if (_libraryStories.isNotEmpty) {
      _libraryStories = _libraryStories
          .map((story) => _sameDay(story, updated) ? updated : story)
          .toList(growable: false);
    }

    _appSessionService.setDailyStoryContext(
      title: updated.title,
      content: updated.content,
      region: _todayStoryMeta?.region,
      summary: _todayStoryMeta?.summary,
    );

    _notifyIfMounted();
  }

  void _notifyIfMounted() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
