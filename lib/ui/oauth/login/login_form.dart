import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/bloc/oauth/login/login_bloc.dart';
import 'package:evalet/bloc/oauth/login/login_event.dart';
import 'package:evalet/bloc/oauth/login/login_state.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/phone_Number/phone_number_field.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/elevated_button.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/common/widgets/text_button.dart';

class LoginForm extends StatefulWidget {
  final TextEditingController loginIdController;
  final FocusNode loginIdFocusNode;

  const LoginForm({
    super.key,
    required this.loginIdController,
    required this.loginIdFocusNode,
  });

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController _codeController = TextEditingController();
  Timer? _resendTimer;
  int _resendSeconds = 0;
  bool _rateLimited = false;
  Timer? _rateLimitTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _rateLimitTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendTimer?.cancel();
    setState(() => _resendSeconds = 30);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds -= 1);
      }
    });
  }

  void _holdForRateLimit() {
    _rateLimitTimer?.cancel();
    setState(() => _rateLimited = true);
    _rateLimitTimer = Timer(const Duration(minutes: 2), () {
      if (mounted) setState(() => _rateLimited = false);
    });
  }

  bool _onCodeScreen(LoginState state) {
    if (state is LoginCodeSent || state is LoginCodeVerifying) return true;
    if (state is LoginFailure && state.phone != null) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginCodeSent) {
          _codeController.clear();
          _startResendCountdown();
        } else if (state is LoginFailure) {
          if (state.clearCode) _codeController.clear();
          if (state.rateLimited) _holdForRateLimit();
        }
      },
      child: BlocBuilder<LoginBloc, LoginState>(
        builder: (context, state) {
          if (_onCodeScreen(state)) {
            final phone = state is LoginCodeSent
                ? state.phone
                : state is LoginCodeVerifying
                    ? state.phone
                    : (state as LoginFailure).phone!;
            return _codeCard(
              context,
              phone: phone,
              verifying: state is LoginCodeVerifying,
            );
          }
          return _phoneCard(
            context,
            loading: state is LoginLoading,
          );
        },
      ),
    );
  }

  Widget _phoneCard(BuildContext context, {required bool loading}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final t = context.watch<AppTranslationsNotifier>();
        final maxCardWidth = math.min(constraints.maxWidth * 0.9, 600.0);
        final iconSize = math.min(maxCardWidth * 0.2, 120.0);
        final titleFontSize = math.min(maxCardWidth * 0.06, 28.0);
        final borderRadius = math.min(maxCardWidth * 0.05, 20.0);

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
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.person_outline,
                      color: AppColors.black, size: iconSize),
                  const SizedBox(height: 16),
                  TextComponent(
                    labelText:
                        t.getByKey('loginPrompt', TextConstants.loginPrompt),
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.black,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextComponent(
                    labelText:
                        'We will send a 6-digit code on WhatsApp.',
                    fontSize: 14,
                    color: AppColors.black,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  PhoneNumberField(
                    labelText: t.getByKey(
                        'phoneNumberLabel', TextConstants.phoneNumberLabel),
                    hintText: t.getByKey(
                        'phoneNumberHint', TextConstants.phoneNumberHint),
                    controller: widget.loginIdController,
                    focusNode: widget.loginIdFocusNode,
                    textInputAction: TextInputAction.done,
                    initialCountryCode: 'IN',
                    disableCountryPicker: true,
                    onSubmitted: (_) => _submitPhone(context),
                    onComplete: () {},
                    onChanged: (value) =>
                        context.read<LoginBloc>().add(LoginIdChanged(value)),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButtonComponent(
                      labelText: loading ? 'Sending code…' : 'Send code',
                      onPressed: () {
                        if (!loading && !_rateLimited) _submitPhone(context);
                      },
                      elevatedButtonBackgroundColor: AppColors.primary,
                      radius: 8,
                      fontSize: 16,
                      fontColor: AppColors.white,
                      fontWeight: FontWeight.w600,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _submitPhone(BuildContext context) {
    context.read<LoginBloc>().add(const RequestLoginCode());
  }

  Widget _codeCard(
    BuildContext context, {
    required String phone,
    required bool verifying,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxCardWidth = math.min(constraints.maxWidth * 0.9, 600.0);
        final borderRadius = math.min(maxCardWidth * 0.05, 20.0);
        final canResend = _resendSeconds == 0 && !verifying && !_rateLimited;

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
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Column(
                children: [
                  const Icon(Icons.sms_outlined, size: 56),
                  const SizedBox(height: 12),
                  const TextComponent(
                    labelText:
                        "If this number is registered, we've sent a code on WhatsApp.",
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  TextComponent(
                    labelText: phone,
                    fontSize: 14,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const TextComponent(
                    labelText: 'The code is valid for 5 minutes.',
                    fontSize: 13,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    enabled: !verifying && !_rateLimited,
                    style: const TextStyle(
                      fontSize: 28,
                      letterSpacing: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      counterText: '',
                      hintText: '••••••',
                    ),
                    onChanged: (value) {
                      if (value.length == 6 && !verifying && !_rateLimited) {
                        context
                            .read<LoginBloc>()
                            .add(VerifyLoginCode(value));
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  const TextComponent(
                    labelText: 'You can paste the code from WhatsApp.',
                    fontSize: 12,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  if (_resendSeconds > 0)
                    TextComponent(
                      labelText: 'Resend in ${_resendSeconds}s',
                      fontSize: 14,
                      textAlign: TextAlign.center,
                    )
                  else ...[
                    TextButtonComponent(
                      labelText: 'Resend on WhatsApp',
                      onPressed: canResend
                          ? () => context
                              .read<LoginBloc>()
                              .add(const ResendLoginCode())
                          : () {},
                      fontSize: 14,
                      fontColor: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    TextButtonComponent(
                      labelText: 'Send by SMS',
                      onPressed: canResend
                          ? () => context.read<LoginBloc>().add(
                              const ResendLoginCode(channel: 'SMS'))
                          : () {},
                      fontSize: 14,
                      fontColor: AppColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButtonComponent(
                    labelText: 'Change number',
                    onPressed: () {
                      _codeController.clear();
                      context.read<LoginBloc>().add(const ChangeLoginPhone());
                    },
                    fontSize: 14,
                    fontColor: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  const SizedBox(height: 4),
                  const TextComponent(
                    labelText:
                        'A new SIM has to be updated by your Client Admin. This app cannot change the number on the account.',
                    fontSize: 12,
                    textAlign: TextAlign.center,
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
