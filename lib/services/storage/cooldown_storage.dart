import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/services/storage/auth_box.dart';

/// Per-session button cooldowns for Confirm Arrival, Customer Missing and Handover.
///
/// Stored in the shared [AuthBox].
class CooldownStorage {
  static const String _confirmArrivalDisabledUntilBySessionKey =
      'confirm_arrival_disabled_until_by_session';
  static const String _confirmArrivalTimerStartedBySessionKey =
      'confirm_arrival_timer_started_by_session';
  static const String _customerMissingDisabledUntilBySessionKey =
      'customer_missing_disabled_until_by_session';
  static const String _confirmHandoverDisabledUntilBySessionKey =
      'confirm_handover_disabled_until_by_session';
  static const String _confirmHandoverTimerStartedBySessionKey =
      'confirm_handover_timer_started_by_session';

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
      if (!Hive.isBoxOpen(AuthBox.name)) return null;
      final box = Hive.box(AuthBox.name);
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
      if (!Hive.isBoxOpen(AuthBox.name)) return;
      final box = Hive.box(AuthBox.name);
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
      if (!Hive.isBoxOpen(AuthBox.name)) return false;
      final box = Hive.box(AuthBox.name);
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
      if (!Hive.isBoxOpen(AuthBox.name)) return;
      final box = Hive.box(AuthBox.name);
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
      if (!Hive.isBoxOpen(AuthBox.name)) return false;
      final box = Hive.box(AuthBox.name);
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
      if (!Hive.isBoxOpen(AuthBox.name)) return;
      final box = Hive.box(AuthBox.name);
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
      if (!Hive.isBoxOpen(AuthBox.name)) return;
      final box = Hive.box(AuthBox.name);
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

  /// Removes every per-session cooldown. Called on logout.
  static Future<void> clear() async {
    await AuthBox.box.delete(_confirmArrivalDisabledUntilBySessionKey);
    await AuthBox.box.delete(_confirmArrivalTimerStartedBySessionKey);
    await AuthBox.box.delete(_confirmHandoverTimerStartedBySessionKey);
    await AuthBox.box.delete(_customerMissingDisabledUntilBySessionKey);
    await AuthBox.box.delete(_confirmHandoverDisabledUntilBySessionKey);
  }
}
