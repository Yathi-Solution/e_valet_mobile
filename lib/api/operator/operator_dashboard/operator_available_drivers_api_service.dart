import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/models/operator/operator_dashboard/operator_available_drivers_response.dart';

class OperatorAvailableDriversApiService {
  OperatorAvailableDriversApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<OperatorAvailableDriversResponse> getAvailableDrivers({
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
        '/operators/dashboard/available-drivers',
        queryParameters: {'outletId': outletId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final drivers = OperatorAvailableDriversResponse.fromJson(data);
        return drivers;
      } else {
        throw ApiException(
          'Failed to load available drivers',
          code: 'available_drivers_error',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error fetching available drivers: $e',
        code: 'available_drivers_exception',
      );
    }
  }
}
