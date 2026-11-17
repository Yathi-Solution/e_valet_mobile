import 'package:evalet/models/driver/session/pending_session.dart';

DateTime? _parseTime(String? raw) {
  final t = (raw ?? '').trim();
  if (t.isEmpty) return null;
  return DateTime.tryParse(t);
}

/// Oldest assignment first (matches [sortAssignedSessionsFifo] for assigned-to-me).
List<PendingSession> pendingSessionsFifoSorted(List<PendingSession> sessions) {
  final out = List<PendingSession>.from(sessions);
  out.sort((a, b) {
    final da = _parseTime(a.assignedAt) ?? _parseTime(a.createdAt);
    final db = _parseTime(b.assignedAt) ?? _parseTime(b.createdAt);
    if (da == null && db == null) return a.sessionId.compareTo(b.sessionId);
    if (da == null) return 1;
    if (db == null) return -1;
    final c = da.compareTo(db);
    return c != 0 ? c : a.sessionId.compareTo(b.sessionId);
  });
  return out;
}
