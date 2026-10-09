import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:niloufer_valet_mobile/api/driver/connectivity_log_api_service.dart';
import 'package:niloufer_valet_mobile/models/driver/connectivity/connectivity_log_batch_request.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

/// Logs driver internet on/off transitions locally and POSTs batches every 3h from login
/// (or immediately when back online if a flush was due while offline).
///
/// Payload enums (backend / Prisma): `ConnectivityStatus` CONNECTED | DISCONNECTED;
/// `NetworkType` WIFI | MOBILE_DATA.
class DriverConnectivityLogService {
  DriverConnectivityLogService._();
  static final DriverConnectivityLogService instance = DriverConnectivityLogService._();

  static const Duration _flushInterval = Duration(hours: 3);
  static const String _statusConnected = 'CONNECTED';
  static const String _statusDisconnected = 'DISCONNECTED';

  static const String _netWifi = 'WIFI';
  static const String _netMobileData = 'MOBILE_DATA';

  bool? _baselineRecorded;
  bool? _lastOnline;
  String? _lastWifiOrMobileLabel;

  /// Call after a successful clock-in so shift/outlet context exists for batch POSTs.
  Future<void> onShiftActiveAfterClockIn({
    required int shiftId,
    required int outletId,
  }) async {
    if (shiftId <= 0 || outletId <= 0) return;
    await TokenStorage.saveDriverConnectivityShiftContext(
      shiftId: shiftId,
      outletId: outletId,
    );
  }

  /// Call after driver login when connectivity settings are fetched.
  /// Clears any prior session events and starts the 3h flush window from login time.
  Future<void> onDriverLoginSessionStarted({
    required bool isEnabled,
  }) async {
    _baselineRecorded = null;
    _lastOnline = null;
    _lastWifiOrMobileLabel = null;

    if (!isEnabled) {
      await TokenStorage.clearConnectivityPendingEvents();
      return;
    }

    await TokenStorage.clearConnectivityPendingEvents();
    await TokenStorage.saveConnectivityNextFlushDue(
      DateTime.now().toUtc().add(_flushInterval),
    );
  }

  /// Sync shift/outlet from GET /drivers/me/status (e.g. after app restart).
  Future<void> syncFromDriverStatus({
    required int shiftId,
    required int outletId,
    required bool isOffline,
  }) async {
    if (isOffline || shiftId <= 0 || outletId <= 0) return;
    await TokenStorage.saveDriverConnectivityShiftContext(
      shiftId: shiftId,
      outletId: outletId,
    );
    final existing = await TokenStorage.getConnectivityNextFlushDue();
    if (existing == null) {
      await TokenStorage.saveConnectivityNextFlushDue(
        DateTime.now().toUtc().add(_flushInterval),
      );
    }
  }

  Future<void> clearOnLogout() async {
    await TokenStorage.clearDriverConnectivityLogData();
    _baselineRecorded = null;
    _lastOnline = null;
    _lastWifiOrMobileLabel = null;
  }

  /// POSTs queued connectivity events **before** tokens are cleared (e.g. logout).
  /// Ignores the 3-hour schedule. No-op if offline, no shift, or nothing queued.
  Future<void> flushPendingIgnoringSchedule() async {
    final shiftId = await TokenStorage.getDriverConnectivityShiftId();
    if (shiftId == null || shiftId <= 0) return;

    // If admin disabled connectivity logging for this driver, skip flushing.
    final connectivityEnabled = await TokenStorage.getDriverConnectivityEnabled();
    if (!connectivityEnabled) return;

    final outletId = await TokenStorage.getDriverConnectivityOutletId();
    if (outletId == null || outletId <= 0) return;

    final events = await _loadEvents();
    if (events.isEmpty) return;

    if (!await _isInternetReachable()) {
      log(
        'DriverConnectivityLogService: pre-logout flush skipped (device offline)',
      );
      return;
    }

    try {
      await ConnectivityLogApiService.postBatch(
        ConnectivityLogBatchRequest(
          outletId: outletId,
          shiftId: shiftId,
          events: events,
        ),
      );
      await TokenStorage.clearConnectivityPendingEvents();
      log(
        'DriverConnectivityLogService: pre-logout flushed ${events.length} event(s)',
      );
    } catch (e, st) {
      log(
        'DriverConnectivityLogService: pre-logout flush failed (logout continues): $e',
        stackTrace: st,
      );
    }
  }

