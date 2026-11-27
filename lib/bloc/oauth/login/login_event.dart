import 'package:equatable/equatable.dart';
import 'package:evalet/models/outlet/outlet.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object?> get props => [];
}

class LoginIdChanged extends LoginEvent {
  final String loginId;

  const LoginIdChanged(this.loginId);

  @override
  List<Object?> get props => [loginId];
}

class PinChanged extends LoginEvent {
  final String pin;

  const PinChanged(this.pin);

  @override
  List<Object?> get props => [pin];
}

class LoginSubmitted extends LoginEvent {
  const LoginSubmitted();
}

/// Phone screen submit. Requests a Login Code with no channel (WhatsApp).
class RequestLoginCode extends LoginEvent {
  const RequestLoginCode();
}

/// Code screen submit. [code] is the 6 digits, kept as a string.
class VerifyLoginCode extends LoginEvent {
  final String code;

  const VerifyLoginCode(this.code);

  @override
  List<Object?> get props => [code];
}

/// Resend. [channel] is null for WhatsApp, or `SMS`.
class ResendLoginCode extends LoginEvent {
  final String? channel;

  const ResendLoginCode({this.channel});

  @override
  List<Object?> get props => [channel];
}

/// Back to the phone screen. Does not call the API.
class ChangeLoginPhone extends LoginEvent {
  const ChangeLoginPhone();
}

/// Fired when the user picks an outlet from the outlet selection dialog.
class OutletSelected extends LoginEvent {
  final Outlet outlet;

  const OutletSelected(this.outlet);

  @override
  List<Object?> get props => [outlet];
}

/// Fired when the user picks a Client (Platform token, or 2+ Clients).
class ClientSelected extends LoginEvent {
  final String clientId;

  const ClientSelected(this.clientId);

  @override
  List<Object?> get props => [clientId];
}

class LoginReset extends LoginEvent {
  const LoginReset();
}
