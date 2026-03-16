class PreferenceHelpers {
  static const List<String> supportedLanguages = <String>['en'];
  static const List<String> riddleDifficulties = <String>[
    'easy',
    'medium',
    'hard',
  ];
  static const List<String> riddleCultures = <String>[
    'East African',
    'West African',
    'Central African',
    'Southern African',
    'North African',
  ];

  static String ensureSupportedLanguage(String value) {
    final normalized = value.trim().toLowerCase();
    if (supportedLanguages.contains(normalized)) {
      return normalized;
    }
    return supportedLanguages.first;
  }

  static String? regionFromCulture(String culture) {
    switch (culture.trim().toLowerCase()) {
      case 'east african':
        return 'east-africa';
      case 'west african':
        return 'west-africa';
      case 'central african':
        return 'central-africa';
      case 'southern african':
        return 'southern-africa';
      case 'north african':
        return 'north-africa';
      default:
        return null;
    }
  }
}
