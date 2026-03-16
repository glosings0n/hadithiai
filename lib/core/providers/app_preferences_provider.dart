import 'package:flutter/foundation.dart';
import 'package:hadithi_ai/core/helpers/preference_helpers.dart';

class AppPreferencesProvider with ChangeNotifier {
  AppPreferencesProvider._();

  static final AppPreferencesProvider instance = AppPreferencesProvider._();

  bool _safeMode = true;
  bool get safeMode => _safeMode;

  bool _autoReadAloud = false;
  bool get autoReadAloud => _autoReadAloud;

  bool _dailyReminder = true;
  bool get dailyReminder => _dailyReminder;

  bool _showCulturalNotes = true;
  bool get showCulturalNotes => _showCulturalNotes;

  bool _voiceInterruptions = true;
  bool get voiceInterruptions => _voiceInterruptions;

  String _appLanguage = 'en';
  String get appLanguage => _appLanguage;

  String _riddleDifficulty = 'medium';
  String get riddleDifficulty => _riddleDifficulty;

  String _riddleCulture = 'East African';
  String get riddleCulture => _riddleCulture;

  String _riddleLanguage = 'en';
  String get riddleLanguage => _riddleLanguage;

  String _storyCatalogLanguage = 'en';
  String get storyCatalogLanguage => _storyCatalogLanguage;

  void setSafeMode(bool value) {
    _safeMode = value;
    notifyListeners();
  }

  void setAutoReadAloud(bool value) {
    _autoReadAloud = value;
    notifyListeners();
  }

  void setDailyReminder(bool value) {
    _dailyReminder = value;
    notifyListeners();
  }

  void setShowCulturalNotes(bool value) {
    _showCulturalNotes = value;
    notifyListeners();
  }

  void setVoiceInterruptions(bool value) {
    _voiceInterruptions = value;
    notifyListeners();
  }

  void setAppLanguage(String value) {
    _appLanguage = PreferenceHelpers.ensureSupportedLanguage(value);
    notifyListeners();
  }

  void setRiddleDifficulty(String value) {
    _riddleDifficulty = value;
    notifyListeners();
  }

  void setRiddleCulture(String value) {
    _riddleCulture = value;
    notifyListeners();
  }

  void setRiddleLanguage(String value) {
    _riddleLanguage = PreferenceHelpers.ensureSupportedLanguage(value);
    notifyListeners();
  }

  void setStoryCatalogLanguage(String value) {
    _storyCatalogLanguage = PreferenceHelpers.ensureSupportedLanguage(value);
    notifyListeners();
  }
}
