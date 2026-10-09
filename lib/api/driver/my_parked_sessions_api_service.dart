import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:niloufer_valet_mobile/api/core/api_config.dart';
import 'package:niloufer_valet_mobile/api/core/base_dio_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/parked/my_parked_sessions_response.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';

class MyParkedSessionsApiService {
  MyParkedSessionsApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;
  static MyParkedSessionsResponse? _memoryCache;

  /// Last successfully loaded parked sessions (memory, then disk).
  static Future<MyParkedSessionsResponse?> getCachedParkedSessions() async {
    if (_memoryCache != null) return _memoryCache;

    final json = await TokenStorage.getCachedParkedSessionsJson();
    if (json == null || json.isEmpty) return null;

    try {
      final data = jsonDecode(json);
      if (data is! Map<String, dynamic>) return null;
      _memoryCache = MyParkedSessionsResponse.fromJson(data);
      return _memoryCache;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _saveCache(MyParkedSessionsResponse data) async {
    _memoryCache = data;
    await TokenStorage.saveCachedParkedSessionsJson(jsonEncode(data.toJson()));
  }

  /// Clears in-memory and on-disk parked session cache (e.g. on logout or before fresh login fetch).
  static Future<void> clearCache() async {
    _memoryCache = null;
    await TokenStorage.clearCachedParkedSessions();
  }

  /// Clears stale cache, fetches fresh parked sessions from the API, merges any pending offline parks, and saves.
  static Future<MyParkedSessionsResponse> refreshParkedSessionsForDisplay() async {
    await clearCache();
    final localSessions = await OfflineParkingService.getLocalParkedSessions();

    try {
      final remote = await getMyParkedSessions().timeout(
        const Duration(seconds: 8),
      );
      final merged = _mergeWithLocalSessions(remote, localSessions);
      await _saveCache(merged);
      return merged;
    } catch (_) {
      if (localSessions.isNotEmpty) {
        final localOnly = await _localOnlyResponse(localSessions);
        await _saveCache(localOnly);
        return localOnly;
      }
      rethrow;
    }
  }

  static Future<MyParkedSessionsResponse> getMyParkedSessions() async {
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.get('/drivers/my-parked-sessions');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw ApiException(
          'Unexpected parked sessions response.',
          code: 'bad_parked_sessions_response',
        );
      }
      return MyParkedSessionsResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'Failed to load parked sessions. Please try again.',
        code: 'unknown_error',
      );
    }
  }

  static List<MyParkedSession> _pendingLocalNotIn(
    List<MyParkedSession> baseSessions,
    List<MyParkedSession> localSessions,
  ) {
    final sessionIds = baseSessions.map((s) => s.sessionId.trim()).toSet();
    final cardNumbers = baseSessions.map((s) => s.cardNumber).toSet();
    return localSessions
        .where(
          (session) =>
              !sessionIds.contains(session.sessionId.trim()) &&
              !cardNumbers.contains(session.cardNumber),
        )
        .toList(growable: false);
  }

  static MyParkedSessionsResponse _mergeWithLocalSessions(
    MyParkedSessionsResponse base,
    List<MyParkedSession> localSessions,
  ) {
    if (localSessions.isEmpty) return base;

    final pendingLocal = _pendingLocalNotIn(base.sessions, localSessions);
    if (pendingLocal.isEmpty) return base;

    return MyParkedSessionsResponse(
      outletId: base.outletId,
      outletName: base.outletName,
      sessions: [...base.sessions, ...pendingLocal],
    );
  }

  static Future<MyParkedSessionsResponse> _localOnlyResponse(
    List<MyParkedSession> localSessions,
  ) async {
    final outletId = int.tryParse(dotenv.env['OUTLET_ID'] ?? '') ?? 0;
    final checkins = await OfflineParkingService.getPendingCheckins();
    final outletFromCheckin =
        checkins.isNotEmpty ? checkins.first.outletId : 0;

    return MyParkedSessionsResponse(
      outletId: outletFromCheckin > 0 ? outletFromCheckin : outletId,
      outletName: '',
      sessions: localSessions,
    );
  }

  static Future<MyParkedSessionsResponse> _offlineFallback({
    MyParkedSessionsResponse? prefetched,
    required List<MyParkedSession> localSessions,
    bool saveCache = true,
  }) async {
    final cached = prefetched ?? await getCachedParkedSessions();

    if (cached != null) {
      final merged = _mergeWithLocalSessions(cached, localSessions);
      if (saveCache) await _saveCache(merged);
      return merged;
    }
    if (localSessions.isNotEmpty) {
      final localOnly = await _localOnlyResponse(localSessions);
      if (saveCache) await _saveCache(localOnly);
      return localOnly;
    }
    throw ApiException(
      'Failed to load parked sessions. Please try again.',
      code: 'unknown_error',
    );
  }

  /// Loads server parked sessions and merges any locally saved offline parks.
  /// Updates the in-memory and on-disk cache on success.
  static Future<MyParkedSessionsResponse> loadParkedSessions({
    MyParkedSessionsResponse? prefetched,
  }) async {
    final localSessions = await OfflineParkingService.getLocalParkedSessions();

    try {
      final remote = await getMyParkedSessions();
      final merged = _mergeWithLocalSessions(remote, localSessions);
      await _saveCache(merged);
      return merged;
    } catch (e) {
      return _offlineFallback(
        prefetched: prefetched,
        localSessions: localSessions,
      );
    }
  }

  /// For UI: prefer a fresh load, but fall back to cached + local data when offline.
  static Future<MyParkedSessionsResponse> loadParkedSessionsForDisplay({
    MyParkedSessionsResponse? prefetched,
  }) async {
    final localSessions = await OfflineParkingService.getLocalParkedSessions();

    try {
      final remote = await getMyParkedSessions().timeout(
        const Duration(seconds: 8),
      );
      final merged = _mergeWithLocalSessions(remote, localSessions);
      await _saveCache(merged);
      return merged;
    } catch (_) {
      return _offlineFallback(
        prefetched: prefetched,
        localSessions: localSessions,
      );
    }
  }
}
