import 'package:evalet/bloc/driver/assigned_sessions_background/assigned_sessions_background_bloc.dart';
import 'package:evalet/models/driver/session/assigned_session.dart';
import 'package:evalet/models/driver/session/pending_session.dart';
import 'package:evalet/models/driver/session/pending_sessions_response.dart';
import 'package:evalet/services/storage/parking_session_storage.dart';
import 'package:evalet/services/storage/retrieval_flow_storage.dart';
import 'package:evalet/ui/driver/driver_home/park_flow_signals.dart';
import 'package:evalet/utils/session_converter.dart';

bool _isCarPhotoParkFlowActive() => ParkFlowSignals.isCarPhotoParkFlowActive;

/// What the driver home should open next for the driver's pending work.
sealed class DriverFlowStep {
  const DriverFlowStep();
}

/// Nothing to open; the home may still show the retrieval sheet.
class DriverFlowNone extends DriverFlowStep {
  const DriverFlowNone();
}

/// Nothing to open and the retrieval sheet must not be attempted either
/// (a just-submitted park is still syncing).
class DriverFlowHold extends DriverFlowStep {
  const DriverFlowHold();
}

/// Resume a re-park at the car photo screen.
class DriverFlowRepark extends DriverFlowStep {
  const DriverFlowRepark(this.session);
  final PendingSession session;
}

/// A checked-in car still needs its photo: show the "session incomplete" dialog.
class DriverFlowSessionIncomplete extends DriverFlowStep {
  const DriverFlowSessionIncomplete(this.session);
  final PendingSession session;
}

/// Open Confirm Arrival for an accepted or arrived retrieval.
class DriverFlowConfirmArrival extends DriverFlowStep {
  const DriverFlowConfirmArrival(this.session, {required this.isArrived});
  final AssignedSession session;
  final bool isArrived;
}

/// Whether the retrieval request sheet should be shown.
enum RetrievalSheetDecision {
  show,
  skip,

  /// Assignments arrived before the driver menu loaded; check again once it has.
  waitForMenu,
}

/// Decides what the driver home does with pending and assigned sessions.
///
/// Holds no state and does no navigation, so the rules can be unit tested.
/// The stored-flag lookups are injectable for the same reason.
class DriverFlowResolver {
  const DriverFlowResolver({
    this.isCollectKeysAcked =
        RetrievalFlowStorage.collectKeysInTransitAckContainsSync,
    this.isConfirmArrivalSuppressed =
        RetrievalFlowStorage.shouldSuppressAutoConfirmArrivalForSessionSync,
    this.deferredRetrievalIds =
        RetrievalFlowStorage.collectKeysInTransitOrderedIdsSync,
    this.currentParkSessionId = ParkingSessionStorage.getSessionIdSync,
    this.isParkFlowActive = _isCarPhotoParkFlowActive,
  });

  /// True when Collect Keys was tapped for the session and handover is pending.
  final bool Function(String sessionId) isCollectKeysAcked;

  /// True during the short cooldown after a retrieval flow completed.
  final bool Function(String sessionId) isConfirmArrivalSuppressed;

  /// Deferred retrieval session ids, oldest first.
  final List<String> Function() deferredRetrievalIds;

  /// Session id of the park the driver is in the middle of, if any.
  final String? Function() currentParkSessionId;

  /// True while the car photo (park) screens are open.
  final bool Function() isParkFlowActive;

  /// True when every queued assignment id is in collect-keys-in-transit ack
  /// (sheet should stay hidden until park completes or queue clears).
  bool allQueuedSessionsInCollectKeysAck(List<dynamic> sessions) {
    if (sessions.isEmpty) return true;
    for (final s in sessions) {
      final id = AssignedSessionsBackgroundBloc.sessionIdOfFirstSession([s]);
      if (id == null || id.isEmpty) continue;
      if (!isCollectKeysAcked(id)) return false;
    }
    return true;
  }

  String statusOfAssignedQueueEntry(dynamic session) {
    if (session is AssignedSession) {
      return session.retrievalLifecycleStatus;
    }
    if (session is Map<String, dynamic>) {
      final rawStatus = session['status'];
      if (rawStatus is String && rawStatus.trim().isNotEmpty) {
        return rawStatus.trim().toUpperCase();
      }
      if (rawStatus is Map<String, dynamic>) {
        for (final key in ['name', 'value', 'status', 'state', 'code']) {
          final value = rawStatus[key];
          if (value is String && value.trim().isNotEmpty) {
            return value.trim().toUpperCase();
          }
        }
      }
    }
    return '';
  }

