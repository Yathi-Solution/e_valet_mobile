import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/operator/operator_overtime/grant_overtime_request.dart';
import 'package:evalet/models/operator/operator_overtime/grant_overtime_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

/// POST /api/v1/operators/drivers/grant-overtime
class GrantOvertimeApiService {
  GrantOvertimeApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<GrantOvertimeResponse> grantOvertime({
    required GrantOvertimeRequest request,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final headers = ApiConfig.authorizedHeaders(accessToken);
    final base = BaseDioService(_baseUrl, headers);
    const path = '/operators/drivers/grant-overtime';
    final body = request.toJson();

    try {
      final response = await base.post(path, data: body);
      final data = response.data;

      if (data is Map<String, dynamic>) {
        return GrantOvertimeResponse.fromJson(data);
      }

      throw ApiException(
        'Unexpected response format for grant-overtime',
        code: 'grant_overtime_bad_response',
        statusCode: response.statusCode,
      );
    } on ApiException catch (e) {
      print('🔴 GRANT OVERTIME ApiException:');
      print('   message: ${e.message}');
      print('   code: ${e.code}');
      print('   statusCode: ${e.statusCode}');
      rethrow;
    } catch (e) {
      print('🔴 GRANT OVERTIME unknown error: $e');
      throw ApiException(
        'Failed to grant overtime: $e',
        code: 'grant_overtime_error',
      );
    }
  }
}
