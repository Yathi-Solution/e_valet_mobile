import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/button_config.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class ConfigApiService {
  ConfigApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<ButtonConfig> getConfig() async {
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
      final response = await base.get('/miscellaneous/config');
      final data = response.data as Map<String, dynamic>;
      return ButtonConfig.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Failed to fetch config. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
