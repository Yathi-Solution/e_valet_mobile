import 'dart:convert';
import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_http_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/oauth/logout_response.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/connectivity/driver_connectivity_log_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/api/driver/my_parked_sessions_api_service.dart';

class LogoutApiService {
  LogoutApiService._();

  static String get _baseUrl => ApiConfig.authBaseUrl;
  static String get _apiKey => ApiConfig.authApiKey;

  static Future<LogoutResponse> logout() async {
    // Clear locally cached driver cards and parked cars before the logout API call.
    await TokenStorage.clearDriverAssignedCardNumbersIfPresent();
    await MyParkedSessionsApiService.clearCache();

    final refreshToken = await TokenStorage.getRefreshToken();

    final headers = <String, String>{
      'Accept': '*/*',
      'X-API-Key': _apiKey,
      if (refreshToken != null && refreshToken.isNotEmpty)
        'Authorization': 'Bearer $refreshToken',
    };

    final http = BaseHttpService(
      baseUrl: _baseUrl,
      defaultHeaders: headers,
    );

    // Upload queued connectivity logs while the valet access token is still valid.
    await DriverConnectivityLogService.instance.flushPendingIgnoringSchedule();

    LogoutResponse response;
    try {
      final httpResponse = await http.postJson(
        '/auth/logout',
        body: '',
      ); // throws ApiException on failure

      final json = jsonDecode(httpResponse.body) as Map<String, dynamic>;
      response = LogoutResponse.fromJson(json);
    } on ApiException catch (_) {
      // even if API fails, local logout should continue
      // Return a default response
      response = LogoutResponse(message: 'Logged out locally');
    } catch (_) {
      response = LogoutResponse(message: 'Logged out locally');
    }

    // Always clear local tokens and session, even if API call failed
    await TokenStorage.clearAll();
    await DriverConnectivityLogService.instance.clearOnLogout();
    await SessionManager.clearSessionFlags();

    return response;
  }
}
