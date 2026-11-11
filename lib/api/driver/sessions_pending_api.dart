import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/session/pending_sessions_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class SessionsPendingApiService {
  SessionsPendingApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// Get pending sessions for the driver
  /// Returns PendingSessionsResponse containing list of pending sessions
  static Future<PendingSessionsResponse> getPendingSessions() async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.get('/sessions/pending');

      final data = response.data as Map<String, dynamic>;
      final pendingSessionsResponse = PendingSessionsResponse.fromJson(data);
      return pendingSessionsResponse;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Failed to fetch pending sessions. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
