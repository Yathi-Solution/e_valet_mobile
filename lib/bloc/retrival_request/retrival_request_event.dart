import 'package:equatable/equatable.dart';
import 'package:evalet/models/driver/session/assigned_session.dart';

abstract class RetrivalRequestEvent extends Equatable {
  const RetrivalRequestEvent();

  @override
  List<Object?> get props => [];
}

class FetchRetrivalRequests extends RetrivalRequestEvent {
  const FetchRetrivalRequests();
}

class AcceptRetrivalRequest extends RetrivalRequestEvent {
  final String sessionId;

  /// Optional; used for logging / future use. Accept API is always attempted.
  final AssignedSession? assignedSession;

  const AcceptRetrivalRequest(this.sessionId, {this.assignedSession});

  @override
  List<Object?> get props => [sessionId, assignedSession];
}

/// Multiple assignments: call POST accept for every session id (FIFO order).
class AcceptAllRetrivalRequests extends RetrivalRequestEvent {
  final List<String> sessionIds;

  const AcceptAllRetrivalRequests(this.sessionIds);

  @override
  List<Object?> get props => [sessionIds];
}

class UpdateAssignedSessions extends RetrivalRequestEvent {
  final List<AssignedSession> sessions;

  const UpdateAssignedSessions(this.sessions);

  @override
  List<Object?> get props => [sessions];
}
