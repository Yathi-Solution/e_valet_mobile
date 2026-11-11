import 'dart:convert';
import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_http_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';

class OtpApiService {
  OtpApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static final _http = BaseHttpService(
    baseUrl: _baseUrl,
    defaultHeaders: ApiConfig.defaultJsonHeaders,
  );

  static Future<String> requestPasswordResetOtp(String identifier) async {
    // POST /auth/forgot-password always answers 202; the user gets a reset link.
    final body = {'identifier': identifier};

    try {
      final response = await _http.postJson(
        '/auth/forgot-password',
        body: body,
      );

      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic> &&
          decoded['message'] is String &&
          (decoded['message'] as String).isNotEmpty) {
        return decoded['message'] as String;
      }

      return 'If the account exists, a reset link has been sent.';
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Something went wrong. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
