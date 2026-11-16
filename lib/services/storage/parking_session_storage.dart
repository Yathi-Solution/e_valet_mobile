import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/services/storage/auth_box.dart';

/// The driver's current parking session: ids, pending photo, assigned session data and the cached parked-sessions list.
///
/// Stored in the shared [AuthBox].
class ParkingSessionStorage {
  static const String _cachedParkedSessionsJsonKey =
      'cached_parked_sessions_json';
  static const String _sessionIdKey = 'session_id';
  static const String _pendingPhotoKey = 'pending_photo_path';
  static const String _sessionIdFromGetApiKey = 'session_id_from_get_api';
  static const String _assignedSessionDataKey = 'assigned_session_data';

  static Future<void> saveCachedParkedSessionsJson(String json) async {
    try {
      await AuthBox.box.put(_cachedParkedSessionsJsonKey, json);
    } catch (e) {
      print('[ParkingSessionStorage] Error saving cached parked sessions: $e');
    }
  }

  static Future<String?> getCachedParkedSessionsJson() async {
    try {
      return AuthBox.box.get(_cachedParkedSessionsJsonKey) as String?;
    } catch (e) {
      print('[ParkingSessionStorage] Error reading cached parked sessions: $e');
      return null;
    }
  }

  static Future<void> clearCachedParkedSessions() async {
    try {
      await AuthBox.box.delete(_cachedParkedSessionsJsonKey);
    } catch (e) {
      print(
          '[ParkingSessionStorage] Error clearing cached parked sessions: $e');
    }
  }

  // Session ID (for parking session)
  static Future<void> saveSessionId(String sessionId) async {
    try {
      await AuthBox.box.put(_sessionIdKey, sessionId);
    } catch (e) {
      print('[ParkingSessionStorage] Error saving session ID: $e');
      rethrow;
    }
  }

  static Future<String?> getSessionId() async {
    try {
      final sessionId = AuthBox.box.get(_sessionIdKey) as String?;
      return sessionId;
    } catch (e) {
      print('[ParkingSessionStorage] Error retrieving session ID: $e');
      return null;
    }
  }

  /// Sync read for park-flow checks (e.g. camera vs retrieval session match).
  static String? getSessionIdSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return null;
      return Hive.box(AuthBox.name).get(_sessionIdKey) as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearSessionId() async {
    try {
      await AuthBox.box.delete(_sessionIdKey);
    } catch (e) {
      print('[ParkingSessionStorage] Error clearing session ID: $e');
    }
  }

  static Future<bool> hasSessionId() async {
    final sessionId = await getSessionId();
    return sessionId != null && sessionId.isNotEmpty;
  }

  // Pending photo management
  static Future<void> savePendingPhotoPath(String photoPath) async {
    try {
      await AuthBox.box.put(_pendingPhotoKey, photoPath);
    } catch (e) {
      print('[ParkingSessionStorage] Error saving pending photo path: $e');
      rethrow;
    }
  }

  static Future<String?> getPendingPhotoPath() async {
    try {
      return AuthBox.box.get(_pendingPhotoKey) as String?;
    } catch (e) {
      print('[ParkingSessionStorage] Error retrieving pending photo path: $e');
      return null;
    }
  }

  static Future<void> clearPendingPhotoPath() async {
    try {
      await AuthBox.box.delete(_pendingPhotoKey);
    } catch (e) {
      print('[ParkingSessionStorage] Error clearing pending photo path: $e');
    }
  }

  // Session ID from GET API management
  static Future<void> saveSessionIdFromGetApi(String sessionId) async {
    try {
      await AuthBox.box.put(_sessionIdFromGetApiKey, sessionId);
    } catch (e) {
      print(
          '[ParkingSessionStorage] ❌ Error saving sessionId from GET API: $e');
      rethrow;
    }
  }

  static Future<String?> getSessionIdFromGetApi() async {
    try {
      final sessionId = AuthBox.box.get(_sessionIdFromGetApiKey) as String?;
      return sessionId;
    } catch (e) {
      print(
          '[ParkingSessionStorage] ❌ Error retrieving sessionId from GET API: $e');
      return null;
    }
  }

  static Future<void> clearSessionIdFromGetApi() async {
    try {
      await AuthBox.box.delete(_sessionIdFromGetApiKey);
    } catch (e) {
      print(
          '[ParkingSessionStorage] ❌ Error clearing sessionId from GET API: $e');
    }
  }

  // Assigned Session Data management
  static Future<void> saveAssignedSessionData(
      Map<String, dynamic> sessionData) async {
    try {
      await AuthBox.box.put(_assignedSessionDataKey, sessionData);
    } catch (e) {
      print('[ParkingSessionStorage] ❌ Error saving assigned session data: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getAssignedSessionData() async {
    try {
      final data =
          AuthBox.box.get(_assignedSessionDataKey) as Map<String, dynamic>?;
      return data;
    } catch (e) {
      print(
          '[ParkingSessionStorage] ❌ Error retrieving assigned session data: $e');
      return null;
    }
  }

  static Future<void> clearAssignedSessionData() async {
    try {
      await AuthBox.box.delete(_assignedSessionDataKey);
    } catch (e) {
      print(
          '[ParkingSessionStorage] ❌ Error clearing assigned session data: $e');
    }
  }
}
