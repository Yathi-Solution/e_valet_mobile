import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/models/operator/operator_dashboard/car_logs_kpis_response.dart';
import 'package:evalet/models/operator/operator_dashboard/car_logs_response.dart';

class OperatorCarLogsApiService {
  OperatorCarLogsApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<CarLogsKpisResponse> getCarLogsKpis({
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
        '/operators/car-logs/kpis',
        queryParameters: {
          'outletId': int.tryParse(outletId) ?? 1,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          final message =
              data is String ? data : 'Invalid response format from server.';
          throw ApiException(
            message,
            code: 'car_logs_kpis_error',
            statusCode: response.statusCode,
          );
        }
        return CarLogsKpisResponse.fromJson(data);
      } else {
        throw ApiException(
          'Failed to load car logs KPIs. Status: ${response.statusCode}',
          code: 'car_logs_kpis_error',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error fetching car logs KPIs: $e',
        code: 'car_logs_kpis_exception',
      );
    }
  }

  static Future<CarLogsResponse> getCarLogs({
    required String outletId,
    int page = 1,
    int pageSize = 10,
    String? search,
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
      final queryParams = <String, dynamic>{
        'outletId': int.tryParse(outletId) ?? 1,
        'page': page,
        'pageSize': pageSize,
      };
      if (search != null && search.trim().isNotEmpty) {
        queryParams['search'] = search.trim();
      }
      final response = await base.get(
        '/operators/car-logs',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          final message =
              data is String ? data : 'Invalid response format from server.';
          throw ApiException(
            message,
            code: 'car_logs_error',
            statusCode: response.statusCode,
          );
        }
        final carLogs = CarLogsResponse.fromJson(data);
        return carLogs;
      } else {
        throw ApiException(
          'Failed to load car logs. Status: ${response.statusCode}',
          code: 'car_logs_error',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error fetching car logs: $e',
        code: 'car_logs_exception',
      );
    }
  }
}
