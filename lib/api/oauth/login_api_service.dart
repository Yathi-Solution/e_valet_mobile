import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/api/oauth/profile_api_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/oauth/client_summary.dart';
import 'package:evalet/models/oauth/login_result.dart';
import 'package:evalet/models/oauth/phone_password_login_request.dart';
import 'package:evalet/models/oauth/profile.dart';
import 'package:evalet/services/oauth/session_manager.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class LoginApiService {
  LoginApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// POST /auth/login-codes. Always 202, whether or not the number can sign in.
  /// [channel] is omitted for WhatsApp (SMS fallback on the server). Send
  /// `SMS` only for "Send by SMS".
  static Future<void> requestLoginCode(
    String phone, {
    String? channel,
  }) async {
    final base = BaseDioService(_baseUrl, ApiConfig.defaultJsonHeaders);
    final body = <String, dynamic>{'phone': phone};
    if (channel != null) body['channel'] = channel;
    await base.post(
      '/auth/login-codes',
      data: body,
      endSessionOn401: false,
    );
  }

  /// POST /auth/login-codes/verify. CLIENT scope finishes sign-in; PLATFORM
  /// scope must pick a Client before the app can be used.
  static Future<LoginResult> verifyLoginCode({
    required String phone,
    required String code,
  }) async {
    final base = BaseDioService(_baseUrl, ApiConfig.defaultJsonHeaders);
    final response = await base.post(
      '/auth/login-codes/verify',
      data: {'phone': phone, 'code': code},
      endSessionOn401: false,
    );
    return _resultFromToken(_asMap(response.data));
  }

  /// POST /auth/login. Kept for accounts that still have a password. The app
  /// UI does not call this.
  static Future<LoginResult> login(PhonePasswordLoginRequest request) async {
    final base = BaseDioService(_baseUrl, ApiConfig.defaultJsonHeaders);
    final response = await base.post(
      '/auth/login',
      data: request.toJson(),
      endSessionOn401: false,
    );
    return _resultFromToken(_asMap(response.data));
  }

  static Future<LoginResult> _resultFromToken(Map<String, dynamic> data) async {
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
