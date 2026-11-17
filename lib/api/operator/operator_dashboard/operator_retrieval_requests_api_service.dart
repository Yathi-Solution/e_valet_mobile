import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/models/operator/operator_dashboard/retrieval_requests_response.dart';

class OperatorRetrievalRequestsApiService {
  OperatorRetrievalRequestsApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<RetrievalRequestsResponse> getRetrievalRequests({
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
        '/operators/dashboard/retrieval-requests',
        queryParameters: {'outletId': outletId},
      );

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final retrievalRequests = RetrievalRequestsResponse.fromJson(data);
        return retrievalRequests;
      } else {
        throw ApiException(
          'Failed to load retrieval requests',
          code: 'retrieval_requests_error',
        );
      }
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error fetching retrieval requests: $e',
        code: 'retrieval_requests_exception',
      );
    }
  }
}
