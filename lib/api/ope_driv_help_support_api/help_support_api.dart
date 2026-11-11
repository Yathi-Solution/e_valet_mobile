import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/help_support/support_member.dart';

class HelpSupportApi {
  HelpSupportApi._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static Future<List<SupportMember>> fetchSupportMembers() async {
    final base = BaseDioService(
      _baseUrl,
      ApiConfig.defaultJsonHeaders,
    );

    try {
      final response = await base.get('/miscellaneous/support-members');

      final data = response.data;
      if (data is! List) {
        throw ApiException(
          'Invalid response format for support members.',
          code: 'invalid_response',
        );
      }

      return data
          .map((e) => SupportMember.fromJson(e as Map<String, dynamic>))
          .toList();
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Failed to fetch support members. Please try again.',
        code: 'unknown_error',
      );
    }
  }
}
