import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/re-park/initiate_repark_request.dart';
import 'package:evalet/models/driver/re-park/initiate_repark_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class InitiateReparkApiService {
  InitiateReparkApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// Initiate repark for a session
  /// POST /api/v1/sessions/{sessionId}/initiate-repark
  static Future<InitiateReparkResponse> initiateRepark({
    required String sessionId,
    required InitiateReparkRequest request,
  }) async {
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
      final response = await base.post(
        '/sessions/$sessionId/initiate-repark',
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      return InitiateReparkResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Failed to initiate repark. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
