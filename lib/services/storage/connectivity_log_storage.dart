import 'package:evalet/services/storage/auth_box.dart';

/// Driver connectivity logging: shift context, settings and queued events.
///
/// Stored in the shared [AuthBox].
class ConnectivityLogStorage {
  /// Driver POST /connectivity/log/batch context (cleared on logout).
  static const String _driverConnectivityShiftIdKey =
      'driver_connectivity_shift_id';
  static const String _driverConnectivityOutletIdKey =
      'driver_connectivity_outlet_id';
  static const String _connectivityPendingEventsJsonKey =
      'connectivity_pending_events_json';
  static const String _connectivityNextFlushDueUtcMillisKey =
      'connectivity_next_flush_due_utc_millis';

  /// Whether connectivity logging / features are enabled for this driver (from GET /connectivity/settings/me).
  static const String _driverConnectivityEnabledKey =
      'driver_connectivity_enabled_v1';

  /// OutletId returned by the latest /connectivity/settings/me call.
  static const String _driverConnectivitySettingsOutletIdKey =
      'driver_connectivity_settings_outlet_id_v1';

  static Future<void> clearDriverConnectivityLogData() async {
    try {
      await AuthBox.box.delete(_driverConnectivityShiftIdKey);
      await AuthBox.box.delete(_driverConnectivityOutletIdKey);
      await AuthBox.box.delete(_connectivityPendingEventsJsonKey);
      await AuthBox.box.delete(_connectivityNextFlushDueUtcMillisKey);
      await AuthBox.box.delete(_driverConnectivityEnabledKey);
      await AuthBox.box.delete(_driverConnectivitySettingsOutletIdKey);
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error clearing driver connectivity log: $e');
    }
  }

  static Future<void> saveDriverConnectivityShiftContext({
    required int shiftId,
    required int outletId,
  }) async {
    try {
      await AuthBox.box.put(_driverConnectivityShiftIdKey, shiftId);
      await AuthBox.box.put(_driverConnectivityOutletIdKey, outletId);
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error saving driver connectivity context: $e');
      rethrow;
    }
  }

  static Future<int?> getDriverConnectivityShiftId() async {
    try {
      final v = AuthBox.box.get(_driverConnectivityShiftIdKey);
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error reading driver connectivity shiftId: $e');
      return null;
    }
  }

  static Future<int?> getDriverConnectivityOutletId() async {
    try {
      final v = AuthBox.box.get(_driverConnectivityOutletIdKey);
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error reading driver connectivity outletId: $e');
      return null;
    }
  }

  /// Persists whether connectivity features are enabled for this driver (from the settings API).
  static Future<void> saveDriverConnectivityEnabled(bool isEnabled) async {
    try {
      await AuthBox.box.put(_driverConnectivityEnabledKey, isEnabled);
      print(
          '[ConnectivityLogStorage] Saved driverConnectivityEnabled = $isEnabled');
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error saving driver connectivity enabled flag: $e');
    }
  }

  /// Returns the last known value of driver connectivity enabled flag.
  /// Defaults to true if never fetched.
  static Future<bool> getDriverConnectivityEnabled() async {
    try {
      final v = AuthBox.box.get(_driverConnectivityEnabledKey);
      if (v is bool) return v;
      // Default to true if not present (fail open for logging)
      return true;
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error reading driver connectivity enabled flag: $e');
      return true;
    }
  }

  /// Saves the full response data from GET /connectivity/settings/me.
  /// This should be called after every successful driver login (after clearing previous data).
  static Future<void> saveDriverConnectivitySettings({
    required int outletId,
    required bool isEnabled,
  }) async {
    try {
      await AuthBox.box.put(_driverConnectivityEnabledKey, isEnabled);
      await AuthBox.box.put(_driverConnectivitySettingsOutletIdKey, outletId);
      // Silent on success — only errors are printed
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error saving driver connectivity settings: $e');
    }
  }

  /// Clears only the connectivity settings data fetched from /connectivity/settings/me.
  /// Called on every new driver login before storing fresh data.
  static Future<void> clearDriverConnectivitySettings() async {
    try {
      await AuthBox.box.delete(_driverConnectivityEnabledKey);
      await AuthBox.box.delete(_driverConnectivitySettingsOutletIdKey);
      // Silent clear on every login — only errors are printed
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error clearing driver connectivity settings: $e');
    }
  }

  /// Optional: get the outletId that was returned by the last /connectivity/settings/me call.
  static Future<int?> getDriverConnectivitySettingsOutletId() async {
    try {
      final v = AuthBox.box.get(_driverConnectivitySettingsOutletIdKey);
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error reading driver connectivity settings outletId: $e');
      return null;
    }
  }

  static Future<void> saveConnectivityNextFlushDue(DateTime utc) async {
    try {
      await AuthBox.box.put(
        _connectivityNextFlushDueUtcMillisKey,
        utc.millisecondsSinceEpoch,
      );
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error saving connectivity flush schedule: $e');
      rethrow;
    }
  }

  static Future<DateTime?> getConnectivityNextFlushDue() async {
    try {
      final v = AuthBox.box.get(_connectivityNextFlushDueUtcMillisKey);
      if (v is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error reading connectivity flush schedule: $e');
      return null;
    }
  }

  static Future<String?> getConnectivityPendingEventsJson() async {
    try {
      return AuthBox.box.get(_connectivityPendingEventsJsonKey) as String?;
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error reading connectivity pending events: $e');
      return null;
    }
  }

  static Future<void> saveConnectivityPendingEventsJson(String json) async {
    try {
      await AuthBox.box.put(_connectivityPendingEventsJsonKey, json);
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error saving connectivity pending events: $e');
      rethrow;
    }
  }

  static Future<void> clearConnectivityPendingEvents() async {
    try {
      await AuthBox.box.delete(_connectivityPendingEventsJsonKey);
    } catch (e) {
      print(
          '[ConnectivityLogStorage] Error clearing connectivity pending events: $e');
    }
  }
}