  String? firstAssignableRetrievalSessionId(List<dynamic> sessions) {
    for (final session in sessions) {
      final id =
          AssignedSessionsBackgroundBloc.sessionIdOfFirstSession([session]);
      if (id == null || id.isEmpty) continue;
      if (statusOfAssignedQueueEntry(session) != 'ASSIGNED') continue;
      if (isCollectKeysAcked(id)) continue;
      return id;
    }
    return null;
  }

  bool isAssignedRetrievalPendingSession(PendingSession session) {
    final taskType = (session.taskType ?? '').trim().toUpperCase();
    final isRetrievalTask =
        taskType.contains('RETRIEVAL') || taskType.contains('RETRIEVE');
    if (!isRetrievalTask) return false;
    return session.status.trim().toUpperCase() == 'ASSIGNED';
  }

  /// Assigned retrievals found in the pending list, for when the
  /// assigned-to-me feed has not delivered them. Null when there is nothing
  /// to add or the feed already has an assignable retrieval.
  List<AssignedSession>? assignedSessionsToAdoptFromPending(
    PendingSessionsResponse? pending,
    AssignedSessionsBackgroundState assignedState,
  ) {
    if (pending == null) return null;
    final fallbackSessions = <AssignedSession>[];
    for (final pendingSession in pending.sessions) {
      if (!isAssignedRetrievalPendingSession(pendingSession)) continue;
      fallbackSessions.add(SessionConverter.pendingToAssigned(pendingSession));
    }
    if (fallbackSessions.isEmpty) return null;

    if (assignedState is AssignedSessionsBackgroundData &&
        firstAssignableRetrievalSessionId(assignedState.sessions) != null) {
      return null;
    }
    return fallbackSessions;
  }

  /// Deferred Collect Keys: block auto Confirm Arrival only while park flow is active.
  ///
  /// [pending] is the driver menu's pending list, or null when it has none.
  bool canResumeDeferredRetrievalConfirm(
    String sessionId, {
    required bool homeIsCurrent,
    required PendingSessionsResponse? pending,
  }) {
    if (isParkFlowActive()) return false;
    if (!homeIsCurrent) return false;
    final hivePark = currentParkSessionId();
    if (hivePark != null &&
        hivePark.isNotEmpty &&
        hivePark.trim() == sessionId.trim()) {
      return false;
    }
    if (pending != null) {
      final rep = pending.reparkingSession;
      if (rep != null && rep.sessionId.trim() == sessionId.trim()) {
        return false;
      }
      final chk = pending.checkedInSession;
      if (chk != null && chk.sessionId.trim() == sessionId.trim()) {
        return false;
      }
    }
    return true;
  }

  bool pendingSessionNeedsConfirmArrivalNavigation(
    PendingSession s, {
    required bool homeIsCurrent,
    required PendingSessionsResponse? pending,
  }) {
    if (isConfirmArrivalSuppressed(s.sessionId)) {
      return false;
    }
    if (!isCollectKeysAcked(s.sessionId)) {
      return true;
    }
    return canResumeDeferredRetrievalConfirm(
      s.sessionId,
      homeIsCurrent: homeIsCurrent,
      pending: pending,
    );
  }

  /// Same session id as assigned retrieval still needs Confirm Arrival (including deferred after park).
  bool pendingNeedsConfirmForAssignedRetrieval(
    PendingSessionsResponse? pending,
    String assignedRetrievalSessionId, {
    required bool homeIsCurrent,
  }) {
    if (pending == null) return false;
    final aid = assignedRetrievalSessionId.trim();
    if (aid.isEmpty) return false;
    for (final s in pending.sessions) {
      if (s.sessionId.trim() != aid) continue;
      if ((s.isArrived || s.isAccepted) &&
          pendingSessionNeedsConfirmArrivalNavigation(
            s,
            homeIsCurrent: homeIsCurrent,
            pending: pending,
          )) {
        return true;
      }
    }
    return false;
  }

