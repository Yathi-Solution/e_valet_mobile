import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/operator/operator_valet/valet_logout_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

/// POST /api/v1/operators/drivers/{driverUserId}/force-logout
/// Force-logs out a valet (driver user) from the application.
class ValetLogoutApiService {
  ValetLogoutApiService._();

  // Use valet (main) API base URL, which already includes /api/v1
  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<ValetLogoutResponse> logoutValet(
      {required String userId}) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final headers = ApiConfig.authorizedHeaders(accessToken);

    final base = BaseDioService(_baseUrl, headers);
    // Example: /api/v1/operators/drivers/21/force-logout
    final path = '/operators/drivers/$userId/force-logout';
    const body = <String, dynamic>{};

    try {
      final response = await base.post(path, data: body);

      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ValetLogoutResponse.fromJson(data);
      }
      return ValetLogoutResponse();
    } on ApiException catch (e) {
      print('🔴 VALET FORCE LOGOUT ApiException:');
      print('   message: ${e.message}');
      print('   code: ${e.code}');
      print('   statusCode: ${e.statusCode}');
      rethrow;
    }
  }
}
