import 'package:equatable/equatable.dart';
import 'package:evalet/models/oauth/logout_response.dart';

abstract class ScannerMenuState extends Equatable {
  const ScannerMenuState();

  @override
  List<Object?> get props => [];
}

class ScannerMenuInitial extends ScannerMenuState {
  const ScannerMenuInitial();
}

enum ScannerMenuActionType { profile }

class ScannerMenuAction extends ScannerMenuState {
  final ScannerMenuActionType action;

  const ScannerMenuAction(this.action);

  @override
  List<Object?> get props => [action];
}

class ScannerMenuLogoutLoading extends ScannerMenuState {
  const ScannerMenuLogoutLoading();
}

class ScannerMenuLogoutSuccess extends ScannerMenuState {
  final LogoutResponse response;

  const ScannerMenuLogoutSuccess(this.response);

  @override
  List<Object?> get props => [response];
}

class ScannerMenuLogoutFailure extends ScannerMenuState {
  final String message;

  const ScannerMenuLogoutFailure(this.message);

  @override
  List<Object?> get props => [message];
}
