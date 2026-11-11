import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/operator/operator_dashboard/assign_retrieval_request.dart';
import 'package:evalet/models/operator/operator_dashboard/assign_retrieval_response.dart';
import 'package:evalet/models/operator/operator_dashboard/assign_retrieval_status_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class OperatorAssignRetrievalApiService {
  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// GET assignment/retrieval status for a session. Used by driver app to poll
  /// when operator changes status in Car Logs (e.g. ARRIVED, PARKED, COMPLETED).
  static Future<AssignRetrievalStatusResponse?> getAssignmentStatus({
    required String sessionId,
  }) async {
    try {
      final accessToken = await TokenStorage.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) {
        return null;
      }
      final base = BaseDioService(
        _baseUrl,
        ApiConfig.authorizedHeaders(accessToken),
      );
      final response = await base.get(
        '/operators/assign-retrieval',
        queryParameters: {'sessionId': sessionId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return AssignRetrievalStatusResponse.fromJson(data);
      }
      if (data is List &&
          data.isNotEmpty &&
          data.first is Map<String, dynamic>) {
        return AssignRetrievalStatusResponse.fromJson(
          data.first as Map<String, dynamic>,
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<AssignRetrievalResponse> assignRetrieval({
    required AssignRetrievalRequest request,
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
        _baseUrl,
        ApiConfig.authorizedHeaders(accessToken),
      );
      final response = await base.post(
        '/operators/assign-retrieval',
        data: request.toJson(),
      );

      return AssignRetrievalResponse.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to assign retrieval: $e');
    }
  }
}
