import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';

/// Response from GET /app-version/build-number.
class AppVersionResponse {
  final String buildNumber;

  const AppVersionResponse({required this.buildNumber});

  factory AppVersionResponse.fromJson(Map<String, dynamic> json) {
    final buildNumber = json['buildNumber'] as String? ?? '';
    return AppVersionResponse(buildNumber: buildNumber);
  }
}

/// API for app version check (public, no auth).
class AppVersionApiService {
  AppVersionApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// GET app-version/build-number. Throws [ApiException] on network/HTTP error.
  static Future<AppVersionResponse> getBuildNumber() async {
    final base = BaseDioService(
      _baseUrl,
      ApiConfig.defaultJsonHeaders,
    );
    final response = await base.get(
      '/app-version/build-number',
      endSessionOn401: false,
    );
    final data = response.data as Map<String, dynamic>?;
    if (data == null) {
      throw ApiException(
        'Invalid response from version API',
        code: 'invalid_response',
      );
    }
    return AppVersionResponse.fromJson(data);
  }
}
