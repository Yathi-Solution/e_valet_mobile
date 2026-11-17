import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/operator/operator_dashboard/auto_assign_settings_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

/// GET /operators/settings/auto-assign?outletId={outletId} (base URL includes /api/v1)
class OperatorAutoAssignApiService {
  OperatorAutoAssignApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<AutoAssignSettingsResponse> getAutoAssignSettings({
    required String outletId,
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

    final response = await base.get(
      '/operators/settings/auto-assign',
      queryParameters: {'outletId': outletId},
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return AutoAssignSettingsResponse.fromJson(data);
    } else {
      throw ApiException(
        'Failed to load auto-assign settings',
        code: 'auto_assign_settings_error',
      );
    }
  }

  /// PATCH /operators/settings/auto-assign?outletId={outletId}
  /// Request body: { "enabled": true | false }
  /// Response (200): { "outletId", "autoAssignEnabled", "message" }
  static Future<AutoAssignSettingsResponse> patchAutoAssignSettings({
    required String outletId,
    required bool enabled,
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

    final response = await base.patch(
      '/operators/settings/auto-assign',
      queryParameters: {'outletId': outletId},
      data: <String, dynamic>{'enabled': enabled},
    );

    if (response.statusCode == 200) {
      final data = response.data as Map<String, dynamic>;
      return AutoAssignSettingsResponse.fromJson(data);
    } else {
      throw ApiException(
        'Failed to update auto-assign settings',
        code: 'auto_assign_patch_error',
      );
    }
  }
}
