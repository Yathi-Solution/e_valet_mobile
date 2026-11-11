import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/oauth/otp_api_service.dart';
import 'package:evalet/bloc/oauth/forgot_password/forgot_password_event.dart';
import 'package:evalet/bloc/oauth/forgot_password/forgot_password_state.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class ForgotPasswordBloc
    extends Bloc<ForgotPasswordEvent, ForgotPasswordState> {
  ForgotPasswordBloc() : super(const ForgotPasswordInitial()) {
    on<ForgotPasswordPhoneChanged>(_onPhoneChanged);
    on<ForgotPasswordSubmitted>(_onSubmitted);
    on<ForgotPasswordReset>(_onReset);
  }

  String _phoneNumber = '';

  String _normalizePhone(String value) {
    // Remove spaces and dashes
    final cleaned = value.replaceAll(RegExp(r'\s+|-'), '');
    if (cleaned.startsWith('+')) {
      return cleaned;
    }
    // Default to India country code if not provided
    return '+91$cleaned';
  }

  void _onPhoneChanged(
    ForgotPasswordPhoneChanged event,
    Emitter<ForgotPasswordState> emit,
  ) {
    _phoneNumber = _normalizePhone(event.phoneNumber.trim());
  }

  Future<void> _onSubmitted(
    ForgotPasswordSubmitted event,
    Emitter<ForgotPasswordState> emit,
  ) async {
    emit(const ForgotPasswordLoading());

    // Validate phone number
    if (_phoneNumber.isEmpty) {
      emit(const ForgotPasswordFailure('Please enter your phone number'));
      return;
    }

    try {
      final message = await OtpApiService.requestPasswordResetOtp(_phoneNumber);

      await TokenStorage.savePhoneNumber(_phoneNumber);

      emit(ForgotPasswordSuccess(
        message,
        _phoneNumber,
      ));
    } on ApiException catch (e) {
      emit(ForgotPasswordFailure(e.message));
    } catch (_) {
      emit(const ForgotPasswordFailure(
        'Something went wrong. Please try again.',
      ));
    }
  }

  void _onReset(
    ForgotPasswordReset event,
    Emitter<ForgotPasswordState> emit,
  ) {
    _phoneNumber = '';
    emit(const ForgotPasswordInitial());
  }
}
