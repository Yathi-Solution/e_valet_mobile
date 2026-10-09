import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/forgot_password/forgot_password_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/forgot_password/forgot_password_event.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/forgot_password/forgot_password_state.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/elevated_button.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/footer.dart';
import 'package:niloufer_valet_mobile/ui/common/phone_Number/phone_number_field.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/oauth/forgot_password/password_reset_otp_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  void _handleSubmit(BuildContext context) {
    final bloc = context.read<ForgotPasswordBloc>();
    // Ensure the latest value in the controller is synced to the bloc
    bloc.add(ForgotPasswordPhoneChanged(_phoneController.text));
    bloc.add(const ForgotPasswordSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return BlocProvider(
      create: (context) => ForgotPasswordBloc(),
      child: BlocListener<ForgotPasswordBloc, ForgotPasswordState>(
        listener: (context, state) {
          if (state is ForgotPasswordSuccess) {
            SnackBars.showSuccessSnackBar(context, state.message);
            Future.delayed(const Duration(milliseconds: 300), () {
              if (!mounted) return;
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => PasswordResetOtpScreen(
                    phoneNumber: state.phoneNumber,
                  ),
                ),
              );
            });
          } else if (state is ForgotPasswordFailure) {
            SnackBars.showErrorSnackBar(context, state.message);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.primarySurface,
            appBar: const CustomAppBar(hideParkedCarsAction: true),
            body: SafeArea(
              child: Column(
                children: [
                  // Main content
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // White card with blue border
                            Container(
                              width: double.infinity,
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 1,
                              ),
                              padding: EdgeInsets.all(
                                MediaQuery.of(context).size.width * 0.05,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.cardBackground,
                                borderRadius: BorderRadius.circular(
                                  MediaQuery.of(context).size.width * 0.05,
                                ),
                                border: Border.all(
                                  color: AppColors.primary, // Blue border
                                  width: 2,
                                ),
                              ),
                              child: Column(
                                children: [
                                  // Lock icon
                                  Icon(
                                    Icons.lock_outline,
                                    color: AppColors.black,
                                    size:
                                        MediaQuery.of(context).size.width * 0.2,
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.02,
                                  ),
                                  // "Forgot Password" text
                                  TextComponent(
                                    labelText: t.getByKey('forgotPasswordTitle',
                                        TextConstants.forgotPasswordTitle),
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.06,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.black,
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.01,
                                  ),
                                  // Description text
                                  TextComponent(
                                    labelText: t.getByKey(
                                        'forgotPasswordDescription',
                                        TextConstants
                                            .forgotPasswordDescription),
                                    fontSize:
                                        MediaQuery.of(context).size.width *
                                            0.04,
                                    fontWeight: FontWeight.w400,
                                    color: AppColors.mutedText,
                                    textAlign: TextAlign.center,
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.03,
                                  ),
                                  // Phone number field
                                  BlocBuilder<ForgotPasswordBloc,
                                      ForgotPasswordState>(
                                    builder: (context, state) {
                                      return PhoneNumberField(
                                        labelText: t.getByKey(
                                            'phoneNumberLabel',
                                            TextConstants.phoneNumberLabel),
                                        hintText: t.getByKey('phoneNumberHint',
                                            TextConstants.phoneNumberHint),
                                        controller: _phoneController,
                                        focusNode: _phoneFocusNode,
                                        initialCountryCode: 'IN',
                                        disableCountryPicker: true,
                                        textInputAction: TextInputAction.done,
                                        onSubmitted: (_) =>
                                            _handleSubmit(context),
                                        onChanged: (value) => context
                                            .read<ForgotPasswordBloc>()
                                            .add(ForgotPasswordPhoneChanged(
                                                value)),
                                      );
                                    },
                                  ),
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height *
                                        0.03,
                                  ),
                                  // Submit button
                                  ValueListenableBuilder<TextEditingValue>(
                                    valueListenable: _phoneController,
                                    builder: (context, phoneValue, _) {
                                      return BlocBuilder<ForgotPasswordBloc,
                                          ForgotPasswordState>(
                                        builder: (context, state) {
                                          final isLoading =
                                              state is ForgotPasswordLoading;
                                          // Check if phone number is valid (10 digits required)
                                          final phoneText =
                                              phoneValue.text.trim();
                                          final isValidPhone =
                                              phoneText.length == 10;
                                          final isButtonEnabled =
                                              !isLoading && isValidPhone;

                                          void handlePress() {
                                            if (isButtonEnabled) {
                                              _handleSubmit(context);
                                            }
                                          }

                                          return SizedBox(
                                            width: double.infinity,
                                            child: Opacity(
                                              opacity:
                                                  isButtonEnabled ? 1.0 : 0.5,
                                              child: ElevatedButtonComponent(
                                                labelText: isLoading
                                                    ? t.getByKey(
                                                        'sendResetInstructionsLoading',
                                                        TextConstants
                                                            .sendResetInstructionsLoading)
                                                    : t.getByKey(
                                                        'sendResetInstructions',
                                                        TextConstants
                                                            .sendResetInstructions),
                                                onPressed: handlePress,
                                                elevatedButtonBackgroundColor:
                                                    AppColors.primary,
                                                radius: 8,
                                                fontSize: 16,
                                                fontColor: AppColors.white,
                                                fontWeight: FontWeight.w600,
                                                padding: EdgeInsets.symmetric(
                                                  vertical:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .height *
                                                          0.02,
                                                ),
                                                icon: isLoading
                                                    ? SizedBox(
                                                        width: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.05,
                                                        height: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .height *
                                                            0.02,
                                                        child:
                                                            const CircularProgressIndicator(
                                                          strokeWidth: 2,
                                                          valueColor:
                                                              AlwaysStoppedAnimation<
                                                                  Color>(
                                                            AppColors.white,
                                                          ),
                                                        ),
                                                      )
                                                    : Icon(
                                                        Icons.send,
                                                        color: AppColors.white,
                                                        size: MediaQuery.of(
                                                                    context)
                                                                .size
                                                                .width *
                                                            0.05,
                                                      ),
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Footer
                  const Footer(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
