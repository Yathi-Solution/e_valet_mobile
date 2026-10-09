import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/connectivity/connectivity_driver_settings_response.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

/// API service for driver connectivity settings.
/// Used after login to determine if connectivity logging / related features are enabled for this driver.
///
/// IMPORTANT: Always call this with a fresh outletId after successful login for drivers.
/// Previous local settings must be cleared before storing the new response.
class ConnectivitySettingsApiService {
  ConnectivitySettingsApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// GET /connectivity/settings/me?outletId=...
  ///
  /// Fetches the current driver's connectivity settings for the given outlet.
  /// This must be called after every successful driver login.
  ///
  /// On success: silent (no logs).
  /// Only logs on errors.
  static Future<ConnectivityDriverSettingsResponse?> getDriverConnectivitySettings({
    required int outletId,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      // Silent skip on no token (not an error for this non-critical call)
      return null;
    }

    if (outletId <= 0) {
      // Silent skip on invalid outlet (not an error)
      return null;
    }

    // Build query param path
    final path = '/connectivity/settings/me?outletId=$outletId';

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.get(path);

      final rawData = response.data;

      if (rawData is Map<String, dynamic>) {
        return ConnectivityDriverSettingsResponse.fromJson(rawData);
      }

      if (rawData is List && rawData.isNotEmpty && rawData.first is Map<String, dynamic>) {
        return ConnectivityDriverSettingsResponse.fromJson(
          rawData.first as Map<String, dynamic>,
        );
      }

      // Unexpected shape — treat as non-fatal, no log on success path
      return null;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final data = e.response?.data;

      log('═══════════════════════════════════════════════════════════════');
      log('[ConnectivitySettings] !!! DIO ERROR');
      log('[ConnectivitySettings] Status Code : ${status ?? 'N/A'}');
      log('[ConnectivitySettings] Error Data  : $data');
      log('[ConnectivitySettings] Message     : ${e.message}');
      log('═══════════════════════════════════════════════════════════════');

      return null;
    } on ApiException catch (e) {
      log('═══════════════════════════════════════════════════════════════');
      log('[ConnectivitySettings] !!! API EXCEPTION');
      log('[ConnectivitySettings] Status Code : ${e.statusCode ?? 'N/A'}');
      log('[ConnectivitySettings] Message     : ${e.message}');
      log('═══════════════════════════════════════════════════════════════');
      return null;
    } catch (e, st) {
      log('═══════════════════════════════════════════════════════════════');
      log('[ConnectivitySettings] !!! UNEXPECTED ERROR');
      log('[ConnectivitySettings] Error : $e');
      log('[ConnectivitySettings] Stack : $st');
      log('═══════════════════════════════════════════════════════════════');
      return null;
    }
  }
}
