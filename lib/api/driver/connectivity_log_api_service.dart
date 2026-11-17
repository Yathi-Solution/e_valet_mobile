import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/connectivity/connectivity_log_batch_request.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

/// Driver connectivity batch log (online / offline transitions).
class ConnectivityLogApiService {
  ConnectivityLogApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<void> postBatch(ConnectivityLogBatchRequest body) async {
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

    await base.post(
      '/connectivity/log/batch',
      data: body.toJson(),
    );
  }
}
