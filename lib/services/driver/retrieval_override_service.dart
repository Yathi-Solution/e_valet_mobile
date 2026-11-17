import 'package:evalet/api/driver/assigned_sessions_api_service.dart';
import 'package:evalet/api/driver/sessions_pending_api.dart';
import 'package:evalet/api/operator/operator_dashboard/operator_assign_retrieval_api_service.dart';

/// What the server says about a retrieval the driver is working on.
enum RetrievalOverrideResult {
  /// Nothing changed.
  none,

  /// The car is now marked as arrived; the handover stage should be shown.
  arrived,

  /// The operator marked the session parked or completed.
  completedByOperator,

  /// The session is no longer assigned to this driver.
  removedFromAssigned,
}

/// Detects an operator changing a retrieval from the dashboard while the
/// driver is on the Confirm Arrival screen.
class RetrievalOverrideService {
  /// Checks the server for [sessionId].
  ///
  /// [isHandoverShown] is read again between requests because the screen can
  /// move to the handover stage while a request is in flight.
  static Future<RetrievalOverrideResult> check(
    String sessionId, {
    required bool Function() isHandoverShown,
  }) async {
    // 1) GET /operators/assign-retrieval - primary source for status when
    //    the operator changes it in Car Logs.
    final assignmentStatus =
        await OperatorAssignRetrievalApiService.getAssignmentStatus(
      sessionId: sessionId,
    );
    if (assignmentStatus != null) {
      if (assignmentStatus.isParked || assignmentStatus.isCompleted) {
        return RetrievalOverrideResult.completedByOperator;
      }
      if (!isHandoverShown() && assignmentStatus.isArrived) {
        return RetrievalOverrideResult.arrived;
      }
    }

    // 2) Fallback: the session leaves assigned-to-me when the operator
    //    completes it.
    final sessions = await AssignedSessionsApiService.fetchAssignedSessions();
    if (!sessions.any((s) => s.id == sessionId)) {
      return RetrievalOverrideResult.removedFromAssigned;
    }

    // 3) Fallback: GET /sessions/pending - the operator may have changed it
    //    to ARRIVED.
    if (!isHandoverShown()) {
      final pending = await SessionsPendingApiService.getPendingSessions();
      final matching =
          pending.sessions.where((s) => s.sessionId == sessionId).toList();
      if (matching.isNotEmpty && matching.first.isArrived) {
        return RetrievalOverrideResult.arrived;
      }
    }
    return RetrievalOverrideResult.none;
  }
}
