import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/api/oauth/profile_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/oauth/client_summary.dart';
import 'package:niloufer_valet_mobile/models/oauth/login_result.dart';
import 'package:niloufer_valet_mobile/models/oauth/phone_password_login_request.dart';
import 'package:niloufer_valet_mobile/models/oauth/profile.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

class LoginApiService {
  LoginApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// POST /auth/login. A Client token finishes the login; a Platform token
  /// (0 or 2+ Clients, or a Platform Admin) returns the Clients to choose from.
  static Future<LoginResult> login(PhonePasswordLoginRequest request) async {
    final base = BaseDioService(_baseUrl, ApiConfig.defaultJsonHeaders);
    final response = await base.post(
      '/auth/login',
      data: request.toJson(),
      endSessionOn401: false,
    );
    final data = _asMap(response.data);

    if (data['scope'] == 'CLIENT') {
      return LoginResult.ready(await _completeClientLogin(data));
    }

    // Platform token: keep it only long enough to list and select a Client.
    await _saveToken(data);
    final clients = await fetchClients();
    return LoginResult.needsClient(clients);
  }

  /// GET /auth/clients (Platform or Client token).
  static Future<List<ClientSummary>> fetchClients() async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Access token not found. Please login again.',
          code: 'no_token');
    }
    final base = BaseDioService(_baseUrl, ApiConfig.authorizedHeaders(token));
    final response = await base.get('/auth/clients');
    final list = _asMap(response.data)['clients'] as List<dynamic>? ?? [];
    return list
        .map((e) => ClientSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// POST /auth/clients/:clientId/select. The previous token stops working.
  static Future<Profile> selectClient(String clientId) async {
    final token = await TokenStorage.getAccessToken();
    if (token == null || token.isEmpty) {
      throw ApiException('Access token not found. Please login again.',
          code: 'no_token');
    }
    final base = BaseDioService(_baseUrl, ApiConfig.authorizedHeaders(token));
    final response = await base.post('/auth/clients/$clientId/select');
    return _completeClientLogin(_asMap(response.data));
  }

  static Future<Profile> _completeClientLogin(Map<String, dynamic> data) async {
    await _saveToken(data);

    final me = await ProfileApiService.getProfile();
    final user = me.user;
    if (user.fullName.isNotEmpty) {
      await TokenStorage.saveUserName(
        firstName: user.firstName,
        lastName: user.lastName,
      );
    }
    if (user.id.isNotEmpty) {
      await TokenStorage.saveCachedAuthContext(
        normalizedRoles: me.normalizedRoles,
        userId: user.id,
      );
    }
    await SessionManager.markLoggedInForToday();

    return Profile(
      user: user,
      applicationId: me.applicationId,
      roles: me.roles,
    );
  }

  static Future<void> _saveToken(Map<String, dynamic> data) async {
    final accessToken = data['accessToken'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException('Invalid login response.', code: 'invalid_response');
    }
    await TokenStorage.saveAccessToken(accessToken);
    final expiresAt = DateTime.tryParse('${data['expiresAt']}')?.toLocal();
    await TokenStorage.saveAccessTokenExpiry(
      expiresAt ?? DateTime.now().add(const Duration(hours: 24)),
    );
  }

  static Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    throw ApiException('Invalid response from server.',
        code: 'invalid_response');
  }
}
