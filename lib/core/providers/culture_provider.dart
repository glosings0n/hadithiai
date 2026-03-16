import 'dart:developer' as dev;

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:hadithi_ai/core/core.dart';

class CultureProvider with ChangeNotifier {
  bool _launchStarted = false;

  String _region = '';
  String get region => _region;

  String _summary = '';
  String get summary => _summary;

  String _title = '';
  String get title => _title;

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'CULTURE PROVIDER',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Future<void> launch() async {
    if (_launchStarted) {
      return;
    }
    _launchStarted = true;

    final allDaily = StoryMockData.getDailyStories();
    final now = DateTime.now();
    final month = DateFormat('MMM').format(now);

    final today = allDaily.firstWhere(
      (entry) => entry.month == month && entry.day == now.day,
      orElse: () => allDaily.first,
    );

    _region = today.region;
    _summary = today.summary;
    _title = today.title;

    _trace('launch: culture context ready region=$_region title=$_title');
    notifyListeners();
  }
}
