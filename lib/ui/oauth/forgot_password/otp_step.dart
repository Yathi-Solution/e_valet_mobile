import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/password_reset_otp/password_reset_otp_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/password_reset_otp/password_reset_otp_event.dart';
import 'package:niloufer_valet_mobile/api/oauth/otp_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/elevated_button.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/otp_input.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class OtpStep extends StatefulWidget {
  final String phoneNumber;
  final bool isVerifying;
  final TextEditingController otpController;
  final FocusNode otpFocusNode;
  final Size size;

  const OtpStep({
    super.key,
    required this.phoneNumber,
    required this.isVerifying,
    required this.otpController,
    required this.otpFocusNode,
    required this.size,
  });

  @override
  State<OtpStep> createState() => _OtpStepState();
}

class _OtpStepState extends State<OtpStep> {
  Timer? _timer;
  int _remainingSeconds = 30;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _remainingSeconds = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_remainingSeconds > 0) {
            _remainingSeconds--;
          } else {
            timer.cancel();
          }
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatTime(int seconds) {
    final secs = seconds % 60;
    return '0:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _handleResendOtp() async {
    if (_isResending || _remainingSeconds > 0) return;

    setState(() {
      _isResending = true;
    });

    try {
      // Use stored phone number (normalized) or fallback to prop
      final phoneNumber =
          await TokenStorage.getPhoneNumber() ?? widget.phoneNumber;
      await OtpApiService.requestPasswordResetOtp(phoneNumber);
      if (mounted) {
        SnackBars.showSuccessSnackBar(
          context,
          'OTP sent successfully.',
        );
        _startTimer(); // Restart timer after successful resend
      }
    } on ApiException catch (e) {
      if (mounted) {
        SnackBars.showErrorSnackBar(context, e.displayMessage);
      }
    } catch (_) {
      if (mounted) {
        final t = context.read<AppTranslationsNotifier>();
        SnackBars.showErrorSnackBar(
          context,
          t.get(TextConstants.genericError),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final canResend = _remainingSeconds == 0 && !_isResending;

    return Column(
      children: [
        TextComponent(
          labelText: t.get(TextConstants.otpSentTo(widget.phoneNumber)),
          fontSize: widget.size.width * 0.04,
          fontWeight: FontWeight.w400,
          color: AppColors.mutedText,
          textAlign: TextAlign.center,
        ),
        SizedBox(height: widget.size.height * 0.03),
        OtpInput(
          length: 6,
          controller: widget.otpController,
          focusNode: widget.otpFocusNode,
          autoFocus: true,
          onChanged: (value) {
            context
                .read<PasswordResetOtpBloc>()
                .add(PasswordResetOtpChanged(value));
          },
          onCompleted: (value) {
            final bloc = context.read<PasswordResetOtpBloc>();
            // Update the OTP in the bloc
            bloc.add(PasswordResetOtpChanged(value));
            // Automatically trigger verification if not already verifying
            if (!widget.isVerifying) {
              bloc.add(const PasswordResetOtpVerifySubmitted());
            }
          },
        ),
        SizedBox(height: widget.size.height * 0.02),
        // Timer or Resend OTP text
        if (canResend)
          GestureDetector(
            onTap: _handleResendOtp,
            child: TextComponent(
              labelText: _isResending
                  ? t.get(TextConstants.resendingOtp)
                  : t.get(TextConstants.resendOtp),
              fontSize: widget.size.width * 0.04,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              textAlign: TextAlign.center,
            ),
          )
        else
          TextComponent(
            labelText: _formatTime(_remainingSeconds),
            fontSize: widget.size.width * 0.04,
            fontWeight: FontWeight.w500,
            color: AppColors.mutedText,
            textAlign: TextAlign.center,
          ),
        SizedBox(height: widget.size.height * 0.03),
        SizedBox(
          width: double.infinity,
          child: Opacity(
            opacity: widget.isVerifying ? 0.5 : 1.0,
            child: ElevatedButtonComponent(
              labelText: widget.isVerifying
                  ? t.get(TextConstants.verifyingOtp)
                  : t.get(TextConstants.verifyOtp),
              onPressed: widget.isVerifying
                  ? () {}
                  : () {
                      context
                          .read<PasswordResetOtpBloc>()
                          .add(const PasswordResetOtpVerifySubmitted());
                    },
              elevatedButtonBackgroundColor: AppColors.primary,
              radius: 8,
              fontSize: 16,
              fontColor: AppColors.white,
              fontWeight: FontWeight.w600,
              padding:
                  EdgeInsets.symmetric(vertical: widget.size.height * 0.02),
              icon: Icon(
                Icons.verified_user_outlined,
                color: AppColors.white,
                size: widget.size.width * 0.05,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
