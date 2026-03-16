import 'dart:developer' as dev;

import 'package:flutter/material.dart';

class HomeProvider with ChangeNotifier {
  HomeProvider() {
    _trace('HomeProvider: initialized');
  }

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(
      message,
      name: 'HOME PROVIDER',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
