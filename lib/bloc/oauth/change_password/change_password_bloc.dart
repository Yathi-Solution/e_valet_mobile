import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/oauth/password_api_service.dart';
import 'package:evalet/bloc/oauth/change_password/change_password_event.dart';
import 'package:evalet/bloc/oauth/change_password/change_password_state.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/oauth/change_password_request.dart';
import 'package:evalet/ui/common/text_constants.dart';

class ChangePasswordBloc
    extends Bloc<ChangePasswordEvent, ChangePasswordState> {
  ChangePasswordBloc() : super(const ChangePasswordState()) {
    on<ChangePasswordSubmitted>(_onSubmitted);
  }

  Future<void> _onSubmitted(
    ChangePasswordSubmitted event,
    Emitter<ChangePasswordState> emit,
  ) async {
    // Don't trim here - we need to check for spaces first
    // We'll validate and then trim when submitting to API
    final oldPassword = event.oldPassword;
    final newPassword = event.newPassword;
    final confirmPassword = event.confirmPassword;

    // Validation: All fields required
    if (oldPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'All fields are required.',
        ),
      );
      return;
    }

    // Validation: Password cannot contain spaces
    if (newPassword.contains(' ')) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: TextConstants.validationPasswordNoSpaces,
        ),
      );
      return;
    }

    // Validation: Password minimum length
    const minPasswordLength = 6;
    if (oldPassword.length < minPasswordLength) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage:
              'Current password must be at least $minPasswordLength characters.',
        ),
      );
      return;
    }

    if (newPassword.length < minPasswordLength) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage:
              'New password must be at least $minPasswordLength characters.',
        ),
      );
      return;
    }

    // Validation: New password and confirm password must match
    if (newPassword != confirmPassword) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'New password and confirm password must match.',
        ),
      );
      return;
    }

    emit(
      state.copyWith(
        isLoading: true,
        isSuccess: false,
        errorMessage: null,
      ),
    );

    try {
      // Trim passwords before sending to API (validation already checked for spaces)
      final request = ChangePasswordRequest(
        oldPassword: oldPassword.trim(),
        newPassword: newPassword.trim(),
      );
      await PasswordApiService.changePassword(request);

      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: true,
          errorMessage: null,
        ),
      );
    } on ApiException catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          isSuccess: false,
          errorMessage: 'Failed to change password. Please try again.',
        ),
      );
    }
  }
}
