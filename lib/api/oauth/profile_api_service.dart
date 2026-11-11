import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/models/oauth/profile_response.dart';

class ProfileApiService {
  ProfileApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// GET /auth/me (Client token).
  static Future<ProfileResponse> getProfile() async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException('Access token not found. Please login again.',
          code: 'no_token');
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );
    final response = await base.get('/auth/me');
    return ProfileResponse.fromMe(response.data as Map<String, dynamic>);
  }
}
