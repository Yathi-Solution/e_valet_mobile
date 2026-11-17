import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/models/operator/operator_dashboard/digital_key_rack_response.dart';

class OperatorDigitalKeyRackApiService {
  OperatorDigitalKeyRackApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<DigitalKeyRackResponse> getDigitalKeyRack({
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

    try {
      final response = await base.get(
        '/operators/dashboard/digital-key-rack',
        queryParameters: {'outletId': outletId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final digitalKeyRack = DigitalKeyRackResponse.fromJson(data);
        return digitalKeyRack;
      } else {
        throw ApiException(
          'Failed to load digital key rack',
          code: 'digital_key_rack_error',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error fetching digital key rack: $e',
        code: 'digital_key_rack_exception',
      );
    }
  }
}
