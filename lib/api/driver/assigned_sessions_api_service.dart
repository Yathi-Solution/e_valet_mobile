import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/session/assigned_session.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/utils/assigned_sessions_fifo.dart';

class AssignedSessionsApiService {
  AssignedSessionsApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<List<AssignedSession>> fetchAssignedSessions() async {
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
      final response = await base.get('/sessions/assigned-to-me');
      final data = response.data;

      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Invalid response format for assigned sessions.',
          code: 'invalid_response',
        );
      }

      final sessions = (data['sessions'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(AssignedSession.fromJson)
              .toList() ??
          [];

      // Oldest assignment first so polling + sheet [sessions.first] show true "next" FIFO.
      return sortAssignedSessionsFifo(sessions);
    } on ApiException catch (e) {
      print('❌ [GET API] HTTP Status Code: ${e.statusCode ?? 'N/A'}');
      print('❌ [GET API] Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [GET API] Unexpected error: $e');
      throw ApiException(
        'Failed to load assigned sessions.',
        code: 'unknown_error',
      );
    }
  }
}
