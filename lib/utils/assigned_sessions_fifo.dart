import 'package:evalet/models/driver/session/assigned_session.dart';

/// Puts assigned sessions in FIFO order: oldest [AssignedSession.assignedAt] first.
/// The retrieval sheet uses [List.first]; without this, API order alone decides "next".
DateTime? _parseAssignedAt(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return null;
  return DateTime.tryParse(t);
}

String _idOfDynamic(dynamic s) {
  if (s is AssignedSession) return s.id;
  if (s is Map<String, dynamic>) {
    return (s['sessionId'] ?? s['id'] ?? '').toString();
  }
  return '';
}

DateTime? _assignedAtOfDynamic(dynamic s) {
  if (s is AssignedSession) return _parseAssignedAt(s.assignedAt);
  if (s is Map<String, dynamic>) {
    return _parseAssignedAt((s['assignedAt'] ?? '').toString());
  }
  return null;
}

/// Compare for FIFO: earlier assignment first; missing dates last; tie-break by id.
int compareAssignedSessionsFifo(dynamic a, dynamic b) {
  final da = _assignedAtOfDynamic(a);
  final db = _assignedAtOfDynamic(b);
  if (da == null && db == null)
    return _idOfDynamic(a).compareTo(_idOfDynamic(b));
  if (da == null) return 1;
  if (db == null) return -1;
  final c = da.compareTo(db);
  if (c != 0) return c;
  return _idOfDynamic(a).compareTo(_idOfDynamic(b));
}

/// Normalizes order for GET /sessions/assigned-to-me and WebSocket payloads.
List<AssignedSession> sortAssignedSessionsFifo(List<AssignedSession> sessions) {
  final out = List<AssignedSession>.from(sessions);
  out.sort(compareAssignedSessionsFifo);
  return out;
}

List<dynamic> sortAssignedSessionsFifoDynamic(List<dynamic> sessions) {
  final out = List<dynamic>.from(sessions);
  out.sort(compareAssignedSessionsFifo);
  return out;
}
