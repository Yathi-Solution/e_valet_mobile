import 'package:hive_flutter/hive_flutter.dart';

class TokenStorage {
  static const String _parkingLocationKey = 'parking_location';

  // Parking Location management
  static Future<void> saveParkingLocation(String location) async {
    try {
      await _box.put(_parkingLocationKey, location);
    } catch (e) {
      print('[TokenStorage] ❌ Error saving parking location: $e');
      rethrow;
    }
  }

  static Future<String?> getParkingLocation() async {
    try {
      return _box.get(_parkingLocationKey) as String?;
    } catch (e) {
      print('[TokenStorage] ❌ Error retrieving parking location: $e');
      return null;
    }
  }

  static Future<void> clearParkingLocation() async {
    try {
      await _box.delete(_parkingLocationKey);
    } catch (e) {
      print('[TokenStorage] ❌ Error clearing parking location: $e');
    }
  }

  static const String _cachedParkedSessionsJsonKey = 'cached_parked_sessions_json';

  static Future<void> saveCachedParkedSessionsJson(String json) async {
    try {
      await _box.put(_cachedParkedSessionsJsonKey, json);
    } catch (e) {
      print('[TokenStorage] Error saving cached parked sessions: $e');
    }
  }

  static Future<String?> getCachedParkedSessionsJson() async {
    try {
      return _box.get(_cachedParkedSessionsJsonKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error reading cached parked sessions: $e');
      return null;
    }
  }

  static Future<void> clearCachedParkedSessions() async {
    try {
      await _box.delete(_cachedParkedSessionsJsonKey);
    } catch (e) {
      print('[TokenStorage] Error clearing cached parked sessions: $e');
    }
  }

  static const String _boxName = 'authBox';

  // Public getter so other classes can reuse the same box name
  static String get boxName => _boxName;

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _firstNameKey = 'user_first_name';
  static const String _lastNameKey = 'user_last_name';
  static const String _phoneNumberKey = 'user_phone_number';
  static const String _resetTokenKey = 'reset_token';
  static const String _sessionIdKey = 'session_id';
  static const String _pendingPhotoKey = 'pending_photo_path';
  static const String _sessionIdFromGetApiKey = 'session_id_from_get_api';
  static const String _assignedSessionDataKey = 'assigned_session_data';
  static const String _arrivalLocationKey = 'arrival_location';
  static const String _arrivalLatitudeKey = 'arrival_latitude';
  static const String _arrivalLongitudeKey = 'arrival_longitude';
  static const String _currentLocationKey = 'current_location';
  static const String _currentLatitudeKey = 'current_latitude';
  static const String _currentLongitudeKey = 'current_longitude';
  static const String _selectedOutletIdKey = 'selected_outlet_id';
  static const String _selectedOutletNameKey = 'selected_outlet_name';
  static const String _confirmArrivalDisableSecondsKey =
      'confirm_arrival_disable_seconds';
  static const String _confirmArrivalDisabledUntilBySessionKey =
      'confirm_arrival_disabled_until_by_session';
  static const String _confirmArrivalTimerStartedBySessionKey =
      'confirm_arrival_timer_started_by_session';
  static const String _customerMissingDisableSecondsKey =
      'customer_missing_disable_seconds';
  static const String _confirmHandoverDisableSecondsKey =
      'confirm_handover_disable_seconds';
  static const String _customerMissingDisabledUntilBySessionKey =
      'customer_missing_disabled_until_by_session';
  static const String _confirmHandoverDisabledUntilBySessionKey =
      'confirm_handover_disabled_until_by_session';
  static const String _confirmHandoverTimerStartedBySessionKey =
      'confirm_handover_timer_started_by_session';
  static const String _scannerButtonStatusKey = 'scanner_button_status';
  static const String _imageCompressionQualityKey = 'image_compression_quality';
  static const String _imageCompressionMaxSizeKbKey =
      'image_compression_max_size_kb';

  /// Last known roles and user id when `/auth/profile` succeeds (splash offline fallback).
  static const String _cachedNormalizedRolesKey =
      'cached_normalized_roles_v1';
  static const String _cachedUserIdKey = 'cached_user_id_v1';

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

  /// Legacy single id (migrated into [_collectKeysInTransitSessionIdsKey]).
  static const String _collectKeysInTransitSessionIdKey =
      'collect_keys_in_transit_session_id';

  /// Session ids for which user tapped Collect Keys in-transit (skip Confirm Arrival).
  static const String _collectKeysInTransitSessionIdsKey =
      'collect_keys_in_transit_session_ids';

  /// Session id → expiry millis; blocks auto [ConfirmArrivalScreen] open while
  /// GET /sessions/pending still shows ARRIVED/ACCEPTED briefly after handover
  /// (collect-keys ack was removed, so [collectKeysInTransitAckContainsSync] is false).
  static const String _retrievalConfirmFlowCooldownUntilKey =
      'retrieval_confirm_flow_cooldown_until';

  static const Duration _retrievalConfirmFlowCooldown = Duration(seconds: 45);

  /// Card numbers allocated to this driver (from GET /drivers/my-cards).
  /// Used to restrict tag/QR entry at park time to only the driver's own cards.
  static const String _driverAssignedCardNumbersKey =
      'driver_assigned_card_numbers_v1';
  static const String _driverAssignedCardsLoadedKey =
      'driver_assigned_cards_loaded_v1';

  /// Must be called once at app start (after Hive.initFlutter()).
  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
  }

  static Box get _box {
    if (!Hive.isBoxOpen(_boxName)) {
      throw StateError(
        'TokenStorage box not opened. Call TokenStorage.init() first.',
      );
    }
    return Hive.box(_boxName);
  }

