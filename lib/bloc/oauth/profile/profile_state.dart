import 'package:equatable/equatable.dart';
import 'package:evalet/models/oauth/profile_response.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final ProfileResponse profile;

  /// Outlet name (or id fallback) from [TokenStorage] after login selection.
  final String? loggedInOutletDisplay;

  const ProfileLoaded(
    this.profile, {
    this.loggedInOutletDisplay,
  });

  @override
  List<Object?> get props => [profile, loggedInOutletDisplay];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError(this.message);

  @override
  List<Object?> get props => [message];
}
