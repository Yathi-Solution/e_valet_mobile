import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class PassParkedSessionsApiService {
  PassParkedSessionsApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// POST /drivers/pass-parked-sessions
  /// Body:
  /// {
  ///   "passes": [
  ///     { "sessionId": "...", "passedToDriverUserId": "..." }
  ///   ]
  /// }
  static Future<int> passParkedSessions({
    required List<String> sessionIds,
    required String passedToDriverUserId,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }
    final cleanedSessionIds = sessionIds
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleanedSessionIds.isEmpty) {
      throw ApiException(
        'No parked sessions available to pass.',
        code: 'no_sessions',
      );
    }

    final targetDriverId = passedToDriverUserId.trim();
    if (targetDriverId.isEmpty) {
      throw ApiException(
        'Please select a driver.',
        code: 'invalid_driver',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    final payload = {
      'passes': cleanedSessionIds
          .map(
            (sessionId) => {
              'sessionId': sessionId,
              'passedToDriverUserId': targetDriverId,
            },
          )
          .toList(growable: false),
    };

    try {
      final response =
          await base.post('/drivers/pass-parked-sessions', data: payload);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        final results = data['results'];
        if (results is List) {
          return results.length;
        }
      }
      return cleanedSessionIds.length;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Failed to pass parked sessions. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
