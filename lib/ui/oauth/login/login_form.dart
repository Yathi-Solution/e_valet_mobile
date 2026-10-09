import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/login/login_bloc.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/login/login_event.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/login/login_state.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/password_text_field.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/elevated_button.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text_button.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/phone_Number/phone_number_field.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/oauth/forgot_password/forgot_password_screen.dart';
import 'dart:math' as math;

class LoginForm extends StatelessWidget {
  final TextEditingController loginIdController;
  final TextEditingController pinController;
  final FocusNode loginIdFocusNode;
  final FocusNode pinFocusNode;

  const LoginForm({
    super.key,
    required this.loginIdController,
    required this.pinController,
    required this.loginIdFocusNode,
    required this.pinFocusNode,
  });

  void _handleLogin(BuildContext context) {
    context.read<LoginBloc>().add(const LoginSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final t = context.watch<AppTranslationsNotifier>();
        final maxCardWidth = math.min(constraints.maxWidth * 0.9, 600.0);
        final iconSize = math.min(maxCardWidth * 0.2, 120.0);
        final titleFontSize = math.min(maxCardWidth * 0.06, 28.0);
        final borderRadius = math.min(maxCardWidth * 0.05, 20.0);
        const verticalSpacing = 16.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(maxWidth: maxCardWidth),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: AppColors.accent,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: AppColors.black,
                    size: iconSize,
                  ),
                  const SizedBox(height: verticalSpacing),
                  TextComponent(
                    labelText:
                        t.getByKey('loginPrompt', TextConstants.loginPrompt),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: verticalSpacing),
                  PhoneNumberField(
                    labelText: t.getByKey(
                        'phoneNumberLabel', TextConstants.phoneNumberLabel),
                    hintText: t.getByKey(
                        'phoneNumberHint', TextConstants.phoneNumberHint),
                    controller: loginIdController,
                    focusNode: loginIdFocusNode,
                    textInputAction: TextInputAction.next,
                    initialCountryCode: 'IN',
                    disableCountryPicker: true,
                    onSubmitted: (_) {
                      FocusScope.of(context).requestFocus(pinFocusNode);
                    },
                    onComplete: () {
                      FocusScope.of(context).requestFocus(pinFocusNode);
                    },
                    onChanged: (value) =>
                        context.read<LoginBloc>().add(LoginIdChanged(value)),
                  ),
                  const SizedBox(height: verticalSpacing),
                  PasswordTextField(
                    controller: pinController,
                    focusNode: pinFocusNode,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(context),
                    labelText: t.getByKey(
                        'passwordLabel', TextConstants.passwordLabel),
                    hintText:
                        t.getByKey('passwordHint', TextConstants.passwordHint),
                    onChanged: (value) =>
                        context.read<LoginBloc>().add(PinChanged(value)),
                  ),
                  const SizedBox(height: verticalSpacing),
                  BlocBuilder<LoginBloc, LoginState>(
                    builder: (context, state) {
                      final isLoading = state is LoginLoading;
                      void handlePress() {
                        if (!isLoading) {
                          _handleLogin(context);
                        }
                      }

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButtonComponent(
                          labelText: isLoading
                              ? t.getByKey('loginButtonLoading',
                                  TextConstants.loginButtonLoading)
                              : t.getByKey(
                                  'loginButton', TextConstants.loginButton),
                          onPressed: handlePress,
                          elevatedButtonBackgroundColor: AppColors.primary,
                          radius: 8,
                          fontSize: 16,
                          fontColor: AppColors.white,
                          fontWeight: FontWeight.w600,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          icon: isLoading
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.white,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward,
                                  color: AppColors.white,
                                  size: 24,
                                ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: verticalSpacing),
                  Row(
                    children: [
                      const Spacer(),
                      TextButtonComponent(
                        labelText: t.getByKey(
                            'forgotPassword', TextConstants.forgotPassword),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        fontSize: 14,
                        fontColor: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
