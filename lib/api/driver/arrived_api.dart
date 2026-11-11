import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/session/arrived_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class ArrivedApiService {
  ArrivedApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<ArrivedResponse> confirmArrival({
    required String sessionId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      print('❌ No access token found');
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
      final requestBody = {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
      };

      final response = await base.post(
        '/sessions/$sessionId/arrived',
        data: requestBody,
      );

      final data = response.data as Map<String, dynamic>;

      return ArrivedResponse.fromJson(data);
    } on ApiException catch (e) {
      print('❌ [ARRIVED API] HTTP Status Code: ${e.statusCode ?? 'N/A'}');
      print('❌ [ARRIVED API] API Exception: ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ [ARRIVED API] Unexpected error: $e');
      throw ApiException(
        'Failed to confirm arrival. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
