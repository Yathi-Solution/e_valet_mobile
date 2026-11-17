import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/api/core/app_version_api_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';

/// Service for mandatory app version check.
/// - Calls API at most once per day (first app open of the day) via [AppVersionApiService].
/// - Stores lastCheckedDate (yyyy-MM-dd) and remoteBuildNumber in Hive.
/// - Offline/errors: returns null so app can skip check gracefully.
class VersionService {
  VersionService._();

  static const String _boxName = 'version_prefs';
  static const String _lastCheckedDateKey = 'lastCheckedDate';
  static const String _remoteBuildNumberKey = 'remoteBuildNumber';

  static late Box _box;

  /// Call once at app start (after Hive.initFlutter()).
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    _box = Hive.box(_boxName);
  }

  static String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// Returns remote build number from API (calling at most once per day).
  /// Returns null if offline or on error (caller should skip mandatory check).
  static Future<String?> getRemoteBuildNumber() async {
    try {
      final today = _todayString();
      final lastChecked = _box.get(_lastCheckedDateKey) as String?;

      if (lastChecked == today) {
        return _box.get(_remoteBuildNumberKey) as String?;
      }

      final response = await AppVersionApiService.getBuildNumber();
      final buildNumber = response.buildNumber;

      if (buildNumber.isNotEmpty) {
        await _box.put(_lastCheckedDateKey, today);
        await _box.put(_remoteBuildNumberKey, buildNumber);
        return buildNumber;
      }
      return _box.get(_remoteBuildNumberKey) as String?;
    } on ApiException {
      return _box.get(_remoteBuildNumberKey) as String?;
    } catch (_) {
      return _box.get(_remoteBuildNumberKey) as String?;
    }
  }

  /// Compare semantic versions (e.g. "0.5.0" vs "0.6.0").
  /// Returns true if [local] is strictly lower than [remote].
  static bool isLocalVersionLowerThan(String local, String remote) {
    final localParts = _parseVersion(local);
    final remoteParts = _parseVersion(remote);
    for (var i = 0; i < 3; i++) {
      final l = i < localParts.length ? localParts[i] : 0;
      final r = i < remoteParts.length ? remoteParts[i] : 0;
      if (l < r) return true;
      if (l > r) return false;
    }
    return false;
  }

  static List<int> _parseVersion(String v) {
    return v.split('.').map((e) => int.tryParse(e.trim()) ?? 0).toList();
  }
}
