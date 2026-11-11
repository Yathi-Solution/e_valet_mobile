import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get valetBaseUrl => dotenv.env['API_BASE_URL'] ?? '';

  static String get websocketBaseUrl => dotenv.env['WEBSOCKET_BASE_URL'] ?? '';

  static String get outletId => (dotenv.env['OUTLET_ID'] ?? '').trim();

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
}
