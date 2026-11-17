import 'package:equatable/equatable.dart';
import 'package:evalet/models/driver/session/pass_available_driver.dart';

abstract class PassAvailableDriversState extends Equatable {
  const PassAvailableDriversState();

  @override
  List<Object?> get props => [];
}

class PassAvailableDriversInitial extends PassAvailableDriversState {
  const PassAvailableDriversInitial();
}

class PassAvailableDriversLoading extends PassAvailableDriversState {
  const PassAvailableDriversLoading();
}

class PassAvailableDriversLoaded extends PassAvailableDriversState {
  final List<PassAvailableDriver> drivers;

  const PassAvailableDriversLoaded(this.drivers);

  @override
  List<Object?> get props => [drivers];
}

class PassAvailableDriversError extends PassAvailableDriversState {
  final String message;

  const PassAvailableDriversError(this.message);

  @override
  List<Object?> get props => [message];
}

/// A "pass" API call is in-flight.
class PassingSessionToDriver extends PassAvailableDriversState {
  final List<PassAvailableDriver> drivers;

  const PassingSessionToDriver({required this.drivers});

  @override
  List<Object?> get props => [drivers];
}

class SessionPassedToDriver extends PassAvailableDriversState {
  final String message;

  const SessionPassedToDriver(this.message);

  @override
  List<Object?> get props => [message];
}

class PassToDriverError extends PassAvailableDriversState {
  final String message;
  final List<PassAvailableDriver> drivers;

  const PassToDriverError({required this.message, required this.drivers});

  @override
  List<Object?> get props => [message, drivers];
}
