import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/translations/language.dart';

/// Fetches available languages from GET /api/languages.
/// API returns: id, code, name, nativeName, isActive, isDefault, createdAt, updatedAt
class LanguageApiService {
  LanguageApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  /// GET .../api/v1/i18n/languages (path matches translations: /i18n/languages)
  /// Response: JSON array of { id, code, name, nativeName, isActive, isDefault, ... }
  static const String _path = '/i18n/languages';

  static Future<List<Language>> fetchLanguages() async {
    if (_baseUrl.isEmpty) {
      throw ApiException(
        'API base URL is not configured.',
        code: 'config_error',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.defaultJsonHeaders,
    );

    try {
      final response = await base.get(
        _path,
        endSessionOn401: false,
      );

      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Invalid response format for languages.',
          code: 'invalid_response',
        );
      }

      final languages = <Language>[];
      for (final item in data) {
        if (item is Map<String, dynamic>) {
          final lang = Language.fromJson(item);
          if (lang.code.isNotEmpty && lang.name.isNotEmpty) {
            languages.add(lang);
          }
        }
      }
      return languages;
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Failed to fetch languages. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
