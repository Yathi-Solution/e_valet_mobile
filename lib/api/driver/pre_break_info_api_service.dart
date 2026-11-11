import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/pre_break/pre_break_info_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class PreBreakInfoApiService {
  PreBreakInfoApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<PreBreakInfoResponse> getPreBreakInfo() async {
    final startedAt = DateTime.now();
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
      final response = await base.get('/drivers/pre-break/info');
      final data = response.data as Map<String, dynamic>;
      final parsed = PreBreakInfoResponse.fromJson(data);

      return parsed;
    } on ApiException catch (e) {
      final ms = DateTime.now().difference(startedAt).inMilliseconds;
      print(
        '🟣 PREBREAK GET ApiException (${ms}ms): code=${e.code} message=${e.message}',
      );
      rethrow;
    } catch (e) {
      final ms = DateTime.now().difference(startedAt).inMilliseconds;
      print('🟣 PREBREAK GET unknown error (${ms}ms): $e');
      throw ApiException(
        'Failed to fetch pre-break info. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
