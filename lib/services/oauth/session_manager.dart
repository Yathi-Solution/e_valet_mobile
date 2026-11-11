import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class SessionManager {
  SessionManager._();

  static const String _loginDateKey = 'session_login_date_v1';
  static const String _isLoggedInKey = 'session_is_logged_in_v1';
  static const String _hasShownScannerIntroKey =
      'session_has_shown_scanner_intro_v1';
  static const String _hasShownCarPhotoIntroKey =
      'session_has_shown_car_photo_intro_v1';
  static const int _dailyResetHour = 3; // 3:00 AM local time

  static Box get _box {
    if (!Hive.isBoxOpen(TokenStorage.boxName)) {
      throw StateError(
        'TokenStorage box not opened. Call TokenStorage.init() first.',
      );
    }
    return Hive.box(TokenStorage.boxName);
  }

  /// Marks the current session as active for the current business day.
  /// Business day rolls over at 3:00 AM local time.
  static Future<void> markLoggedInForToday() async {
    await _box.put(_isLoggedInKey, true);
    await _box.put(_loginDateKey, _businessDayKey());
  }

  /// Clears any persisted session metadata (including intro animation flags).
  /// Called on logout so that after the next login, the Camera and Scanner
  /// intro animations (Lottie) are shown once again.
  static Future<void> clearSessionFlags() async {
    await _box.delete(_isLoggedInKey);
    await _box.delete(_loginDateKey);
    await _box.delete(_hasShownScannerIntroKey);
    await _box.delete(_hasShownCarPhotoIntroKey);
  }

  /// True if the QR/scanner intro animation has been shown this login session.
  static Future<bool> hasShownScannerIntroThisSession() async {
    return (_box.get(_hasShownScannerIntroKey) as bool?) ?? false;
  }

  /// Mark that the scanner intro has been shown (so we skip it on retake/return).
  static Future<void> markScannerIntroShown() async {
    await _box.put(_hasShownScannerIntroKey, true);
  }

  /// True if the car photo intro animation has been shown this login session.
  static Future<bool> hasShownCarPhotoIntroThisSession() async {
    return (_box.get(_hasShownCarPhotoIntroKey) as bool?) ?? false;
  }

  /// Mark that the car photo intro has been shown (so we skip it on retake).
  static Future<void> markCarPhotoIntroShown() async {
    await _box.put(_hasShownCarPhotoIntroKey, true);
  }

  /// Returns true when stored login markers are valid for the current
  /// business day (which changes at 3:00 AM local time).
  static Future<bool> hasValidSessionForToday() async {
    final isLoggedIn = (_box.get(_isLoggedInKey) as bool?) ?? false;
    if (!isLoggedIn) return false;

    final storedDate = _box.get(_loginDateKey) as String?;
    if (storedDate == null || storedDate.isEmpty) return false;
    if (storedDate != _businessDayKey()) return false;

    final token = await TokenStorage.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Returns true if user session is valid for the current business day.
  static Future<bool> isUserLoggedIn() async {
    return await hasValidSessionForToday();
  }

  /// Clears local auth/session data if we crossed the daily 3:00 AM cutoff.
  /// Returns true when a forced reset happened.
  static Future<bool> enforceDailyResetIfNeeded() async {
    final hasTokens = await TokenStorage.hasValidTokens();
    if (!hasTokens) return false;

    final validForCurrentBusinessDay = await hasValidSessionForToday();
    if (validForCurrentBusinessDay) return false;

    await TokenStorage.clearAll();
    await clearSessionFlags();
    return true;
  }

  /// Current business-day key based on a 3:00 AM cutoff.
  static String _businessDayKey([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final businessNow = now.hour < _dailyResetHour
        ? now.subtract(const Duration(days: 1))
        : now;
    final month = businessNow.month.toString().padLeft(2, '0');
    final day = businessNow.day.toString().padLeft(2, '0');
    return '${businessNow.year}-$month-$day';
  }

  /// Timestamp for next forced daily reset (next 3:00 AM local time).
  static DateTime nextDailyResetAt([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    var next = DateTime(now.year, now.month, now.day, _dailyResetHour);
    if (!now.isBefore(next)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }
}
