import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/oauth/change_password_request.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

class PasswordApiService {
  PasswordApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// POST /auth/change-password (204). Ends the user's other sessions.
  static Future<void> changePassword(
    ChangePasswordRequest request,
  ) async {
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
    await base.post('/auth/change-password', data: request.toJson());
  }
}
