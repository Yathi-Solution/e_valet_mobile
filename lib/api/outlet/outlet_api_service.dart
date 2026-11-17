import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/outlet/outlet.dart';
import 'package:evalet/models/outlet/verify_location_request.dart';
import 'package:evalet/models/outlet/verify_location_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class OutletApiService {
  OutletApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// Fetches all available outlets.
  static Future<List<Outlet>> getOutlets() async {
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
      final response = await base.get('/outlets');
      final data = response.data as Map<String, dynamic>;
      final list = data['outlets'] as List<dynamic>;
      return list
          .map((e) => Outlet.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Failed to fetch outlets. Please try again.',
        code: 'unknown_error',
      );
    }
  }

  /// Verifies whether the user is within the allowed radius of the given outlet.
  /// Used by Operator and Scanner roles after outlet selection.
  static Future<VerifyLocationResponse> verifyLocation(
    int outletId,
    VerifyLocationRequest request,
  ) async {
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
      final response = await base.post(
        '/outlets/$outletId/verify-location',
        data: request.toJson(),
      );
      final data = response.data as Map<String, dynamic>;
      return VerifyLocationResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Failed to verify location. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
