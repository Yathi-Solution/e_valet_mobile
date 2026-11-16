import 'package:evalet/bloc/driver/assigned_sessions_background/assigned_sessions_background_bloc.dart';
import 'package:evalet/models/driver/session/assigned_session.dart';
import 'package:evalet/models/driver/session/pending_session.dart';
import 'package:evalet/models/driver/session/pending_sessions_response.dart';
import 'package:evalet/ui/driver/driver_home/driver_flow_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

PendingSession pendingSession(
  String id,
  String status, {
  String? assignedAt,
  String createdAt = '2026-01-01T10:00:00Z',
  String? taskType,
}) =>
    PendingSession(
      sessionId: id,
      cardNumber: 7,
      status: status,
      createdAt: createdAt,
      assignedAt: assignedAt,
      pendingForMinutes: 0,
      taskType: taskType,
    );

PendingSessionsResponse pendingList(List<PendingSession> sessions) =>
    PendingSessionsResponse(
      sessions: sessions,
      count: sessions.length,
      parkingTasksCount: 0,
      retrievalTasksCount: 0,
      hasPendingTasks: sessions.isNotEmpty,
      message: '',
    );

AssignedSession assignedSession(String id, String status) => AssignedSession(
      id: id,
      cardNumber: 7,
      status: {'status': status},
      outletName: '',
      assignedAt: '',
      customerPhone: '',
      parkedBy: null,
      photos: const [],
      parkingLocation: '',
    );

DriverFlowResolver resolver({
  Set<String> acked = const {},
  Set<String> suppressed = const {},
  List<String> deferred = const [],
  String? parkSessionId,
  bool parkFlowActive = false,
}) =>
    DriverFlowResolver(
      isCollectKeysAcked: acked.contains,
      isConfirmArrivalSuppressed: suppressed.contains,
      deferredRetrievalIds: () => deferred,
      currentParkSessionId: () => parkSessionId,
      isParkFlowActive: () => parkFlowActive,
    );

bool neverSuppressed(String _) => false;