  DateTime? pendingSessionFifoTime(PendingSession session) {
    final assignedAtRaw = (session.assignedAt ?? '').trim();
    if (assignedAtRaw.isNotEmpty) {
      final assignedAt = DateTime.tryParse(assignedAtRaw);
      if (assignedAt != null) return assignedAt;
    }
    final createdAtRaw = session.createdAt.trim();
    if (createdAtRaw.isNotEmpty) {
      return DateTime.tryParse(createdAtRaw);
    }
    return null;
  }

  int comparePendingSessionsFifo(PendingSession a, PendingSession b) {
    final ta = pendingSessionFifoTime(a);
    final tb = pendingSessionFifoTime(b);
    if (ta == null && tb == null) {
      return a.sessionId.compareTo(b.sessionId);
    }
    if (ta == null) return 1;
    if (tb == null) return -1;
    final c = ta.compareTo(tb);
    if (c != 0) return c;
    return a.sessionId.compareTo(b.sessionId);
  }

  /// Driver-flow target selection:
  /// 1) keep first API item if it is a parking continuation task
  /// 2) otherwise resume retrieval Confirm Arrival in FIFO order (oldest first)
  /// 3) fallback to first API item
  PendingSession? nextPendingSessionForDriverFlow(
    PendingSessionsResponse pending,
  ) {
    if (pending.sessions.isEmpty) return null;
    final top = pending.sessions.first;
    if (top.isReparking || top.isCheckedIn) {
      return top;
    }

    final retrievalCandidates = pending.sessions
        .where((s) => s.isArrived || s.isAccepted)
        .toList()
      ..sort(comparePendingSessionsFifo);
    if (retrievalCandidates.isNotEmpty) {
      // Strict FIFO: always keep the oldest accepted/arrived retrieval as head.
      // Do not advance to newer retrievals while this head is pending/suppressed.
      return retrievalCandidates.first;
    }

    return top;
  }

  bool shouldDeferRetrievalSheetForTopPendingTask(
    PendingSessionsResponse? pending,
    String assignedRetrievalSessionId,
  ) {
    if (pending == null || pending.sessions.isEmpty) return false;
    final assignedId = assignedRetrievalSessionId.trim();
    if (assignedId.isEmpty) return false;
    final nextPending = nextPendingSessionForDriverFlow(pending);
    if (nextPending == null) return false;
    if (nextPending.sessionId.trim() != assignedId) return false;
    if (nextPending.isReparking || nextPending.isCheckedIn) return true;
    if (nextPending.isArrived || nextPending.isAccepted) {
      return true;
    }
    return false;
  }

  AssignedSession? findAssignedSessionById(List<dynamic> sessions, String id) {
    final aid = id.trim();
    if (aid.isEmpty) return null;
    for (final s in sessions) {
      if (s is AssignedSession) {
        if (s.id.trim() == aid) return s;
      } else if (s is Map<String, dynamic>) {
        final raw = (s['sessionId'] ?? s['id'])?.toString().trim();
        if (raw == aid) {
          try {
            return AssignedSession.fromJson(s);
          } catch (_) {}
        }
      }
    }
    return null;
  }

  /// When pending API lags, next deferred id may still appear on assigned-to-me only.
  AssignedSession? firstAssignedDeferredNeedingConfirm(
    AssignedSessionsBackgroundState assignedState, {
    required bool homeIsCurrent,
    required PendingSessionsResponse? pending,
  }) {
    final defOrder = deferredRetrievalIds();
    if (defOrder.isEmpty) return null;
    if (assignedState is! AssignedSessionsBackgroundData ||
        !assignedState.hasSessions) {
      return null;
    }
    // Arrived cars first, then accepted ones, each in deferred (FIFO) order.
    for (final wanted in const ['ARRIVED', 'ACCEPTED']) {
      for (final id in defOrder) {
        if (isConfirmArrivalSuppressed(id)) continue;
        final s = findAssignedSessionById(assignedState.sessions, id);
        if (s == null) continue;
        if (s.retrievalLifecycleStatus == wanted &&
            canResumeDeferredRetrievalConfirm(
              id,
              homeIsCurrent: homeIsCurrent,
              pending: pending,
            )) {
          return s;
        }
      }
    }
    return null;
  }

