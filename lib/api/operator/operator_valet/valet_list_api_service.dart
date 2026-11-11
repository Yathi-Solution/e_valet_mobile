import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/operator/operator_valet/valet_list_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class ValetListApiService {
  /// Get valet list for a specific outlet
  static Future<ValetListResponse> getValets({
    required String outletId,
  }) async {
    try {
      final accessToken = await TokenStorage.getAccessToken();

      if (accessToken == null || accessToken.isEmpty) {
        throw ApiException(
          'Access token not found. Please login again.',
          code: 'no_token',
        );
      }
      final base = BaseDioService(
        ApiConfig.valetBaseUrl,
        ApiConfig.authorizedHeaders(accessToken),
      );

      final response = await base.get(
        '/operators/valets',
        queryParameters: {'outletId': outletId},
      );
      return ValetListResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Error fetching valets: $e');
    }
  }
}
