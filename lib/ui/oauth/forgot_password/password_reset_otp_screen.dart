import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/password_reset_otp/password_reset_otp_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/password_reset_otp/password_reset_otp_event.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/password_reset_otp/password_reset_otp_state.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/footer.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/oauth/forgot_password/password_reset_otp_widgets.dart';

class PasswordResetOtpScreen extends StatefulWidget {
  final String phoneNumber;

  const PasswordResetOtpScreen({
    super.key,
    required this.phoneNumber,
  });

  @override
  State<PasswordResetOtpScreen> createState() => _PasswordResetOtpScreenState();
}

class _PasswordResetOtpScreenState extends State<PasswordResetOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  final TextEditingController _newPasswordController = TextEditingController();

  bool _obscureNewPassword = true;
  PasswordResetOtpState? _previousState;

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PasswordResetOtpBloc()
        ..add(PasswordResetOtpInitialized(widget.phoneNumber)),
      child: BlocListener<PasswordResetOtpBloc, PasswordResetOtpState>(
        listener: (context, state) {
          // Only show snackbar when transitioning TO verified state (not when already verified)
          if (state is PasswordResetOtpVerified) {
            // Check if we're transitioning from a non-verified state to verified
            final wasNotVerified = _previousState == null ||
                (_previousState is! PasswordResetOtpVerified &&
                    _previousState is! PasswordResetOtpVerifiedWithError);

            if (wasNotVerified) {
              SnackBars.showSuccessSnackBar(context, state.message);
            }
          } else if (state is PasswordResetOtpResetSuccess) {
            SnackBars.showSuccessSnackBar(context, state.message);
            Navigator.of(context).popUntil((route) => route.isFirst);
          } else if (state is PasswordResetOtpFailure) {
            // Only show snackbar for failures that are NOT during password reset
            // (e.g., OTP verification failures)
            SnackBars.showErrorSnackBar(context, state.message);
          }
          // PasswordResetOtpVerifiedWithError is handled in the UI, not here

          // Update previous state
          _previousState = state;
        },
        child: Scaffold(
          backgroundColor: AppColors.primarySurface,
          appBar: const CustomAppBar(hideParkedCarsAction: true),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: BlocBuilder<PasswordResetOtpBloc,
                          PasswordResetOtpState>(
                        builder: (context, state) {
                          final storedPhone = state is PasswordResetOtpInitial
                              ? state.storedPhone
                              : null;
                          final phoneNumber = storedPhone ?? widget.phoneNumber;
                          // OTP is verified if we're in verified state, resetting state, or verified with error
                          // This ensures we stay on new password step during reset
                          final isOtpVerified =
                              state is PasswordResetOtpVerified ||
                                  state is PasswordResetOtpVerifiedWithError ||
                                  state is PasswordResetOtpResetting;
                          final isVerifying =
                              state is PasswordResetOtpVerifying;
                          final isResetting =
                              state is PasswordResetOtpResetting;
                          final errorMessage =
                              state is PasswordResetOtpVerifiedWithError
                                  ? state.errorMessage
                                  : null;

                          return PasswordResetOtpCard(
                            isOtpVerified: isOtpVerified,
                            phoneNumber: phoneNumber,
                            isVerifying: isVerifying,
                            isResetting: isResetting,
                            otpController: _otpController,
                            otpFocusNode: _otpFocusNode,
                            newPasswordController: _newPasswordController,
                            obscureNewPassword: _obscureNewPassword,
                            onToggleObscure: () {
                              setState(() {
                                _obscureNewPassword = !_obscureNewPassword;
                              });
                            },
                            errorMessage: errorMessage,
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const Footer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
