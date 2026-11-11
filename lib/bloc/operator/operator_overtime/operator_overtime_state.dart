import 'package:equatable/equatable.dart';
import 'package:evalet/models/operator/operator_valet/valet_response.dart';

abstract class OperatorOvertimeState extends Equatable {
  const OperatorOvertimeState();

  @override
  List<Object?> get props => [];
}

class OperatorOvertimeInitial extends OperatorOvertimeState {}

class OperatorOvertimeLoading extends OperatorOvertimeState {}

class OperatorOvertimeLoadError extends OperatorOvertimeState {
  final String message;

  const OperatorOvertimeLoadError({required this.message});

  @override
  List<Object?> get props => [message];
}

class OperatorOvertimeLoaded extends OperatorOvertimeState {
  final List<ValetResponse> valets;

  const OperatorOvertimeLoaded({required this.valets});

  @override
  List<Object?> get props => [valets];
}

/// Emitted after a successful grant; listener should show success and clear input for [driverUserId].
class OperatorOvertimeGrantSuccess extends OperatorOvertimeState {
  final List<ValetResponse> valets;
  final String driverUserId;
  final String message;

  const OperatorOvertimeGrantSuccess({
    required this.valets,
    required this.driverUserId,
    required this.message,
  });

  @override
  List<Object?> get props => [valets, driverUserId, message];
}

/// Emitted when grant API fails; listener should show error snackbar.
class OperatorOvertimeGrantError extends OperatorOvertimeState {
  final List<ValetResponse> valets;
  final String message;

  const OperatorOvertimeGrantError({
    required this.valets,
    required this.message,
  });

  @override
  List<Object?> get props => [valets, message];
}