  // Access token
  static Future<void> saveAccessToken(String token) async {
    try {
      await _box.put(_accessTokenKey, token);
    } catch (e) {
      print('[TokenStorage] Error saving access token: $e');
      rethrow;
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      return _box.get(_accessTokenKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error retrieving access token: $e');
      return null;
    }
  }

  static Future<void> saveAccessTokenExpiry(DateTime expiry) async {
    try {
      await _box.put(_accessTokenExpiryKey, expiry.toIso8601String());
    } catch (e) {
      print('[TokenStorage] Error saving access token expiry: $e');
      rethrow;
    }
  }

  static Future<DateTime?> getAccessTokenExpiry() async {
    try {
      final expiryStr = _box.get(_accessTokenExpiryKey) as String?;
      if (expiryStr == null) return null;
      return DateTime.parse(expiryStr);
    } catch (e) {
      print('[TokenStorage] Error retrieving access token expiry: $e');
      return null;
    }
  }

  static Future<void> clearAccessToken() async {
    try {
      await _box.delete(_accessTokenKey);
      await _box.delete(_accessTokenExpiryKey);
    } catch (e) {
      print('[TokenStorage] Error clearing access token: $e');
    }
  }

  static Future<bool> isAccessTokenExpiredOrExpiringSoon() async {
    try {
      final expiry = await getAccessTokenExpiry();
      if (expiry == null) return true; // If no expiry, consider expired
      final now = DateTime.now();
      // Consider expired if less than 2 minutes left
      return now.isAfter(expiry.subtract(const Duration(minutes: 2)));
    } catch (e) {
      print('[TokenStorage] Error checking token expiry: $e');
      return true; // On error, assume expired
    }
  }

  // Refresh token
  static Future<void> saveRefreshToken(String token) async {
    try {
      await _box.put(_refreshTokenKey, token);
    } catch (e) {
      print('[TokenStorage] Error saving refresh token: $e');
      rethrow;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return _box.get(_refreshTokenKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error retrieving refresh token: $e');
      return null;
    }
  }

  static Future<void> clearRefreshToken() async {
    try {
      await _box.delete(_refreshTokenKey);
    } catch (e) {
      print('[TokenStorage] Error clearing refresh token: $e');
    }
  }

  // User name
  static Future<void> saveUserName({
    required String firstName,
    required String lastName,
  }) async {
    try {
      await _box.put(_firstNameKey, firstName);
      await _box.put(_lastNameKey, lastName);
    } catch (e) {
      print('[TokenStorage] Error saving user name: $e');
      rethrow;
    }
  }

  static Future<String?> getFirstName() async {
    try {
      return _box.get(_firstNameKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error retrieving first name: $e');
      return null;
    }
  }

  static Future<String?> getLastName() async {
    try {
      return _box.get(_lastNameKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error retrieving last name: $e');
      return null;
    }
  }

  static Future<void> clearUserName() async {
    try {
      await _box.delete(_firstNameKey);
      await _box.delete(_lastNameKey);
    } catch (e) {
      print('[TokenStorage] Error clearing user name: $e');
    }
  }

  // Phone number (identifier)
  static Future<void> savePhoneNumber(String phoneNumber) async {
    try {
      await _box.put(_phoneNumberKey, phoneNumber);
    } catch (e) {
      print('[TokenStorage] Error saving phone number: $e');
      rethrow;
    }
  }

  static Future<String?> getPhoneNumber() async {
    try {
      return _box.get(_phoneNumberKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error retrieving phone number: $e');
      return null;
    }
  }

  static Future<void> clearPhoneNumber() async {
    try {
      await _box.delete(_phoneNumberKey);
    } catch (e) {
      print('[TokenStorage] Error clearing phone number: $e');
    }
  }

  // Reset token (password reset flow)
  static Future<void> saveResetToken(String token) async {
    try {
      await _box.put(_resetTokenKey, token);
    } catch (e) {
      print('[TokenStorage] Error saving reset token: $e');
      rethrow;
    }
  }

  static Future<String?> getResetToken() async {
    try {
      return _box.get(_resetTokenKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error retrieving reset token: $e');
      return null;
    }
  }

  static Future<void> clearResetToken() async {
    try {
      await _box.delete(_resetTokenKey);
    } catch (e) {
      print('[TokenStorage] Error clearing reset token: $e');
    }
  }

  // Session ID (for parking session)
  static Future<void> saveSessionId(String sessionId) async {
    try {
      await _box.put(_sessionIdKey, sessionId);
    } catch (e) {
      print('[TokenStorage] Error saving session ID: $e');
      rethrow;
    }
  }

  static Future<String?> getSessionId() async {
    try {
      final sessionId = _box.get(_sessionIdKey) as String?;
      return sessionId;
    } catch (e) {
      print('[TokenStorage] Error retrieving session ID: $e');
      return null;
    }
  }

  /// Sync read for park-flow checks (e.g. camera vs retrieval session match).
  static String? getSessionIdSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      return Hive.box(_boxName).get(_sessionIdKey) as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSessionId() async {
    try {
      await _box.delete(_sessionIdKey);
    } catch (e) {
      print('[TokenStorage] Error clearing session ID: $e');
    }
  }

  static Future<bool> hasSessionId() async {
    final sessionId = await getSessionId();
    return sessionId != null && sessionId.isNotEmpty;
  }

  // Pending photo management
  static Future<void> savePendingPhotoPath(String photoPath) async {
    try {
      await _box.put(_pendingPhotoKey, photoPath);
    } catch (e) {
      print('[TokenStorage] Error saving pending photo path: $e');
      rethrow;
    }
  }

  static Future<String?> getPendingPhotoPath() async {
    try {
      return _box.get(_pendingPhotoKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error retrieving pending photo path: $e');
      return null;
    }
  }

  static Future<void> clearPendingPhotoPath() async {
    try {
      await _box.delete(_pendingPhotoKey);
    } catch (e) {
      print('[TokenStorage] Error clearing pending photo path: $e');
    }
  }

  // Session ID from GET API management
  static Future<void> saveSessionIdFromGetApi(String sessionId) async {
    try {
      await _box.put(_sessionIdFromGetApiKey, sessionId);
    } catch (e) {
      print('[TokenStorage] ❌ Error saving sessionId from GET API: $e');
      rethrow;
    }
  }

  static Future<String?> getSessionIdFromGetApi() async {
    try {
      final sessionId = _box.get(_sessionIdFromGetApiKey) as String?;
      return sessionId;
    } catch (e) {
      print('[TokenStorage] ❌ Error retrieving sessionId from GET API: $e');
      return null;
    }
  }

  static Future<void> clearSessionIdFromGetApi() async {
    try {
      await _box.delete(_sessionIdFromGetApiKey);
    } catch (e) {
      print('[TokenStorage] ❌ Error clearing sessionId from GET API: $e');
    }
  }

  // Assigned Session Data management
  static Future<void> saveAssignedSessionData(
      Map<String, dynamic> sessionData) async {
    try {
      await _box.put(_assignedSessionDataKey, sessionData);
    } catch (e) {
      print('[TokenStorage] ❌ Error saving assigned session data: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getAssignedSessionData() async {
    try {
      final data = _box.get(_assignedSessionDataKey) as Map<String, dynamic>?;
      return data;
    } catch (e) {
      print('[TokenStorage] ❌ Error retrieving assigned session data: $e');
      return null;
    }
  }

  static Future<void> clearAssignedSessionData() async {
    try {
      await _box.delete(_assignedSessionDataKey);
    } catch (e) {
      print('[TokenStorage] ❌ Error clearing assigned session data: $e');
    }
  }

  // Arrival Location management
  static Future<void> saveArrivalLocation({
    required double latitude,
    required double longitude,
    required String location,
  }) async {
    try {
      await _box.put(_arrivalLatitudeKey, latitude);
      await _box.put(_arrivalLongitudeKey, longitude);
      await _box.put(_arrivalLocationKey, location);
    } catch (e) {
      print('[TokenStorage] ❌ Error saving arrival location: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getArrivalLocation() async {
    try {
      final latitude = _box.get(_arrivalLatitudeKey) as double?;
      final longitude = _box.get(_arrivalLongitudeKey) as double?;
      final location = _box.get(_arrivalLocationKey) as String?;

      if (latitude != null && longitude != null && location != null) {
        return {
          'latitude': latitude,
          'longitude': longitude,
          'location': location,
        };
      }
      return null;
    } catch (e) {
      print('[TokenStorage] ❌ Error retrieving arrival location: $e');
      return null;
    }
  }

  static Future<void> clearArrivalLocation() async {
    try {
      await _box.delete(_arrivalLatitudeKey);
      await _box.delete(_arrivalLongitudeKey);
      await _box.delete(_arrivalLocationKey);
    } catch (e) {
      print('[TokenStorage] ❌ Error clearing arrival location: $e');
    }
  }

  // Current Location management (used for accept, arrived, handover APIs)
  static Future<void> saveCurrentLocation({
    required double latitude,
    required double longitude,
    required String location,
  }) async {
    try {
      await _box.put(_currentLatitudeKey, latitude);
      await _box.put(_currentLongitudeKey, longitude);
      await _box.put(_currentLocationKey, location);
    } catch (e) {
      print('[TokenStorage] ❌ Error saving current location: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final latitude = _box.get(_currentLatitudeKey) as double?;
      final longitude = _box.get(_currentLongitudeKey) as double?;
      final location = _box.get(_currentLocationKey) as String?;

      if (latitude != null && longitude != null && location != null) {
        return {
          'latitude': latitude,
          'longitude': longitude,
          'location': location,
        };
      }
      return null;
    } catch (e) {
      print('[TokenStorage] ❌ Error retrieving current location: $e');
      return null;
    }
  }

  static Future<void> clearCurrentLocation() async {
    try {
      await _box.delete(_currentLatitudeKey);
      await _box.delete(_currentLongitudeKey);
      await _box.delete(_currentLocationKey);
    } catch (e) {
      print('[TokenStorage] ❌ Error clearing current location: $e');
    }
  }

  // Selected Outlet management
  static Future<void> saveSelectedOutlet({
    required int outletId,
    required String outletName,
  }) async {
    try {
      await _box.put(_selectedOutletIdKey, outletId);
      await _box.put(_selectedOutletNameKey, outletName);
    } catch (e) {
      print('[TokenStorage] ❌ Error saving selected outlet: $e');
      rethrow;
    }
  }

  static Future<int?> getSelectedOutletId() async {
    try {
      return _box.get(_selectedOutletIdKey) as int?;
    } catch (e) {
      print('[TokenStorage] ❌ Error retrieving selected outlet id: $e');
      return null;
    }
  }

  static int? getSelectedOutletIdSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      return Hive.box(_boxName).get(_selectedOutletIdKey) as int?;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getSelectedOutletName() async {
    try {
      return _box.get(_selectedOutletNameKey) as String?;
    } catch (e) {
      print('[TokenStorage] ❌ Error retrieving selected outlet name: $e');
      return null;
    }
  }

  static Future<void> clearSelectedOutlet() async {
    try {
      await _box.delete(_selectedOutletIdKey);
      await _box.delete(_selectedOutletNameKey);
    } catch (e) {
      print('[TokenStorage] ❌ Error clearing selected outlet: $e');
    }
  }

  // Button config management
  static Future<void> saveButtonConfig({
    required int confirmArrivalDisableSeconds,
    required int customerMissingDisableSeconds,
    required int confirmHandoverDisableSeconds,
    required bool scannerButtonStatus,
    required int imageCompressionQuality,
    required int imageCompressionMaxSizeKB,
  }) async {
    try {
      await _box.put(
          _confirmArrivalDisableSecondsKey, confirmArrivalDisableSeconds);
      await _box.put(
          _customerMissingDisableSecondsKey, customerMissingDisableSeconds);
      await _box.put(
          _confirmHandoverDisableSecondsKey, confirmHandoverDisableSeconds);
      await _box.put(_scannerButtonStatusKey, scannerButtonStatus);
      await _box.put(_imageCompressionQualityKey, imageCompressionQuality);
      await _box.put(_imageCompressionMaxSizeKbKey, imageCompressionMaxSizeKB);
    } catch (e) {
      print('[TokenStorage] ❌ Error saving button config: $e');
      rethrow;
    }
  }

  static Future<int?> getConfirmArrivalDisableSeconds() async {
    try {
      final value = _box.get(_confirmArrivalDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print('[TokenStorage] ❌ Error reading confirm arrival config: $e');
      return null;
    }
  }

  static int? getConfirmArrivalDisableSecondsSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      final value = Hive.box(_boxName).get(_confirmArrivalDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getCustomerMissingDisableSeconds() async {
    try {
      final value = _box.get(_customerMissingDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print('[TokenStorage] ❌ Error reading customer missing config: $e');
      return null;
    }
  }

  static int? getCustomerMissingDisableSecondsSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      final value = Hive.box(_boxName).get(_customerMissingDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getConfirmHandoverDisableSeconds() async {
    try {
      final value = _box.get(_confirmHandoverDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print('[TokenStorage] ❌ Error reading confirm handover config: $e');
      return null;
    }
  }

  static int? getConfirmHandoverDisableSecondsSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      final value = Hive.box(_boxName).get(_confirmHandoverDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static List<String> _cooldownKeysForSession({
    required String sessionId,
    int? cardNumber,
  }) {
    final keys = <String>[];
    final sid = sessionId.trim();
    if (sid.isNotEmpty) keys.add(sid);
    if (cardNumber != null && cardNumber > 0) {
      keys.add('card:$cardNumber');
    }
    return keys;
  }

  static DateTime? _getDisabledUntilForKeysSync({
    required String mapKey,
    required List<String> candidateKeys,
  }) {
    if (candidateKeys.isEmpty) return null;
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      final box = Hive.box(_boxName);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final raw = box.get(mapKey);
      if (raw is! Map) return null;

      final cleaned = <String, int>{};
      for (final entry in raw.entries) {
        final k = entry.key?.toString().trim() ?? '';
        if (k.isEmpty) continue;
        final v = entry.value;
        final untilMs = v is int ? v : int.tryParse(v.toString()) ?? 0;
        if (untilMs > nowMs) {
          cleaned[k] = untilMs;
        }
      }
      if (cleaned.length != raw.length) {
        box.put(mapKey, cleaned);
      }

      for (final key in candidateKeys) {
        final until = cleaned[key];
        if (until != null) {
          return DateTime.fromMillisecondsSinceEpoch(until);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static void _saveDisabledUntilForKeysSync({
    required String mapKey,
    required List<String> targetKeys,
    required DateTime until,
  }) {
    if (targetKeys.isEmpty) return;
    try {
      if (!Hive.isBoxOpen(_boxName)) return;
      final box = Hive.box(_boxName);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final untilMs = until.millisecondsSinceEpoch;
      final raw = box.get(mapKey);
      final map = <String, int>{};
      if (raw is Map) {
        for (final entry in raw.entries) {
          final k = entry.key?.toString().trim() ?? '';
          if (k.isEmpty) continue;
          final v = entry.value;
          final exp = v is int ? v : int.tryParse(v.toString()) ?? 0;
          if (exp > nowMs) {
            map[k] = exp;
          }
        }
      }
      for (final key in targetKeys) {
        if (untilMs > nowMs) {
          map[key] = untilMs;
        } else {
          map.remove(key);
        }
      }
      box.put(mapKey, map);
    } catch (_) {}
  }

  static DateTime? getCustomerMissingDisabledUntilForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) {
    return _getDisabledUntilForKeysSync(
      mapKey: _customerMissingDisabledUntilBySessionKey,
      candidateKeys: _cooldownKeysForSession(
        sessionId: sessionId,
        cardNumber: cardNumber,
      ),
    );
  }

  static bool hasConfirmArrivalTimerStartedForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) {
    final keys = _cooldownKeysForSession(
      sessionId: sessionId,
      cardNumber: cardNumber,
    );
    if (keys.isEmpty) return false;
    try {
      if (!Hive.isBoxOpen(_boxName)) return false;
      final box = Hive.box(_boxName);
      final raw = box.get(_confirmArrivalTimerStartedBySessionKey);
      if (raw is! Map) return false;
      final map = <String, bool>{};
      var found = false;
      for (final entry in raw.entries) {
        final k = entry.key?.toString().trim() ?? '';
        if (k.isEmpty) continue;
        final v = entry.value;
        final started = v == true || v?.toString() == 'true';
        if (started) {
          map[k] = true;
          if (keys.contains(k)) found = true;
        }
      }
      if (map.length != raw.length) {
        box.put(_confirmArrivalTimerStartedBySessionKey, map);
      }
      return found;
    } catch (_) {
      return false;
    }
  }

  static void markConfirmArrivalTimerStartedForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) {
    final keys = _cooldownKeysForSession(
      sessionId: sessionId,
      cardNumber: cardNumber,
    );
    if (keys.isEmpty) return;
    try {
      if (!Hive.isBoxOpen(_boxName)) return;
      final box = Hive.box(_boxName);
      final raw = box.get(_confirmArrivalTimerStartedBySessionKey);
      final map = <String, bool>{};
      if (raw is Map) {
        for (final entry in raw.entries) {
          final k = entry.key?.toString().trim() ?? '';
          if (k.isEmpty) continue;
          final v = entry.value;
          final started = v == true || v?.toString() == 'true';
          if (started) map[k] = true;
        }
      }
      for (final k in keys) {
        map[k] = true;
      }
      box.put(_confirmArrivalTimerStartedBySessionKey, map);
    } catch (_) {}
  }

  static void saveCustomerMissingDisabledUntilForSessionSync(
    String sessionId,
    DateTime until, {
    int? cardNumber,
  }) {
    _saveDisabledUntilForKeysSync(
      mapKey: _customerMissingDisabledUntilBySessionKey,
      targetKeys: _cooldownKeysForSession(
        sessionId: sessionId,
        cardNumber: cardNumber,
      ),
      until: until,
    );
  }

  static DateTime? getConfirmArrivalDisabledUntilForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) {
    return _getDisabledUntilForKeysSync(
      mapKey: _confirmArrivalDisabledUntilBySessionKey,
      candidateKeys: _cooldownKeysForSession(
        sessionId: sessionId,
        cardNumber: cardNumber,
      ),
    );
  }

  static void saveConfirmArrivalDisabledUntilForSessionSync(
    String sessionId,
    DateTime until, {
    int? cardNumber,
  }) {
    _saveDisabledUntilForKeysSync(
      mapKey: _confirmArrivalDisabledUntilBySessionKey,
      targetKeys: _cooldownKeysForSession(
        sessionId: sessionId,
        cardNumber: cardNumber,
      ),
      until: until,
    );
  }

  static DateTime? getConfirmHandoverDisabledUntilForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) {
    return _getDisabledUntilForKeysSync(
      mapKey: _confirmHandoverDisabledUntilBySessionKey,
      candidateKeys: _cooldownKeysForSession(
        sessionId: sessionId,
        cardNumber: cardNumber,
      ),
    );
  }

  static void saveConfirmHandoverDisabledUntilForSessionSync(
    String sessionId,
    DateTime until, {
    int? cardNumber,
  }) {
    _saveDisabledUntilForKeysSync(
      mapKey: _confirmHandoverDisabledUntilBySessionKey,
      targetKeys: _cooldownKeysForSession(
        sessionId: sessionId,
        cardNumber: cardNumber,
      ),
      until: until,
    );
  }

  static bool hasConfirmHandoverTimerStartedForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) {
    final keys = _cooldownKeysForSession(
      sessionId: sessionId,
      cardNumber: cardNumber,
    );
    if (keys.isEmpty) return false;
    try {
      if (!Hive.isBoxOpen(_boxName)) return false;
      final box = Hive.box(_boxName);
      final raw = box.get(_confirmHandoverTimerStartedBySessionKey);
      if (raw is! Map) return false;
      final map = <String, bool>{};
      var found = false;
      for (final entry in raw.entries) {
        final k = entry.key?.toString().trim() ?? '';
        if (k.isEmpty) continue;
        final v = entry.value;
        final started = v == true || v?.toString() == 'true';
        if (started) {
          map[k] = true;
          if (keys.contains(k)) found = true;
        }
      }
      if (map.length != raw.length) {
        box.put(_confirmHandoverTimerStartedBySessionKey, map);
      }
      return found;
    } catch (_) {
      return false;
    }
  }

  static void markConfirmHandoverTimerStartedForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) {
    final keys = _cooldownKeysForSession(
      sessionId: sessionId,
      cardNumber: cardNumber,
    );
    if (keys.isEmpty) return;
    try {
      if (!Hive.isBoxOpen(_boxName)) return;
      final box = Hive.box(_boxName);
      final raw = box.get(_confirmHandoverTimerStartedBySessionKey);
      final map = <String, bool>{};
      if (raw is Map) {
        for (final entry in raw.entries) {
          final k = entry.key?.toString().trim() ?? '';
          if (k.isEmpty) continue;
          final v = entry.value;
          final started = v == true || v?.toString() == 'true';
          if (started) map[k] = true;
        }
      }
      for (final k in keys) {
        map[k] = true;
      }
      box.put(_confirmHandoverTimerStartedBySessionKey, map);
    } catch (_) {}
  }

  static void clearHandoverButtonCooldownForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) {
    final targetKeys = _cooldownKeysForSession(
      sessionId: sessionId,
      cardNumber: cardNumber,
    ).toSet();
    if (targetKeys.isEmpty) return;
    try {
      if (!Hive.isBoxOpen(_boxName)) return;
      final box = Hive.box(_boxName);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      void clearMap(String mapKey) {
        final raw = box.get(mapKey);
        if (raw is! Map) return;
        final map = <String, int>{};
        for (final entry in raw.entries) {
          final k = entry.key?.toString().trim() ?? '';
          if (k.isEmpty || targetKeys.contains(k)) continue;
          final v = entry.value;
          final exp = v is int ? v : int.tryParse(v.toString()) ?? 0;
          if (exp > nowMs) {
            map[k] = exp;
          }
        }
        box.put(mapKey, map);
      }

      clearMap(_customerMissingDisabledUntilBySessionKey);
      clearMap(_confirmHandoverDisabledUntilBySessionKey);
      clearMap(_confirmArrivalDisabledUntilBySessionKey);
      clearMap(_confirmArrivalTimerStartedBySessionKey);
      clearMap(_confirmHandoverTimerStartedBySessionKey);
    } catch (_) {}
  }

  static Future<bool?> getScannerButtonStatus() async {
    try {
      final value = _box.get(_scannerButtonStatusKey);
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return null;
    } catch (e) {
      print('[TokenStorage] ❌ Error reading scanner button status: $e');
      return null;
    }
  }

  static bool? getScannerButtonStatusSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return null;
      final value = Hive.box(_boxName).get(_scannerButtonStatusKey);
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getImageCompressionQuality() async {
    try {
      final value = _box.get(_imageCompressionQualityKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print('[TokenStorage] ❌ Error reading image compression quality: $e');
      return null;
    }
  }

  static Future<int?> getImageCompressionMaxSizeKB() async {
    try {
      final value = _box.get(_imageCompressionMaxSizeKbKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print('[TokenStorage] ❌ Error reading image compression max size: $e');
      return null;
    }
  }

  /// After Collect Keys (accept API): FIFO-ordered retrieval **session ids**
  /// deferred until Confirm Arrival / handover completes. While active park
  /// flow runs, Confirm Arrival is not auto-opened for these ids; after park,
  /// home resumes them one-by-one. Remove with
  /// [removeCollectKeysInTransitAckForSessionSync] when retrieval flow completes.
  /// Cleared when assigned-to-me becomes empty.
  ///
  /// Prefer [saveCollectKeysInTransitAckSync] before closing the retrieval
  /// sheet so pending-session polling cannot open Confirm Arrival before Hive
  /// reflects the new id.
  static void saveCollectKeysInTransitAckSync(String sessionId) {
    try {
      final trimmed = sessionId.trim();
      if (trimmed.isEmpty) return;
      final list = _readCollectKeysInTransitListSync();
      if (!list.any((e) => e.trim() == trimmed)) {
        list.add(trimmed);
      }
      _box.put(_collectKeysInTransitSessionIdsKey, list);
      _box.delete(_collectKeysInTransitSessionIdKey);
    } catch (e) {
      print(
          '[TokenStorage] Error saving collect-keys-in-transit ack (sync): $e');
    }
  }

  static Future<void> saveCollectKeysInTransitAck(String sessionId) async {
    saveCollectKeysInTransitAckSync(sessionId);
    return Future.value();
  }

  /// FIFO order of deferred retrieval session ids (Collect Keys done, handover pending).
  static List<String> collectKeysInTransitOrderedIdsSync() {
    return List<String>.from(_readCollectKeysInTransitListSync());
  }

  static List<String> _readCollectKeysInTransitListSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return [];
      final box = Hive.box(_boxName);
      final seen = <String>{};
      final out = <String>[];
      void addUnique(String raw) {
        final s = raw.trim();
        if (s.isEmpty || seen.contains(s)) return;
        seen.add(s);
        out.add(s);
      }

      final raw = box.get(_collectKeysInTransitSessionIdsKey);
      if (raw is List) {
        for (final e in raw) {
          addUnique((e?.toString() ?? ''));
        }
      }
      final legacy = box.get(_collectKeysInTransitSessionIdKey) as String?;
      if (legacy != null && legacy.trim().isNotEmpty) {
        addUnique(legacy);
      }
      return out;
    } catch (_) {
      return [];
    }
  }

  /// Removes one deferred retrieval id after handover / operator completion.
  static void removeCollectKeysInTransitAckForSessionSync(String sessionId) {
    try {
      final t = sessionId.trim();
      if (t.isEmpty) return;
      if (!Hive.isBoxOpen(_boxName)) return;
      final box = Hive.box(_boxName);
      final list = _readCollectKeysInTransitListSync();
      list.removeWhere((e) => e.trim() == t);
      if (list.isEmpty) {
        box.delete(_collectKeysInTransitSessionIdsKey);
        box.delete(_collectKeysInTransitSessionIdKey);
      } else {
        box.put(_collectKeysInTransitSessionIdsKey, list);
      }
    } catch (e) {
      print('[TokenStorage] Error removing collect-keys-in-transit id: $e');
    }
  }

  /// True if this session had Collect Keys deferred (handover not done yet).
  static Future<bool> collectKeysInTransitAckContains(String sessionId) async {
    return collectKeysInTransitAckContainsSync(sessionId);
  }

  static bool collectKeysInTransitAckContainsSync(String sessionId) {
    final t = sessionId.trim();
    if (t.isEmpty) return false;
    return _readCollectKeysInTransitListSync().any((e) => e.trim() == t);
  }

  /// Call when Confirm Arrival is popped after handover or operator completion so
  /// stale pending data cannot re-push the same screen for a second or two.
  static void markRetrievalConfirmFlowCompletedCooldownSync(String sessionId) {
    final t = sessionId.trim();
    if (t.isEmpty) return;
    try {
      if (!Hive.isBoxOpen(_boxName)) return;
      final box = Hive.box(_boxName);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final until = nowMs + _retrievalConfirmFlowCooldown.inMilliseconds;
      final raw = box.get(_retrievalConfirmFlowCooldownUntilKey);
      final map = <String, int>{};
      if (raw is Map) {
        for (final e in raw.entries) {
          final k = e.key?.toString().trim() ?? '';
          if (k.isEmpty) continue;
          final v = e.value;
          final exp = v is int ? v : int.tryParse(v.toString()) ?? 0;
          if (exp > nowMs) map[k] = exp;
        }
      }
      map[t] = until;
      box.put(_retrievalConfirmFlowCooldownUntilKey, map);
    } catch (e) {
      print(
        '[TokenStorage] Error marking retrieval confirm cooldown: $e',
      );
    }
  }

  /// True while cooldown is active — skip auto-navigation to Confirm Arrival for this session.
  static bool shouldSuppressAutoConfirmArrivalForSessionSync(String sessionId) {
    final t = sessionId.trim();
    if (t.isEmpty) return false;
    try {
      if (!Hive.isBoxOpen(_boxName)) return false;
      final raw = Hive.box(_boxName).get(_retrievalConfirmFlowCooldownUntilKey);
      if (raw is! Map) return false;
      final v = raw[t];
      final until = v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
      return DateTime.now().millisecondsSinceEpoch < until;
    } catch (_) {
      return false;
    }
  }

  static Future<void> clearCollectKeysInTransitAck() async {
    try {
      await _box.delete(_collectKeysInTransitSessionIdsKey);
      await _box.delete(_collectKeysInTransitSessionIdKey);
    } catch (e) {
      print('[TokenStorage] Error clearing collect-keys-in-transit ack: $e');
    }
  }

  static void clearCollectKeysInTransitAckSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return;
      final box = Hive.box(_boxName);
      box.delete(_collectKeysInTransitSessionIdsKey);
      box.delete(_collectKeysInTransitSessionIdKey);
    } catch (_) {}
  }

  // Driver assigned cards (for park-time ownership check against local allocation)
  static Future<void> saveDriverAssignedCardNumbers(List<int> cardNumbers) async {
    try {
      await _box.put(_driverAssignedCardNumbersKey, cardNumbers);
      await _box.put(_driverAssignedCardsLoadedKey, true);
    } catch (e) {
      print('[TokenStorage] Error saving driver assigned cards: $e');
    }
  }

  static Future<List<int>> getDriverAssignedCardNumbers() async {
    try {
      final raw = _box.get(_driverAssignedCardNumbersKey);
      if (raw is List) {
        return raw.whereType<int>().toList(growable: false);
      }
      return const <int>[];
    } catch (e) {
      print('[TokenStorage] Error reading driver assigned cards: $e');
      return const <int>[];
    }
  }

  /// Sync getter for use in submit guards and other non-async contexts.
  static List<int> getDriverAssignedCardNumbersSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return const <int>[];
      final raw = Hive.box(_boxName).get(_driverAssignedCardNumbersKey);
      if (raw is List) {
        return raw.whereType<int>().toList(growable: false);
      }
      return const <int>[];
    } catch (_) {
      return const <int>[];
    }
  }

  /// Returns true only if the card number is in the driver's locally stored allocation list.
  /// An empty list blocks all cards until cards are fetched and saved (login, splash, or My Cards sync).
  static bool isDriverCardNumberAllowedSync(int cardNumber) {
    final cards = getDriverAssignedCardNumbersSync();
    if (cards.isEmpty) return false;
    return cards.contains(cardNumber);
  }

  /// False while GET /drivers/my-cards is still running after login.
  static bool isDriverAssignedCardsLoadedSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return false;
      return (Hive.box(_boxName).get(_driverAssignedCardsLoadedKey) as bool?) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDriverAssignedCardsLoading() async {
    try {
      await _box.put(_driverAssignedCardsLoadedKey, false);
    } catch (e) {
      print('[TokenStorage] Error marking driver cards loading: $e');
    }
  }

  static Future<bool> hasDriverAssignedCardNumbers() async {
    final cards = await getDriverAssignedCardNumbers();
    return cards.isNotEmpty;
  }

  /// Clears locally stored card allocation only when data from a prior session exists.
  static Future<bool> clearDriverAssignedCardNumbersIfPresent() async {
    if (!await hasDriverAssignedCardNumbers()) return false;
    await clearDriverAssignedCardNumbers();
    return true;
  }

  static Future<void> clearDriverAssignedCardNumbers() async {
    try {
      await _box.delete(_driverAssignedCardNumbersKey);
      await _box.delete(_driverAssignedCardsLoadedKey);
    } catch (e) {
      print('[TokenStorage] Error clearing driver assigned cards: $e');
    }
  }

  static void clearDriverAssignedCardNumbersSync() {
    try {
      if (!Hive.isBoxOpen(_boxName)) return;
      final box = Hive.box(_boxName);
      box.delete(_driverAssignedCardNumbersKey);
      box.delete(_driverAssignedCardsLoadedKey);
    } catch (_) {}
  }

  static Future<void> clearDriverConnectivityLogData() async {
    try {
      await _box.delete(_driverConnectivityShiftIdKey);
      await _box.delete(_driverConnectivityOutletIdKey);
      await _box.delete(_connectivityPendingEventsJsonKey);
      await _box.delete(_connectivityNextFlushDueUtcMillisKey);
      await _box.delete(_driverConnectivityEnabledKey);
      await _box.delete(_driverConnectivitySettingsOutletIdKey);
    } catch (e) {
      print('[TokenStorage] Error clearing driver connectivity log: $e');
    }
  }

  static Future<void> saveDriverConnectivityShiftContext({
    required int shiftId,
    required int outletId,
  }) async {
    try {
      await _box.put(_driverConnectivityShiftIdKey, shiftId);
      await _box.put(_driverConnectivityOutletIdKey, outletId);
    } catch (e) {
      print('[TokenStorage] Error saving driver connectivity context: $e');
      rethrow;
    }
  }

  static Future<int?> getDriverConnectivityShiftId() async {
    try {
      final v = _box.get(_driverConnectivityShiftIdKey);
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    } catch (e) {
      print('[TokenStorage] Error reading driver connectivity shiftId: $e');
      return null;
    }
  }

  static Future<int?> getDriverConnectivityOutletId() async {
    try {
      final v = _box.get(_driverConnectivityOutletIdKey);
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    } catch (e) {
      print('[TokenStorage] Error reading driver connectivity outletId: $e');
      return null;
    }
  }

  /// Persists whether connectivity features are enabled for this driver (from the settings API).
  static Future<void> saveDriverConnectivityEnabled(bool isEnabled) async {
    try {
      await _box.put(_driverConnectivityEnabledKey, isEnabled);
      print('[TokenStorage] Saved driverConnectivityEnabled = $isEnabled');
    } catch (e) {
      print('[TokenStorage] Error saving driver connectivity enabled flag: $e');
    }
  }

  /// Returns the last known value of driver connectivity enabled flag.
  /// Defaults to true if never fetched.
  static Future<bool> getDriverConnectivityEnabled() async {
    try {
      final v = _box.get(_driverConnectivityEnabledKey);
      if (v is bool) return v;
      // Default to true if not present (fail open for logging)
      return true;
    } catch (e) {
      print('[TokenStorage] Error reading driver connectivity enabled flag: $e');
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
      await _box.put(_driverConnectivityEnabledKey, isEnabled);
      await _box.put(_driverConnectivitySettingsOutletIdKey, outletId);
      // Silent on success — only errors are printed
    } catch (e) {
      print('[TokenStorage] Error saving driver connectivity settings: $e');
    }
  }

  /// Clears only the connectivity settings data fetched from /connectivity/settings/me.
  /// Called on every new driver login before storing fresh data.
  static Future<void> clearDriverConnectivitySettings() async {
    try {
      await _box.delete(_driverConnectivityEnabledKey);
      await _box.delete(_driverConnectivitySettingsOutletIdKey);
      // Silent clear on every login — only errors are printed
    } catch (e) {
      print('[TokenStorage] Error clearing driver connectivity settings: $e');
    }
  }

  /// Optional: get the outletId that was returned by the last /connectivity/settings/me call.
  static Future<int?> getDriverConnectivitySettingsOutletId() async {
    try {
      final v = _box.get(_driverConnectivitySettingsOutletIdKey);
      if (v is int) return v;
      return int.tryParse(v?.toString() ?? '');
    } catch (e) {
      print('[TokenStorage] Error reading driver connectivity settings outletId: $e');
      return null;
    }
  }

  static Future<void> saveConnectivityNextFlushDue(DateTime utc) async {
    try {
      await _box.put(
        _connectivityNextFlushDueUtcMillisKey,
        utc.millisecondsSinceEpoch,
      );
    } catch (e) {
      print('[TokenStorage] Error saving connectivity flush schedule: $e');
      rethrow;
    }
  }

  static Future<DateTime?> getConnectivityNextFlushDue() async {
    try {
      final v = _box.get(_connectivityNextFlushDueUtcMillisKey);
      if (v is! int) return null;
      return DateTime.fromMillisecondsSinceEpoch(v, isUtc: true);
    } catch (e) {
      print('[TokenStorage] Error reading connectivity flush schedule: $e');
      return null;
    }
  }

  static Future<String?> getConnectivityPendingEventsJson() async {
    try {
      return _box.get(_connectivityPendingEventsJsonKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error reading connectivity pending events: $e');
      return null;
    }
  }

  static Future<void> saveConnectivityPendingEventsJson(String json) async {
    try {
      await _box.put(_connectivityPendingEventsJsonKey, json);
    } catch (e) {
      print('[TokenStorage] Error saving connectivity pending events: $e');
      rethrow;
    }
  }

  static Future<void> clearConnectivityPendingEvents() async {
    try {
      await _box.delete(_connectivityPendingEventsJsonKey);
    } catch (e) {
      print('[TokenStorage] Error clearing connectivity pending events: $e');
    }
  }

  static Future<void> saveCachedAuthContext({
    required List<String> normalizedRoles,
    required String userId,
  }) async {
    try {
      await _box.put(_cachedNormalizedRolesKey, normalizedRoles);
      await _box.put(_cachedUserIdKey, userId);
    } catch (e) {
      print('[TokenStorage] Error saving cached auth context: $e');
      rethrow;
    }
  }

  static Future<List<String>?> getCachedNormalizedRoles() async {
    try {
      final raw = _box.get(_cachedNormalizedRolesKey);
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return null;
    } catch (e) {
      print('[TokenStorage] Error reading cached roles: $e');
      return null;
    }
  }

  static Future<String?> getCachedUserId() async {
    try {
      return _box.get(_cachedUserIdKey) as String?;
    } catch (e) {
      print('[TokenStorage] Error reading cached user id: $e');
      return null;
    }
  }

  static Future<void> clearCachedAuthContext() async {
    try {
      await _box.delete(_cachedNormalizedRolesKey);
      await _box.delete(_cachedUserIdKey);
    } catch (e) {
      print('[TokenStorage] Error clearing cached auth context: $e');
    }
  }

  // Bulk helpers
  static Future<void> clearAllTokens() async {
    await clearAccessToken();
    await clearRefreshToken();
  }

  static Future<void> clearAll() async {
    await clearAllTokens();
    await clearCachedAuthContext();
    await clearUserName();
    await clearPhoneNumber();
    await clearResetToken();
    await clearSessionId();
    await clearSelectedOutlet();
    await clearCurrentLocation();
    await clearDriverConnectivityLogData();
    await clearDriverAssignedCardNumbers();
    await clearCachedParkedSessions();
    await _box.delete(_confirmArrivalDisableSecondsKey);
    await _box.delete(_confirmArrivalDisabledUntilBySessionKey);
    await _box.delete(_confirmArrivalTimerStartedBySessionKey);
    await _box.delete(_customerMissingDisableSecondsKey);
    await _box.delete(_confirmHandoverDisableSecondsKey);
    await _box.delete(_confirmHandoverTimerStartedBySessionKey);
    await _box.delete(_customerMissingDisabledUntilBySessionKey);
    await _box.delete(_confirmHandoverDisabledUntilBySessionKey);
    await _box.delete(_scannerButtonStatusKey);
    await _box.delete(_imageCompressionQualityKey);
    await _box.delete(_imageCompressionMaxSizeKbKey);
  }

  static Future<bool> hasValidTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return (access != null && access.isNotEmpty) ||
        (refresh != null && refresh.isNotEmpty);
  }
}
