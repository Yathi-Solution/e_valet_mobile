import 'package:equatable/equatable.dart';
import 'package:evalet/models/oauth/profile.dart';

abstract class OutletLocationRetryState extends Equatable {
  final String displayMessage;

  const OutletLocationRetryState(this.displayMessage);

  bool get isBusy => false;

  @override
  List<Object?> get props => [displayMessage];
}

class OutletLocationRetryIdle extends OutletLocationRetryState {
  const OutletLocationRetryIdle(super.displayMessage);
}

class OutletLocationRetryBusy extends OutletLocationRetryState {
  const OutletLocationRetryBusy(super.displayMessage);

  @override
  bool get isBusy => true;

  @override
  List<Object?> get props => [displayMessage, isBusy];
}

class OutletLocationRetrySuccess extends OutletLocationRetryState {
  final Profile profile;

  const OutletLocationRetrySuccess(
    super.displayMessage, {
    required this.profile,
  });

  @override
  List<Object?> get props => [displayMessage, profile];
}

/// Shown transiently so the listener can show a snackbar and resume idle UI.
class OutletLocationRetryTransientFailure extends OutletLocationRetryState {
  final String notification;
  final String resumeDisplayMessage;

  const OutletLocationRetryTransientFailure({
    required this.notification,
    required this.resumeDisplayMessage,
  }) : super(resumeDisplayMessage);

  @override
  List<Object?> get props => [notification, resumeDisplayMessage];
}
