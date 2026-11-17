import 'package:equatable/equatable.dart';
import 'package:evalet/models/driver/pre_break/pre_break_info_response.dart';
import 'package:evalet/models/driver/status/driver_status.dart';

abstract class DriverStatusState extends Equatable {
  const DriverStatusState();

  @override
  List<Object?> get props => [];
}

class DriverStatusInitial extends DriverStatusState {
  const DriverStatusInitial();
}

class DriverStatusLoading extends DriverStatusState {
  const DriverStatusLoading();
}

class DriverStatusLoaded extends DriverStatusState {
  final DriverStatus status;

  const DriverStatusLoaded(this.status);

  @override
  List<Object?> get props => [status];
}

class DriverStatusError extends DriverStatusState {
  final String message;

  const DriverStatusError(this.message);

  @override
  List<Object?> get props => [message];
}

class DriverBreakToggleLoading extends DriverStatusState {
  final DriverStatus? previousStatus;
  final bool requestedOnBreakState;

  const DriverBreakToggleLoading({
    this.previousStatus,
    required this.requestedOnBreakState,
  });

  @override
  List<Object?> get props => [previousStatus, requestedOnBreakState];
}

class DriverBreakBlockedByPendingWork extends DriverStatusState {
  final DriverStatus? previousStatus;
  final PreBreakInfoResponse preBreakInfo;

  const DriverBreakBlockedByPendingWork({
    required this.preBreakInfo,
    this.previousStatus,
  });

  @override
  List<Object?> get props => [previousStatus, preBreakInfo];
}

class DriverBreakStartSuccess extends DriverStatusState {
  final DriverStatus status;
  final String message;

  const DriverBreakStartSuccess({
    required this.status,
    required this.message,
  });

  @override
  List<Object?> get props => [status, message];
}

class DriverBreakEndSuccess extends DriverStatusState {
  final DriverStatus status;
  final String message;

  const DriverBreakEndSuccess({
    required this.status,
    required this.message,
  });

  @override
  List<Object?> get props => [status, message];
}
