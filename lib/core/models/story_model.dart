class StoryModel {
  final String id;
  final String title;
  final String content;
  final String summary;
  final String language;
  final String region;
  final String month;
  final int day;
  final String imageUrl;

  const StoryModel({
    required this.id,
    required this.title,
    required this.content,
    required this.summary,
    required this.month,
    required this.day,
    this.language = 'en',
    this.imageUrl = '',
    this.region = '',
  });

  bool get isEmpty => content.isEmpty;

  /// Canonical payload for daystory endpoints.
  /// Includes all required fields for story generation tasks.
  Map<String, dynamic> toGenerationPayload({
    String? overrideContent,
    String? overrideLanguage,
  }) {
    final normalizedLanguage = (overrideLanguage ?? language).trim();

    return <String, dynamic>{
      'id': id.trim(),
      'title': title.trim(),
      'content': (overrideContent ?? content).trim(),
      'summary': summary.trim(),
      'language': normalizedLanguage.isEmpty ? 'en' : normalizedLanguage,
      'region': region.trim(),
    };
  }

  /// Payload contract for /api/v1/stories/daystory/image endpoint.
  /// This endpoint accepts metadata only.
  Map<String, dynamic> toImageGenerationPayload({String? overrideLanguage}) {
    final normalizedLanguage = (overrideLanguage ?? language).trim();

    return <String, dynamic>{
      'id': id.trim(),
      'title': title.trim(),
      'summary': summary.trim(),
      'language': normalizedLanguage.isEmpty ? 'en' : normalizedLanguage,
    };
  }

  static const empty = StoryModel(
    id: '',
    title: '',
    content: '',
    summary: '',
    month: '',
    day: 0,
  );

  StoryModel copyWith({
    String? id,
    String? title,
    String? content,
    String? summary,
    String? language,
    String? imageUrl,
    String? region,
    String? month,
    int? day,
  }) {
    return StoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      summary: summary ?? this.summary,
      imageUrl: imageUrl ?? this.imageUrl,
      language: language ?? this.language,
      region: region ?? this.region,
      month: month ?? this.month,
      day: day ?? this.day,
    );
  }

  factory StoryModel.fromCatalogJson(
    Map<String, dynamic> json, {
    int index = 0,
  }) {
    final title = (json['title']?.toString() ?? '').trim();
    final content = (json['content']?.toString() ?? '').trim();
    final description = (json['summary'] ?? json['description'] ?? '')
        .toString()
        .trim();
    final language = (json['language']?.toString() ?? 'en').trim();
    final imageUrl = (json['imageUrl'] ?? json['image_url'] ?? '')
        .toString()
        .trim();
    final day = _asInt(json['day']) ?? 0;
    final month = _normalizeMonth((json['month'] ?? '').toString());
    final region = (json['region']?.toString() ?? '').trim();

    final resolvedId = (json['id']?.toString().trim().isNotEmpty == true)
        ? json['id'].toString().trim()
        : 'api_story_${day}_${month}_${region.replaceAll(' ', '_')}_$index';

    return StoryModel(
      id: resolvedId,
      title: title,
      content: content,
      summary: description,
      language: language.isEmpty ? 'en' : language,
      imageUrl: imageUrl,
      day: day,
      month: month,
      region: region,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _normalizeMonth(String month) {
    final raw = month.trim().toLowerCase();
    const map = <String, String>{
      'jan': 'Jan',
      'january': 'Jan',
      'janvier': 'Jan',
      'feb': 'Feb',
      'february': 'Feb',
      'fevrier': 'Feb',
      'février': 'Feb',
      'mar': 'Mar',
      'march': 'Mar',
      'mars': 'Mar',
      'apr': 'Apr',
      'april': 'Apr',
      'avril': 'Apr',
      'may': 'May',
      'mai': 'May',
      'jun': 'Jun',
      'june': 'Jun',
      'juin': 'Jun',
      'jul': 'Jul',
      'july': 'Jul',
      'juillet': 'Jul',
      'aug': 'Aug',
      'august': 'Aug',
      'aout': 'Aug',
      'août': 'Aug',
      'sep': 'Sep',
      'sept': 'Sep',
      'september': 'Sep',
      'septembre': 'Sep',
      'oct': 'Oct',
      'october': 'Oct',
      'octobre': 'Oct',
      'nov': 'Nov',
      'november': 'Nov',
      'novembre': 'Nov',
      'dec': 'Dec',
      'december': 'Dec',
      'decembre': 'Dec',
      'décembre': 'Dec',
    };
    return map[raw] ?? month.trim();
  }
}
