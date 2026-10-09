import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/oauth/forgot_password/new_password_step.dart';
import 'package:niloufer_valet_mobile/ui/oauth/forgot_password/otp_step.dart';

/// Card wrapper that decides which step to show.
class PasswordResetOtpCard extends StatelessWidget {
  final bool isOtpVerified;
  final String phoneNumber;
  final bool isVerifying;
  final bool isResetting;
  final TextEditingController otpController;
  final FocusNode otpFocusNode;
  final TextEditingController newPasswordController;
  final bool obscureNewPassword;
  final VoidCallback onToggleObscure;
  final String? errorMessage;

  const PasswordResetOtpCard({
    super.key,
    required this.isOtpVerified,
    required this.phoneNumber,
    required this.isVerifying,
    required this.isResetting,
    required this.otpController,
    required this.otpFocusNode,
    required this.newPasswordController,
    required this.obscureNewPassword,
    required this.onToggleObscure,
    this.errorMessage,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final size = MediaQuery.of(context).size;

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(maxWidth: size.width * 1),
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(size.width * 0.05),
        border: Border.all(
          color: AppColors.primary,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mark_email_unread_outlined,
            color: AppColors.black,
            size: size.width * 0.2,
          ),
          SizedBox(height: size.height * 0.02),
          TextComponent(
            labelText: isOtpVerified
                ? t.get(TextConstants.enterNewPasswordTitle)
                : t.get(TextConstants.enterOtpTitle),
            fontSize: size.width * 0.06,
            fontWeight: FontWeight.w600,
            color: AppColors.black,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: size.height * 0.01),
          if (!isOtpVerified)
            OtpStep(
              phoneNumber: phoneNumber,
              isVerifying: isVerifying,
              otpController: otpController,
              otpFocusNode: otpFocusNode,
              size: size,
            )
          else
            NewPasswordStep(
              isResetting: isResetting,
              newPasswordController: newPasswordController,
              obscureNewPassword: obscureNewPassword,
              onToggleObscure: onToggleObscure,
              size: size,
            ),
        ],
      ),
    );
  }
}