  /// The next screen to open from the driver home, given the current pending
  /// list and assignments. Call only while the home is the current route.
  ///
  /// [nextPending] is [nextPendingSessionForDriverFlow] for [pending].
  /// [isSessionIncompleteSuppressed] is true when the "session incomplete"
  /// dialog must not be shown for that session right now.
  DriverFlowStep resolveNextStep({
    required PendingSessionsResponse? pending,
    required PendingSession? nextPending,
    required AssignedSessionsBackgroundState assignedState,
    required bool Function(String sessionId) isSessionIncompleteSuppressed,
  }) {
    if (pending == null) {
      final assigned = firstAssignedDeferredNeedingConfirm(
        assignedState,
        homeIsCurrent: true,
        pending: null,
      );
      if (assigned == null) return const DriverFlowNone();
      return DriverFlowConfirmArrival(
        assigned,
        isArrived: assigned.retrievalLifecycleStatus == 'ARRIVED',
      );
    }

    final target = nextPending;
    if (target == null) return const DriverFlowNone();

    if (target.isReparking) return DriverFlowRepark(target);

    if (target.isCheckedIn) {
      if (isSessionIncompleteSuppressed(target.sessionId)) {
        return const DriverFlowHold();
      }
      return DriverFlowSessionIncomplete(target);
    }

    if ((target.isArrived || target.isAccepted) &&
        pendingSessionNeedsConfirmArrivalNavigation(
          target,
          homeIsCurrent: true,
          pending: pending,
        )) {
      return DriverFlowConfirmArrival(
        SessionConverter.pendingToAssigned(target),
        isArrived: target.isArrived,
      );
    }

    // Top API row is not actionable for confirm-arrival navigation
    // (e.g. transient stale status); avoid reopening stale retrieval UI.
    return const DriverFlowNone();
  }

  /// Whether to show the retrieval request sheet.
  ///
  /// [menuLoaded] is false until the driver menu has loaded; [pending] is its
  /// pending list. [homeIsCurrent] is false when another driver screen is on
  /// top of the home.
  RetrievalSheetDecision decideRetrievalSheet({
    required AssignedSessionsBackgroundState assignedState,
    required bool menuLoaded,
    required PendingSessionsResponse? pending,
    required bool homeIsCurrent,
  }) {
    if (assignedState is! AssignedSessionsBackgroundData ||
        !assignedState.hasSessions) {
      return RetrievalSheetDecision.skip;
    }

    if (allQueuedSessionsInCollectKeysAck(assignedState.sessions)) {
      return RetrievalSheetDecision.skip;
    }

    final firstId = firstAssignableRetrievalSessionId(assignedState.sessions);
    if (firstId == null || firstId.isEmpty) {
      return RetrievalSheetDecision.skip;
    }
    if (isConfirmArrivalSuppressed(firstId)) {
      return RetrievalSheetDecision.skip;
    }

    if (!menuLoaded) return RetrievalSheetDecision.waitForMenu;

    // If top pending task should be resumed directly (parking or confirm-arrival),
    // don't flash retrieval sheet for 1-2s during refresh races on home.
    // Keep showing the sheet on non-home routes (Confirm Arrival/Handover) so
    // collect-keys in-transit behavior continues to work.
    if (homeIsCurrent &&
        shouldDeferRetrievalSheetForTopPendingTask(pending, firstId)) {
      return RetrievalSheetDecision.skip;
    }

    // Reparking: only block retrieval for the **same** session as this assignment.
    // Otherwise a different REPARKING row was hiding the sheet on camera/preview.
    if (pending != null && pending.hasReparkingSession) {
      final rep = pending.reparkingSession;
      if (rep != null && rep.sessionId.trim() == firstId.trim()) {
        return RetrievalSheetDecision.skip;
      }
    }

    // Block retrieval sheet only when **this** assigned retrieval session still
    // needs Confirm Arrival. Another session’s ACCEPTED/ARRIVED must not hide
    // a new assignment while you’re on another screen.
    if (pendingNeedsConfirmForAssignedRetrieval(
      pending,
      firstId,
      homeIsCurrent: homeIsCurrent,
    )) {
      return RetrievalSheetDecision.skip;
    }

    return RetrievalSheetDecision.show;
  }
}
