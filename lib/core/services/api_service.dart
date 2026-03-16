import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:hadithi_ai/core/constants/api_constants.dart';
import 'package:hadithi_ai/core/models/riddle_model.dart';
import 'package:hadithi_ai/core/models/story_model.dart';

class ApiService {
  final Dio _dio;

  void _trace(String message, {Object? error, StackTrace? stackTrace}) {
    dev.log(message, name: 'API SERVICE', error: error, stackTrace: stackTrace);
  }

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: const Duration(seconds: 20),
          sendTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 45),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          final shouldRetry =
              error.type == DioExceptionType.connectionTimeout ||
              error.type == DioExceptionType.receiveTimeout ||
              error.type == DioExceptionType.sendTimeout;

          final request = error.requestOptions;
          final retryCount = (request.extra['retry_count'] as int?) ?? 0;

          if (shouldRetry && retryCount < 1) {
            request.extra['retry_count'] = retryCount + 1;
            _trace(
              'interceptor: retry ${request.method} ${request.path} attempt=${retryCount + 1}',
            );
            final response = await _dio.fetch(request);
            return handler.resolve(response);
          }

          _trace(
            'interceptor: request failed ${request.method} ${request.path}',
            error: error,
            stackTrace: error.stackTrace,
          );
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> createSession({
    String language = 'en',
    String? region,
    String ageGroup = 'adult',
  }) async {
    try {
      _trace(
        'createSession: language=$language ageGroup=$ageGroup region=$region',
      );
      return await _dio.post(
        '/api/v1/sessions',
        data: {'language': language, 'region': region, 'age_group': ageGroup},
      );
    } on DioException catch (e) {
      _trace('createSession: failed', error: e, stackTrace: e.stackTrace);
      throw _wrapDioException(e);
    }
  }

  Future<Response> getSession(String sessionId) async {
    try {
      _trace('getSession: sessionId=$sessionId');
      return await _dio.get('/api/v1/sessions/$sessionId');
    } on DioException catch (e) {
      _trace('getSession: failed', error: e, stackTrace: e.stackTrace);
      throw _wrapDioException(e);
    }
  }

  Future<Response> deleteSession(String sessionId) async {
    try {
      _trace('deleteSession: sessionId=$sessionId');
      return await _dio.delete('/api/v1/sessions/$sessionId');
    } on DioException catch (e) {
      _trace('deleteSession: failed', error: e, stackTrace: e.stackTrace);
      throw _wrapDioException(e);
    }
  }

  Future<Response> updateSessionPreferences({
    required String sessionId,
    String? language,
    String? ageGroup,
    String? region,
  }) async {
    final payload = <String, dynamic>{};
    if (language != null && language.trim().isNotEmpty) {
      payload['language'] = language.trim();
    }
    if (ageGroup != null && ageGroup.trim().isNotEmpty) {
      payload['age_group'] = ageGroup.trim();
    }
    if (region != null && region.trim().isNotEmpty) {
      payload['region'] = region.trim();
    }

    try {
      _trace(
        'updateSessionPreferences: sessionId=$sessionId payloadKeys=${payload.keys.toList()}',
      );
      return await _dio.post(
        '/api/v1/sessions/$sessionId/preferences',
        data: payload,
      );
    } on DioException catch (e) {
      _trace(
        'updateSessionPreferences: failed',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw _wrapDioException(e);
    }
  }

  Future<Response> getSessionHistory({
    required String sessionId,
    int limit = 50,
  }) async {
    try {
      _trace('getSessionHistory: sessionId=$sessionId limit=$limit');
      return await _dio.get(
        '/api/v1/sessions/$sessionId/history',
        queryParameters: {'limit': limit},
      );
    } on DioException catch (e) {
      _trace('getSessionHistory: failed', error: e, stackTrace: e.stackTrace);
      throw _wrapDioException(e);
    }
  }

  Future<Response> listAgents() async {
    try {
      _trace('listAgents: request');
      return await _dio.get('/api/v1/agents');
    } on DioException catch (e) {
      _trace('listAgents: failed', error: e, stackTrace: e.stackTrace);
      throw _wrapDioException(e);
    }
  }

  Future<String> getStoryDaystoryContent({
    required StoryModel story,
    String? language,
  }) async {
    final payload = story.toGenerationPayload(overrideLanguage: language);

    try {
      _trace(
        'getStoryDaystoryContent: id=${story.id} title=${story.title} language=${payload['language']} region=${story.region}',
      );

      final response = await _dio.post(
        '/api/v1/stories/daystory',
        data: payload,
      );
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        _trace(
          'getStoryDaystoryContent: unexpected payload type=${data.runtimeType}',
        );
        return '';
      }

      final content = (data['content']?.toString() ?? '').trim();
      _trace(
        'getStoryDaystoryContent: received content chars=${content.length}',
      );
      return content;
    } on DioException catch (e) {
      _trace(
        'getStoryDaystoryContent: failed',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw _wrapDioException(e);
    }
  }

  Future<String> getStoryDaystoryImage({
    required StoryModel story,
    String? language,
  }) async {
    final payload = story.toImageGenerationPayload(overrideLanguage: language);

    try {
      _trace(
        'getStoryDaystoryImage: id=${story.id} title=${story.title} language=${payload['language']}',
      );

      final response = await _dio.post(
        '/api/v1/stories/daystory/image',
        data: payload,
      );
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        _trace(
          'getStoryDaystoryImage: unexpected payload type=${data.runtimeType}',
        );
        return '';
      }

      // Prefer image_url if available, fallback to image_base64 or generic url
      final imageUrl = (data['image_url']?.toString() ?? '').trim();
      if (imageUrl.isNotEmpty) {
        _trace(
          'getStoryDaystoryImage: received image_url url_length=${imageUrl.length}',
        );
        return imageUrl;
      }

      final genericImage = (data['image']?.toString() ?? '').trim();
      if (genericImage.isNotEmpty) {
        _trace(
          'getStoryDaystoryImage: received image url_length=${genericImage.length}',
        );
        return genericImage;
      }

      final imageBase64 = (data['image_base64']?.toString() ?? '').trim();
      _trace(
        'getStoryDaystoryImage: received image_base64 length=${imageBase64.length}',
      );
      return imageBase64;
    } on DioException catch (e) {
      _trace(
        'getStoryDaystoryImage: failed',
        error: e,
        stackTrace: e.stackTrace,
      );
      throw _wrapDioException(e);
    }
  }

  Future<RiddleModel?> generateRiddle({
    String culture = 'East African',
    String difficulty = 'medium',
    String language = 'en',
  }) async {
    final payload = <String, dynamic>{
      'culture': culture,
      'difficulty': difficulty,
      'language': language,
    };

    try {
      _trace(
        'generateRiddle: culture=$culture difficulty=$difficulty language=$language',
      );
      final response = await _dio.post(
        '/api/v1/riddles/generate',
        data: payload,
      );
      final data = response.data;

      final Map<String, dynamic>? payloadMap;
      if (data is Map<String, dynamic>) {
        if (data['data'] is Map<String, dynamic>) {
          payloadMap = data['data'] as Map<String, dynamic>;
        } else {
          payloadMap = data;
        }
      } else {
        payloadMap = null;
      }

      if (payloadMap == null) {
        _trace('generateRiddle: invalid payload type=${data.runtimeType}');
        return null;
      }

      final parsed = RiddleModel.fromApiPayload(
        payloadMap,
        fallbackId: 'riddle_${DateTime.now().millisecondsSinceEpoch}',
      );
      _trace('generateRiddle: parsed=${parsed != null}');
      return parsed;
    } on DioException catch (e) {
      _trace('generateRiddle: failed', error: e, stackTrace: e.stackTrace);
      throw _wrapDioException(e);
    }
  }

  Future<Map<String, dynamic>> verifyRiddleAnswer({
    required String riddleId,
    required String selectedAnswer,
  }) async {
    try {
      _trace('verifyRiddleAnswer: riddleId=$riddleId answer=$selectedAnswer');
      final response = await _dio.post(
        '/api/v1/riddles/$riddleId/answer',
        data: {'selected_answer': selectedAnswer},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data;
      }
      return <String, dynamic>{};
    } on DioException catch (e) {
      _trace('verifyRiddleAnswer: failed', error: e, stackTrace: e.stackTrace);
      throw _wrapDioException(e);
    }
  }

  DioException _wrapDioException(DioException error) {
    final code = error.response?.statusCode;

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error:
              'Request timeout. Verify API availability and internet connection.',
        );
      case DioExceptionType.connectionError:
        return DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: 'Network error while contacting API. Check connectivity.',
        );
      case DioExceptionType.badResponse:
        return DioException(
          requestOptions: error.requestOptions,
          response: error.response,
          type: error.type,
          error: 'API responded with HTTP ${code ?? 'unknown'}',
        );
      default:
        return error;
    }
  }
}
