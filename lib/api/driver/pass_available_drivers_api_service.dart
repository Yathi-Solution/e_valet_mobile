import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/session/pass_available_driver.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

class PassAvailableDriversApiService {
  PassAvailableDriversApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// The API has no per-session driver list; the online colleagues a Driver can
  /// hand work to come from GET /drivers/pre-break/info (group first, then the
  /// rest of the outlet).
  static Future<List<PassAvailableDriver>> getAvailableDrivers({
    required String sessionId,
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
      final response = await base.get('/drivers/pre-break/info');

      final data = response.data as Map<String, dynamic>;
      final seen = <String>{};
      final drivers = <PassAvailableDriver>[];
      for (final key in const ['groupDrivers', 'outletDrivers']) {
        for (final d in (data[key] as List<dynamic>? ?? const [])) {
          if (d is! Map<String, dynamic>) continue;
          final id = (d['driverUserId'] ?? '').toString();
          if (id.isEmpty || !seen.add(id)) continue;
          drivers.add(PassAvailableDriver(
            userId: id,
            name: (d['name'] ?? 'Unknown Driver').toString(),
            phone: (d['phone'] ?? 'N/A').toString(),
          ));
        }
      }
      return drivers;
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Failed to load available drivers: $e',
        code: 'pass_drivers_error',
      );
    }
  }

  /// Without [driverUserId]: POST /sessions/{sessionId}/pass (no body, the
  /// server picks a Driver). With it: POST /drivers/pass-parked-sessions to that
  /// Driver, which also accepts ACCEPTED / ARRIVED retrievals.
  /// Response: { "sessionId", "newAssignmentId", "assignedTo", "assignedAt", "message" }
  static Future<String> passSessionToDriver({
    required String sessionId,
    String? driverUserId,
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
      if (driverUserId != null && driverUserId.isNotEmpty) {
        final res = await base.post('/drivers/pass-parked-sessions', data: {
          'passes': [
            {'sessionId': sessionId, 'passedToDriverUserId': driverUserId},
          ],
        });
        final body = res.data as Map<String, dynamic>?;
        final errors = body?['errors'] as List<dynamic>? ?? const [];
        if (errors.isNotEmpty) {
          final first = errors.first as Map<String, dynamic>;
          throw ApiException(
            (first['reason'] ?? 'Failed to pass session.').toString(),
            code: 'pass_session_error',
          );
        }
        return 'Request passed successfully.';
      }

      final response = await base.post('/sessions/$sessionId/pass');

      final data = response.data as Map<String, dynamic>?;
      return (data?['message'] as String?) ?? 'Request passed successfully.';
    } on ApiException catch (e) {
      print('[PASS API] ApiException');
      print('[PASS API] Status: ${e.statusCode ?? 'N/A'}');
      print('[PASS API] Code: ${e.code}');
      print('[PASS API] Message: ${e.message}');
      rethrow;
    } catch (e) {
      print('[PASS API] Unexpected error: $e');
      throw ApiException(
        'Failed to pass session: $e',
        code: 'pass_session_error',
      );
    }
  }
}
