import 'package:flutter/foundation.dart';
import 'package:evalet/services/translations/translations_cache.dart';

/// Holds the current translation map in memory so the UI can read translated
/// strings synchronously. Call [load] on app start and after the user changes
/// language so the app rebuilds with new translations.
///
/// Translations come from the backend API only (GET /i18n/translations?language=xx).
/// Use [getByKey] for keys that match the backend API exactly (e.g. 'takingBreak').
/// Use [get] for display strings that convert to camelCase (e.g. "Parked Car" -> "parkedCar").
class AppTranslationsNotifier extends ChangeNotifier {
  Map<String, String>? _translations;
  String? _currentLanguageCode;

  /// Current language code from the last API response (e.g. 'te', 'hi').
  String? get currentLanguageCode => _currentLanguageCode;

  /// Converts a display string (e.g. "Parked Car", "Dashboard") to the API key
  /// format (e.g. "parkedCar", "dashboard") so we can look up in the API response.
  static String _displayStringToApiKey(String value) {
    final parts = value.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return value.toLowerCase();
    final first = parts.first.toLowerCase();
    if (parts.length == 1) return first;
    final rest = parts
        .skip(1)
        .map((p) =>
            p.isEmpty ? p : p[0].toUpperCase() + p.substring(1).toLowerCase())
        .join();
    return first + rest;
  }

  /// Returns the translated string for [textConstant] (e.g. [TextConstants.logout]).
  /// Looks up using derived camelCase key from display string; returns from API or [textConstant].
  String get(String textConstant) {
    final value = _translations?[_displayStringToApiKey(textConstant)];
    return value ?? textConstant;
  }

  /// Returns the translated string for [apiKey] from the backend API.
  /// Use when the backend key differs from the display-string-to-camelCase conversion.
  /// [fallback] is used when the API has no translation for this key.
  String getByKey(String apiKey, [String? fallback]) {
    final value = _translations?[apiKey];
    return value ?? fallback ?? apiKey;
  }

  /// First non-empty translation among [apiKeys], else [fallback].
  /// Use when the backend may store the same string under more than one key
  /// (e.g. legacy `groupingDescription` vs `driversGroupSubtitle`).
  String getFirstTranslation(List<String> apiKeys, String fallback) {
    for (final k in apiKeys) {
      final v = _translations?[k];
      if (v != null && v.isNotEmpty) return v;
    }
    return fallback;
  }

  /// Loads translations from [TranslationsCache] and notifies listeners so the
  /// app rebuilds. Call after app start (e.g. in provider create) and after
  /// the user selects a new language in the language dropdown.
  Future<void> load() async {
    try {
      final response = await TranslationsCache().getTranslations();
      _translations = response?.translations;
      _currentLanguageCode = response?.language;
      notifyListeners();
    } catch (_) {
      // Keep previous translations on error
    }
  }
}
