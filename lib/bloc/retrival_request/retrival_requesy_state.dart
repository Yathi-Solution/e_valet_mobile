import 'package:equatable/equatable.dart';
import 'package:evalet/models/driver/session/assigned_session.dart';

abstract class RetrivalRequestState extends Equatable {
  const RetrivalRequestState();

  @override
  List<Object?> get props => [];
}

class RetrivalRequestInitial extends RetrivalRequestState {
  const RetrivalRequestInitial();
}

class RetrivalRequestLoading extends RetrivalRequestState {
  const RetrivalRequestLoading();
}

class RetrivalRequestLoaded extends RetrivalRequestState {
  final List<AssignedSession> sessions;

  const RetrivalRequestLoaded(this.sessions);

  @override
  List<Object?> get props => [sessions];
}

class RetrivalRequestError extends RetrivalRequestState {
  final String message;

  const RetrivalRequestError(this.message);

  @override
  List<Object?> get props => [message];
}

class RetrivalRequestAccepted extends RetrivalRequestState {
  final String message;

  /// Session ids successfully accepted (single-accept or bulk). Used for in-transit Hive.
  final List<String> acceptedIds;

  const RetrivalRequestAccepted(
    this.message, {
    this.acceptedIds = const [],
  });

  @override
  List<Object?> get props => [message, acceptedIds];
}
