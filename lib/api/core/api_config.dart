import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get authBaseUrl => dotenv.env['OAUTH_BASE_URL'] ?? '';

  static String get authApiKey =>
      (dotenv.env['OAUTH_BASE_API_KEY'] ?? '').trim();

  static String get valetBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get websocketBaseUrl => dotenv.env['WEBSOCKET_BASE_URL'] ?? '';

  static String get outletId => (dotenv.env['OUTLET_ID'] ?? '').trim();

  /// Application ID for valet logout API. Reads EVALET_APPLICATION_BASE_URL (e.g. EVALET_APPLICATION_DEV_ID or EVALET_APPLICATION_PROD_ID)
  /// and uses that as the key to get the actual ID value from .env.
  static String get evaletApplicationId {
    final key = (dotenv.env['EVALET_APPLICATION_BASE_URL'] ?? '').trim();
    return key.isEmpty ? '' : (dotenv.env[key] ?? '').trim();
  }

  static Map<String, String> get defaultJsonHeaders => const {
        'Accept': 'application/json, text/plain, */*',
        'Content-Type': 'application/json',
        'Connection': 'keep-alive',
      };

  static Map<String, String> authorizedHeaders(String accessToken) {
    final headers = <String, String>{


      
      ...defaultJsonHeaders,
      'Authorization': 'Bearer $accessToken',
    };
    if (outletId.isNotEmpty) {
      // Some backend routes require outlet id in headers.
      headers['outletId'] = outletId;
      headers['X-Outlet-Id'] = outletId;
    }
    return headers;
  }

  static Map<String, String> apiKeyHeaders(String apiKey) {
    return {
      ...defaultJsonHeaders,
      'X-API-Key': apiKey,
    };
  }
}
