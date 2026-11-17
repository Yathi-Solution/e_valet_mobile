import 'package:evalet/models/driver/session/assigned_session.dart';
import 'package:evalet/models/driver/session/assigned_session_parked_by.dart';
import 'package:evalet/models/driver/session/assigned_session_photo.dart';
import 'package:evalet/models/driver/session/pending_session.dart';

/// Utility class to convert PendingSession to AssignedSession
/// This is used when navigating to screens that require AssignedSession
class SessionConverter {
  SessionConverter._();

  /// Convert a PendingSession to AssignedSession
  /// Uses default/empty values for fields not available in PendingSession
  static AssignedSession pendingToAssigned(PendingSession pendingSession) {
    // Create a status map from the status string
    final statusMap = <String, dynamic>{
      'status': pendingSession.status,
    };

    // Convert ParkedBy to AssignedSessionParkedBy
    AssignedSessionParkedBy? parkedBy;
    if (pendingSession.parkedBy != null) {
      parkedBy = AssignedSessionParkedBy(
        userId: pendingSession.parkedBy!.userId,
        name: pendingSession.parkedBy!.name,
        phone: pendingSession.parkedBy!.phone,
      );
    }

    // Convert photos list - handle both Map and other formats
    final photos = <AssignedSessionPhoto>[];
    if (pendingSession.photos.isNotEmpty) {
      for (final photo in pendingSession.photos) {
        if (photo is Map<String, dynamic>) {
          try {
            photos.add(AssignedSessionPhoto.fromJson(photo));
          } catch (e) {
            // Skip invalid photo entries
            continue;
          }
        }
      }
    }

    return AssignedSession(
      id: pendingSession.sessionId,
      cardNumber: pendingSession.cardNumber,
      status: statusMap,
      outletName: '', // Not available in pending session
      assignedAt: pendingSession.assignedAt ?? pendingSession.createdAt,
      customerPhone: pendingSession.customerPhone ?? '',
      parkedBy: parkedBy,
      photos: photos,
      parkingLocation: pendingSession.parkingLocation ?? '',
    );
  }
}
