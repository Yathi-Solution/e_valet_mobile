import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/models/operator/operator_dashboard/update_session_status_response.dart';

class OperatorUpdateSessionApiService {
  OperatorUpdateSessionApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<UpdateSessionStatusResponse> updateSessionStatus(
      {required String sessionId, required String newStatus}) async {
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
      final response = await base.patch(
        '/operators/update-session',
        data: {
          'sessionId': sessionId,
          'newStatus': newStatus,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          final message =
              data is String ? data : 'Invalid response format from server.';
          throw ApiException(
            message,
            code: 'update_session_error',
            statusCode: response.statusCode,
          );
        }
        final updateResponse = UpdateSessionStatusResponse.fromJson(data);
        return updateResponse;
      } else {
        throw ApiException(
          'Failed to update session status. Status: ${response.statusCode}',
          code: 'update_session_error',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error updating session status: $e',
        code: 'update_session_exception',
      );
    }
  }
}
