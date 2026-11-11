import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/oauth/logout_response.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/connectivity/driver_connectivity_log_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/api/driver/my_parked_sessions_api_service.dart';

class LogoutApiService {
  LogoutApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<LogoutResponse> logout() async {
    // Clear locally cached driver cards and parked cars before the logout API call.
    await TokenStorage.clearDriverAssignedCardNumbersIfPresent();
    await MyParkedSessionsApiService.clearCache();

    final accessToken = await TokenStorage.getAccessToken();

    // Upload queued connectivity logs while the access token is still valid.
    await DriverConnectivityLogService.instance.flushPendingIgnoringSchedule();

    LogoutResponse response;
    try {
      if (accessToken != null && accessToken.isNotEmpty) {
        final base = BaseDioService(
          _baseUrl,
          ApiConfig.authorizedHeaders(accessToken),
        );
        // 204 No Content; a 401 just means the session is already gone.
        await base.post('/auth/logout', endSessionOn401: false);
      }
      response = LogoutResponse(message: 'Logged out');
    } on ApiException catch (_) {
      // even if API fails, local logout should continue
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