void main() {
  const noAssignments = AssignedSessionsBackgroundInitial();

  group('next pending session', () {
    test('a re-park or checked-in car at the top wins', () {
      final pending = pendingList([
        pendingSession('park', 'CHECKED_IN'),
        pendingSession('ret', 'ARRIVED'),
      ]);
      expect(
        resolver().nextPendingSessionForDriverFlow(pending)!.sessionId,
        'park',
      );
    });

    test('otherwise the oldest accepted or arrived retrieval is next', () {
      final pending = pendingList([
        pendingSession('new', 'ARRIVED', assignedAt: '2026-01-01T10:05:00Z'),
        pendingSession('old', 'ACCEPTED', assignedAt: '2026-01-01T10:01:00Z'),
      ]);
      expect(
        resolver().nextPendingSessionForDriverFlow(pending)!.sessionId,
        'old',
      );
    });

    test('an empty list has no next session', () {
      expect(resolver().nextPendingSessionForDriverFlow(pendingList([])), null);
    });
  });

  group('next step from home', () {
    DriverFlowStep step(
      DriverFlowResolver r,
      PendingSessionsResponse? pending, {
      AssignedSessionsBackgroundState assigned = noAssignments,
      bool Function(String) incompleteSuppressed = neverSuppressed,
    }) =>
        r.resolveNextStep(
          pending: pending,
          nextPending: pending == null
              ? null
              : r.nextPendingSessionForDriverFlow(pending),
          assignedState: assigned,
          isSessionIncompleteSuppressed: incompleteSuppressed,
        );

    test('a re-parking car resumes the re-park', () {
      final result = step(
        resolver(),
        pendingList([pendingSession('s1', 'REPARKING')]),
      );
      expect(result, isA<DriverFlowRepark>());
    });

    test('a checked-in car asks to finish the session', () {
      final result = step(
        resolver(),
        pendingList([pendingSession('s1', 'CHECKED_IN')]),
      );
      expect(result, isA<DriverFlowSessionIncomplete>());
    });

    test('a checked-in car that is still syncing is left alone', () {
      final result = step(
        resolver(),
        pendingList([pendingSession('s1', 'CHECKED_IN')]),
        incompleteSuppressed: (id) => id == 's1',
      );
      expect(result, isA<DriverFlowHold>());
    });

    test('an arrived retrieval opens Confirm Arrival at handover', () {
      final result = step(
        resolver(),
        pendingList([pendingSession('s1', 'ARRIVED')]),
      );
      expect(result, isA<DriverFlowConfirmArrival>());
      result as DriverFlowConfirmArrival;
      expect(result.session.id, 's1');
      expect(result.isArrived, true);
    });

    test('an accepted retrieval opens Confirm Arrival before arrival', () {
      final result = step(
        resolver(),
        pendingList([pendingSession('s1', 'ACCEPTED')]),
      ) as DriverFlowConfirmArrival;
      expect(result.isArrived, false);
    });

    test('a retrieval in its post-handover cooldown is not reopened', () {
      final result = step(
        resolver(suppressed: {'s1'}),
        pendingList([pendingSession('s1', 'ARRIVED')]),
      );
      expect(result, isA<DriverFlowNone>());
    });

    test('a deferred retrieval waits while a park is in progress', () {
      final result = step(
        resolver(acked: {'s1'}, parkFlowActive: true),
        pendingList([pendingSession('s1', 'ACCEPTED')]),
      );
      expect(result, isA<DriverFlowNone>());
    });

    test('a deferred retrieval resumes once the park is done', () {
      final result = step(
        resolver(acked: {'s1'}),
        pendingList([pendingSession('s1', 'ACCEPTED')]),
      );
      expect(result, isA<DriverFlowConfirmArrival>());
    });

    test('with no pending list, a deferred arrived assignment is opened', () {
      final result = step(
        resolver(deferred: ['a', 'b']),
        null,
        assigned: AssignedSessionsBackgroundData([
          assignedSession('a', 'ACCEPTED'),
          assignedSession('b', 'ARRIVED'),
        ]),
      ) as DriverFlowConfirmArrival;
      // Arrived cars come before accepted ones.
      expect(result.session.id, 'b');
      expect(result.isArrived, true);
    });

    test('with nothing pending or deferred there is nothing to open', () {
      expect(step(resolver(), null), isA<DriverFlowNone>());
    });
  });

  group('retrieval sheet', () {
    RetrievalSheetDecision decide(
      DriverFlowResolver r, {
      required AssignedSessionsBackgroundState assigned,
      bool menuLoaded = true,
      PendingSessionsResponse? pending,
      bool homeIsCurrent = true,
    }) =>
        r.decideRetrievalSheet(
          assignedState: assigned,
          menuLoaded: menuLoaded,
          pending: pending,
          homeIsCurrent: homeIsCurrent,
        );

    final oneAssigned =
        AssignedSessionsBackgroundData([assignedSession('s1', 'ASSIGNED')]);

    test('a new assignment shows the sheet', () {
      expect(
        decide(resolver(), assigned: oneAssigned),
        RetrievalSheetDecision.show,
      );
    });

    test('no assignments, no sheet', () {
      expect(
        decide(resolver(), assigned: noAssignments),
        RetrievalSheetDecision.skip,
      );
    });

    test('an assignment already collected is not offered again', () {
      expect(
        decide(resolver(acked: {'s1'}), assigned: oneAssigned),
        RetrievalSheetDecision.skip,
      );
    });

    test('an assignment that is not in ASSIGNED status is not offered', () {
      expect(
        decide(
          resolver(),
          assigned: AssignedSessionsBackgroundData(
            [assignedSession('s1', 'ACCEPTED')],
          ),
        ),
        RetrievalSheetDecision.skip,
      );
    });

    test('waits for the driver menu to load', () {
      expect(
        decide(resolver(), assigned: oneAssigned, menuLoaded: false),
        RetrievalSheetDecision.waitForMenu,
      );
    });

    test('hidden while the same session is being re-parked', () {
      expect(
        decide(
          resolver(),
          assigned: oneAssigned,
          pending: pendingList([pendingSession('s1', 'REPARKING')]),
          homeIsCurrent: false,
        ),
        RetrievalSheetDecision.skip,
      );
    });

    test('another session being re-parked does not hide it', () {
      expect(
        decide(
          resolver(),
          assigned: oneAssigned,
          pending: pendingList([pendingSession('other', 'REPARKING')]),
          homeIsCurrent: false,
        ),
        RetrievalSheetDecision.show,
      );
    });

    test('hidden on home when the same session resumes directly', () {
      expect(
        decide(
          resolver(),
          assigned: oneAssigned,
          pending: pendingList([pendingSession('s1', 'ACCEPTED')]),
        ),
        RetrievalSheetDecision.skip,
      );
    });
  });

  group('adopting assignments from the pending list', () {
    test('an assigned retrieval in pending is adopted when the feed is empty',
        () {
      final adopted = resolver().assignedSessionsToAdoptFromPending(
        pendingList([
          pendingSession('s1', 'ASSIGNED', taskType: 'RETRIEVAL'),
          pendingSession('s2', 'CHECKED_IN', taskType: 'PARKING'),
        ]),
        noAssignments,
      );
      expect(adopted!.map((s) => s.id), ['s1']);
    });

    test('nothing is adopted when the feed already has an assignable one', () {
      final adopted = resolver().assignedSessionsToAdoptFromPending(
        pendingList([pendingSession('s1', 'ASSIGNED', taskType: 'RETRIEVAL')]),
        AssignedSessionsBackgroundData([assignedSession('s9', 'ASSIGNED')]),
      );
      expect(adopted, null);
    });
  });
}
