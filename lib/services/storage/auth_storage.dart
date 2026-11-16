import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/services/storage/auth_box.dart';

/// Access, refresh and reset tokens, plus the cached roles and user id.
///
/// Stored in the shared [AuthBox].
class AuthStorage {
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _accessTokenExpiryKey = 'access_token_expiry';
  static const String _resetTokenKey = 'reset_token';

  /// Last known roles and user id when `/auth/profile` succeeds (splash offline fallback).
  static const String _cachedNormalizedRolesKey = 'cached_normalized_roles_v1';
  static const String _cachedUserIdKey = 'cached_user_id_v1';

  // Access token
  static Future<void> saveAccessToken(String token) async {
    try {
      await AuthBox.box.put(_accessTokenKey, token);
    } catch (e) {
      print('[AuthStorage] Error saving access token: $e');
      rethrow;
    }
  }

  static Future<String?> getAccessToken() async {
    try {
      return AuthBox.box.get(_accessTokenKey) as String?;
    } catch (e) {
      print('[AuthStorage] Error retrieving access token: $e');
      return null;
    }
  }

  static Future<void> saveAccessTokenExpiry(DateTime expiry) async {
    try {
      await AuthBox.box.put(_accessTokenExpiryKey, expiry.toIso8601String());
    } catch (e) {
      print('[AuthStorage] Error saving access token expiry: $e');
      rethrow;
    }
  }

  static Future<DateTime?> getAccessTokenExpiry() async {
    try {
      final expiryStr = AuthBox.box.get(_accessTokenExpiryKey) as String?;
      if (expiryStr == null) return null;
      return DateTime.parse(expiryStr);
    } catch (e) {
      print('[AuthStorage] Error retrieving access token expiry: $e');
      return null;
    }
  }

  static Future<void> clearAccessToken() async {
    try {
      await AuthBox.box.delete(_accessTokenKey);
      await AuthBox.box.delete(_accessTokenExpiryKey);
    } catch (e) {
      print('[AuthStorage] Error clearing access token: $e');
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
      print('[AuthStorage] Error checking token expiry: $e');
      return true; // On error, assume expired
    }
  }

  // Refresh token
  static Future<void> saveRefreshToken(String token) async {
    try {
      await AuthBox.box.put(_refreshTokenKey, token);
    } catch (e) {
      print('[AuthStorage] Error saving refresh token: $e');
      rethrow;
    }
  }

  static Future<String?> getRefreshToken() async {
    try {
      return AuthBox.box.get(_refreshTokenKey) as String?;
    } catch (e) {
      print('[AuthStorage] Error retrieving refresh token: $e');
      return null;
    }
  }

  static Future<void> clearRefreshToken() async {
    try {
      await AuthBox.box.delete(_refreshTokenKey);
    } catch (e) {
      print('[AuthStorage] Error clearing refresh token: $e');
    }
  }

  // Reset token (password reset flow)
  static Future<void> saveResetToken(String token) async {
    try {
      await AuthBox.box.put(_resetTokenKey, token);
    } catch (e) {
      print('[AuthStorage] Error saving reset token: $e');
      rethrow;
    }
  }

  static Future<String?> getResetToken() async {
    try {
      return AuthBox.box.get(_resetTokenKey) as String?;
    } catch (e) {
      print('[AuthStorage] Error retrieving reset token: $e');
      return null;
    }
  }

  static Future<void> clearResetToken() async {
    try {
      await AuthBox.box.delete(_resetTokenKey);
    } catch (e) {
      print('[AuthStorage] Error clearing reset token: $e');
    }
  }

  static Future<void> saveCachedAuthContext({
    required List<String> normalizedRoles,
    required String userId,
  }) async {
    try {
      await AuthBox.box.put(_cachedNormalizedRolesKey, normalizedRoles);
      await AuthBox.box.put(_cachedUserIdKey, userId);
    } catch (e) {
      print('[AuthStorage] Error saving cached auth context: $e');
      rethrow;
    }
  }

  static Future<List<String>?> getCachedNormalizedRoles() async {
    try {
      final raw = AuthBox.box.get(_cachedNormalizedRolesKey);
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return null;
    } catch (e) {
      print('[AuthStorage] Error reading cached roles: $e');
      return null;
    }
  }

  static Future<String?> getCachedUserId() async {
    try {
      return AuthBox.box.get(_cachedUserIdKey) as String?;
    } catch (e) {
      print('[AuthStorage] Error reading cached user id: $e');
      return null;
    }
  }

  /// Sync getter for build methods that need to know who is logged in.
  static String? getCachedUserIdSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return null;
      return Hive.box(AuthBox.name).get(_cachedUserIdKey) as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<void> clearCachedAuthContext() async {
    try {
      await AuthBox.box.delete(_cachedNormalizedRolesKey);
      await AuthBox.box.delete(_cachedUserIdKey);
    } catch (e) {
      print('[AuthStorage] Error clearing cached auth context: $e');
    }
  }

  // Bulk helpers
  static Future<void> clearAllTokens() async {
    await clearAccessToken();
    await clearRefreshToken();
  }

  static Future<bool> hasValidTokens() async {
    final access = await getAccessToken();
    return access != null && access.isNotEmpty;
  }
}
