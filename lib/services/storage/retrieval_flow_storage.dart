import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/services/storage/auth_box.dart';

/// Retrieval flow markers: sessions with Collect Keys done but handover pending, and the short cooldown after a flow completes.
///
/// Stored in the shared [AuthBox].
class RetrievalFlowStorage {
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
      AuthBox.box.put(_collectKeysInTransitSessionIdsKey, list);
      AuthBox.box.delete(_collectKeysInTransitSessionIdKey);
    } catch (e) {
      print(
          '[RetrievalFlowStorage] Error saving collect-keys-in-transit ack (sync): $e');
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
      if (!Hive.isBoxOpen(AuthBox.name)) return [];
      final box = Hive.box(AuthBox.name);
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
      if (!Hive.isBoxOpen(AuthBox.name)) return;
      final box = Hive.box(AuthBox.name);
      final list = _readCollectKeysInTransitListSync();
      list.removeWhere((e) => e.trim() == t);
      if (list.isEmpty) {
        box.delete(_collectKeysInTransitSessionIdsKey);
        box.delete(_collectKeysInTransitSessionIdKey);
      } else {
        box.put(_collectKeysInTransitSessionIdsKey, list);
      }
    } catch (e) {
      print(
          '[RetrievalFlowStorage] Error removing collect-keys-in-transit id: $e');
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
      if (!Hive.isBoxOpen(AuthBox.name)) return;
      final box = Hive.box(AuthBox.name);
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
        '[RetrievalFlowStorage] Error marking retrieval confirm cooldown: $e',
      );
    }
  }

  /// True while cooldown is active — skip auto-navigation to Confirm Arrival for this session.
  static bool shouldSuppressAutoConfirmArrivalForSessionSync(String sessionId) {
    final t = sessionId.trim();
    if (t.isEmpty) return false;
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return false;
      final raw =
          Hive.box(AuthBox.name).get(_retrievalConfirmFlowCooldownUntilKey);
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
      await AuthBox.box.delete(_collectKeysInTransitSessionIdsKey);
      await AuthBox.box.delete(_collectKeysInTransitSessionIdKey);
    } catch (e) {
      print(
          '[RetrievalFlowStorage] Error clearing collect-keys-in-transit ack: $e');
    }
  }

  static void clearCollectKeysInTransitAckSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return;
      final box = Hive.box(AuthBox.name);
      box.delete(_collectKeysInTransitSessionIdsKey);
      box.delete(_collectKeysInTransitSessionIdKey);
    } catch (_) {}
  }
}
