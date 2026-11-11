import 'dart:convert';

import 'package:hive/hive.dart';
import 'package:evalet/api/translations/language_api_service.dart';
import 'package:evalet/models/translations/language.dart';

class LanguageCache {
  static const String _languagesKey = 'cached_languages';
  static const String _lastFetchKey = 'languages_last_fetch';

  Future<List<Language>> getLanguages() async {
    final box = await Hive.openBox('languageBox');
    final now = DateTime.now();
    final lastFetch = box.get(_lastFetchKey);
    final cached = box.get(_languagesKey);

    if (lastFetch != null && cached != null) {
      final lastFetchDate = DateTime.parse(lastFetch);
      if (now.year == lastFetchDate.year &&
          now.month == lastFetchDate.month &&
          now.day == lastFetchDate.day) {
        final fromCache = Language.fromJsonList(cached);
        if (fromCache.isNotEmpty) return fromCache;
      }
    }

    try {
      final languages = await LanguageApiService.fetchLanguages();
      if (languages.isNotEmpty) {
        final jsonString =
            json.encode(languages.map((e) => e.toJson()).toList());
        await box.put(_languagesKey, jsonString);
        await box.put(_lastFetchKey, now.toIso8601String());
        return languages;
      }
    } catch (_) {
      // Fall through to use cached or default
    }

    // Fallback: use cached data even if stale
    if (cached != null && cached is String) {
      final fromCache = Language.fromJsonList(cached);
      if (fromCache.isNotEmpty) return fromCache;
    }

    return [];
  }
}
