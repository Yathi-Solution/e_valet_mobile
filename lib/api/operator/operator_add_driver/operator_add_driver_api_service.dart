import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/operator/operator_add_driver/add_driver_request.dart';
import 'package:evalet/models/operator/operator_add_driver/add_driver_response.dart';
import 'package:evalet/models/operator/operator_add_driver/client_outlet.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

/// Operator "Add Driver" endpoints:
///  - GET  /operators/client-outlets
///  - POST /operators/drivers
///  - POST /operators/drivers/:userId/invitation
class OperatorAddDriverApiService {
  OperatorAddDriverApiService._();

  static Future<BaseDioService> _client() async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }
    return BaseDioService(
      ApiConfig.valetBaseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );
  }

  /// Every active Outlet of the Client (not only the Operator's own), by name.
  static Future<List<ClientOutlet>> getClientOutlets() async {
    final base = await _client();
    final response = await base.get('/operators/client-outlets');
    final data = response.data;
    final list = data is List
        ? data
        : (data is Map ? (data['outlets'] ?? data['data']) : null);
    if (list is! List) {
      throw ApiException(
        'Unexpected response format for client-outlets',
        code: 'client_outlets_bad_response',
        statusCode: response.statusCode,
      );
    }
    return list
        .whereType<Map<String, dynamic>>()
        .map(ClientOutlet.fromJson)
        .toList();
  }

  static Future<AddDriverResponse> addDriver(AddDriverRequest request) async {
    final base = await _client();
    final response =
        await base.post('/operators/drivers', data: request.toJson());
    final data = response.data;
    if (data is Map<String, dynamic>) {
      return AddDriverResponse.fromJson(data);
    }
    throw ApiException(
      'Unexpected response format for add driver',
      code: 'add_driver_bad_response',
      statusCode: response.statusCode,
    );
  }

  /// Sends a fresh Invitation; the previous link stops working.
  /// Limited to 5 per User per hour (shared with Client Admin resends).
  static Future<void> resendInvitation(String userId) async {
    final base = await _client();
    await base.post(
      '/operators/drivers/${Uri.encodeComponent(userId)}/invitation',
    );
  }
}
