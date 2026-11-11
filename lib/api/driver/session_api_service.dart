import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/session/checkin_request.dart';
import 'package:evalet/models/driver/session/checkin_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class SessionApiService {
  SessionApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<CheckinResponse> checkin(CheckinRequest request) async {
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
        '/sessions/checkin',
        data: request.toJson(),
      );

      final data = response.data as Map<String, dynamic>;
      return CheckinResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Failed to check in. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
