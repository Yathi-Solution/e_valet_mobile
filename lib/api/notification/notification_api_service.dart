import 'dart:convert';
import 'dart:developer';
import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/api/core/base_http_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/notification/fcm_register_request.dart';
import 'package:niloufer_valet_mobile/models/notification/fcm_register_response.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

class NotificationApiService extends BaseHttpService {
  NotificationApiService()
      : super(
          baseUrl: ApiConfig.valetBaseUrl,
          defaultHeaders: ApiConfig.defaultJsonHeaders,
        );
  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// Register FCM token with the backend
  Future<FcmRegisterResponse> registerFcmToken(
      FcmRegisterRequest request) async {
    try {
      log('Registering FCM token with backend...');

      // Get access token
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null) {
        throw ApiException(
          'No access token available',
          code: 'no_token',
          statusCode: 401,
        );
      }

      final base = BaseDioService(
        _baseUrl,
        ApiConfig.authorizedHeaders(accessToken),
      );
      try {
        final response = await base.post(
          '/notifications/fcm/register',
          data: request.toJson(),
        );

        log('FCM token registered successfully via Dio');
        final data = response.data as Map<String, dynamic>;
        return FcmRegisterResponse.fromJson(data);
      } on ApiException {
        rethrow;
      }
    } catch (e) {
      log('Error registering FCM token: $e');
      rethrow;
    }
  }

  /// Update FCM token (useful for token refresh)
  Future<FcmRegisterResponse> updateFcmToken(FcmRegisterRequest request) async {
    try {
      log('Updating FCM token with backend...');

      // Get access token
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null) {
        throw ApiException(
          'No access token available',
          code: 'no_token',
          statusCode: 401,
        );
      }

      final response = await postJson(
        '/notifications/fcm/register',
        body: request.toJson(),
        headers: ApiConfig.authorizedHeaders(accessToken),
      );

      log('FCM token updated successfully');
      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      return FcmRegisterResponse.fromJson(responseData);
    } catch (e) {
      log('Error updating FCM token: $e');
      rethrow;
    }
  }
}
