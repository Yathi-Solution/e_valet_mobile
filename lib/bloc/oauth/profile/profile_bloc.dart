import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/oauth/profile_api_service.dart';
import 'package:evalet/bloc/oauth/profile/profile_event.dart';
import 'package:evalet/bloc/oauth/profile/profile_state.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc() : super(const ProfileInitial()) {
    on<ProfileStarted>(_onStarted);
  }

  Future<void> _onStarted(
    ProfileStarted event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileLoading());

    try {
      final profile = await ProfileApiService.getProfile();
      final outletName = await TokenStorage.getSelectedOutletName();
      final outletId = await TokenStorage.getSelectedOutletId();
      final String? loggedInOutletDisplay;
      if (outletName != null && outletName.trim().isNotEmpty) {
        loggedInOutletDisplay = outletName.trim();
      } else if (outletId != null) {
        loggedInOutletDisplay = '#$outletId';
      } else {
        loggedInOutletDisplay = null;
      }
      emit(ProfileLoaded(
        profile,
        loggedInOutletDisplay: loggedInOutletDisplay,
      ));
    } on ApiException catch (e) {
      emit(ProfileError(e.message));
    } catch (_) {
      emit(const ProfileError('Failed to load profile'));
    }
  }
}