  /// Logs CONNECTED / DISCONNECTED transitions when actual internet reachability changes.
  Future<void> handleInternetState({
    required bool isOnline,
    required List<ConnectivityResult> results,
  }) async {
    final shiftId = await TokenStorage.getDriverConnectivityShiftId();
    if (shiftId == null || shiftId <= 0) {
      _baselineRecorded = null;
      _lastOnline = null;
      _lastWifiOrMobileLabel = null;
      return;
    }

    final connectivityEnabled = await TokenStorage.getDriverConnectivityEnabled();
    if (!connectivityEnabled) {
      return;
    }

    final networkType = _resolveWifiOrMobileLabel(results);

    if (_baselineRecorded != true) {
      _lastOnline = isOnline;
      _lastWifiOrMobileLabel = networkType;
      _baselineRecorded = true;
      return;
    }

    if (isOnline == _lastOnline && networkType == _lastWifiOrMobileLabel) {
      return;
    }

    _lastOnline = isOnline;
    _lastWifiOrMobileLabel = networkType;

    final status = isOnline ? _statusConnected : _statusDisconnected;

    await _appendEvent(
      ConnectivityLogEventItem(
        status: status,
        networkType: networkType,
        occurredAt: _formatOccurredAt(DateTime.now().toUtc()),
      ),
    );

    if (isOnline) {
      await tryFlushIfDue();
    }
  }

  /// Called from a periodic timer and when returning online.
  Future<void> tryFlushIfDue() async {
    final shiftId = await TokenStorage.getDriverConnectivityShiftId();
    if (shiftId == null || shiftId <= 0) return;

    // Respect driver connectivity settings flag.
    final connectivityEnabled = await TokenStorage.getDriverConnectivityEnabled();
    if (!connectivityEnabled) return;

    if (!await _isInternetReachable()) {
      return;
    }

    final outletId = await TokenStorage.getDriverConnectivityOutletId();
    if (outletId == null || outletId <= 0) return;

    final events = await _loadEvents();
    if (events.isEmpty) {
      await _rollNextFlushIfPastDueOnly();
      return;
    }

    final nextDue = await TokenStorage.getConnectivityNextFlushDue();
    final now = DateTime.now().toUtc();
    if (nextDue != null && now.isBefore(nextDue)) {
      return;
    }

    try {
      await ConnectivityLogApiService.postBatch(
        ConnectivityLogBatchRequest(
          outletId: outletId,
          shiftId: shiftId,
          events: events,
        ),
      );
      await TokenStorage.clearConnectivityPendingEvents();
      await TokenStorage.saveConnectivityNextFlushDue(
        now.add(_flushInterval),
      );
      log('DriverConnectivityLogService: flushed ${events.length} event(s)');
    } catch (e, st) {
      log(
        'DriverConnectivityLogService: batch flush failed (will retry): $e',
        stackTrace: st,
      );
    }
  }

  Future<void> _rollNextFlushIfPastDueOnly() async {
    final nextDue = await TokenStorage.getConnectivityNextFlushDue();
    final now = DateTime.now().toUtc();
    if (nextDue != null && !now.isBefore(nextDue)) {
      await TokenStorage.saveConnectivityNextFlushDue(now.add(_flushInterval));
    }
  }

  Future<void> _appendEvent(ConnectivityLogEventItem item) async {
    final list = await _loadEvents();
    list.add(item);
    await TokenStorage.saveConnectivityPendingEventsJson(
      jsonEncode(list.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<ConnectivityLogEventItem>> _loadEvents() async {
    final raw = await TokenStorage.getConnectivityPendingEventsJson();
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => e as Map<String, dynamic>)
          .map(
            (m) => ConnectivityLogEventItem(
              status: (m['status'] as String? ?? '').trim(),
              networkType: _normalizeStoredNetworkType(m['networkType'] as String? ?? ''),
              occurredAt: m['occurredAt'] as String? ?? '',
            ),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Legacy app versions used CELLULAR; backend enum is MOBILE_DATA.
  static String _normalizeStoredNetworkType(String raw) {
    final s = raw.trim();
    if (s.toUpperCase() == 'CELLULAR') return _netMobileData;
    return s;
  }

  static String _formatOccurredAt(DateTime utc) {
    return utc.toIso8601String();
  }

  Future<bool> _isInternetReachable() async {
    try {
      await InternetAddress.lookup('cloudflare.com').timeout(
        const Duration(seconds: 4),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Maps interface to API [NetworkType]: WIFI | MOBILE_DATA (never NONE).
  String _resolveWifiOrMobileLabel(List<ConnectivityResult> results) {
    if (results.contains(ConnectivityResult.wifi)) return _netWifi;
    if (results.contains(ConnectivityResult.mobile)) return _netMobileData;
    if (results.any((r) => r != ConnectivityResult.none)) {
      return _netMobileData;
    }
    return _lastWifiOrMobileLabel ?? _netWifi;
  }
}
