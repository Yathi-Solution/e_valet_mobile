import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text_field.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_state.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_state.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/ui/driver/car_Camera/car_camera_screen.dart';

class DriverManualEntryContent extends StatefulWidget {
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;
  final VoidCallback? onSwitchToQrScanner;

  const DriverManualEntryContent({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
    this.onSwitchToQrScanner,
  });

  @override
  State<DriverManualEntryContent> createState() =>
      _DriverManualEntryContentState();
}

class _DriverManualEntryContentState extends State<DriverManualEntryContent> {
  final TextEditingController _tagNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _submittedCardNumber;

  bool get _canSubmitTagNumber => _tagNumberController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tagNumberController.addListener(_onTagFormChanged);
  }

  void _onTagFormChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tagNumberController.removeListener(_onTagFormChanged);
    _tagNumberController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_formKey.currentState?.validate() ?? false) {
      final tagNumber = _tagNumberController.text.trim();

      // Parse card number from tag number
      final cardNumber = int.tryParse(tagNumber);
      if (cardNumber == null) {
        // Show error if tag number is not a valid number
        final t = context.read<AppTranslationsNotifier>();
        SnackBars.showErrorSnackBar(
          context,
          t.get(TextConstants.validationEnterValidTagNumber),
        );
        return;
      }

      if (!TokenStorage.isDriverAssignedCardsLoadedSync()) {
        final t = context.read<AppTranslationsNotifier>();
        final msg = t.get(TextConstants.driverCardsLoading);
        SnackBars.showErrorSnackBar(
          context,
          msg.isNotEmpty ? msg : TextConstants.driverCardsLoading,
        );
        return;
      }

      if (!TokenStorage.isDriverCardNumberAllowedSync(cardNumber)) {
        final t = context.read<AppTranslationsNotifier>();
        final msg = t.get(TextConstants.driverCardNotAssigned);
        final baseMsg =
            msg.isNotEmpty ? msg : TextConstants.driverCardNotAssigned;
        SnackBars.showErrorSnackBar(
          context,
          '$baseMsg Please contact Operator.',
        );
        return;
      }

      _submittedCardNumber = cardNumber.toString();

      // Get outletId from DriverStatusBloc
      final statusState = context.read<DriverStatusBloc>().state;
      int outletId =
          int.tryParse(dotenv.env['OUTLET_ID'] ?? '1') ?? 1; // Default fallback

      if (statusState is DriverStatusLoaded) {
        outletId = statusState.status.outletId;
      }

      context.read<TagSubmissionBloc>().add(
            TagNumberSubmitted(
              outletId: outletId,
              cardNumber: cardNumber,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final w = widget.screenWidth;
    final h = widget.screenHeight;

    return BlocListener<TagSubmissionBloc, TagSubmissionState>(
      listener: (context, state) {
        if (state is TagSubmissionSuccess) {
          // Navigate to Car Camera Screen on success
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CarCameraScreen(
                sessionId: null,
                preventBackNavigation: true,
                cardNumber: _submittedCardNumber,
              ),
            ),
          );
        }
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: w * 0.04),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card with icon + title + input
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(w * 0.04),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(w * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow10,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(
                      'assets/svg/key_handover.svg',
                      width: w * 0.2,
                      height: w * 0.2,
                    ),
                    SizedBox(height: h * 0.022),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextComponent(
                        labelText: t.get(TextConstants.tagNumberLabel),
                        fontSize: w * 0.048,
                        fontWeight: FontWeight.w600,
                        color: AppColors.black,
                      ),
                    ),
                    TextFieldComponent(
                      labelText: t.get(TextConstants.emptyText),
                      hintText: t.getByKey(
                          'tagNumberHint', TextConstants.tagNumberHint),
                      controller: _tagNumberController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      fontSize: w * 0.044,
                      labelFontSize: w * 0.048,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: w * 0.04, vertical: h * 0.022),
                      onSubmitEditing: _handleSubmit,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return t.get(TextConstants.validationEnterTagNumber);
                        }
                        final cardNumber = int.tryParse(value.trim());
                        if (cardNumber == null) {
                          return t
                              .get(TextConstants.validationEnterValidNumber);
                        }
                        return null;
                      },
                      borderRadius: w * 0.03,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: h * 0.028),
            // "Or scan the tag number" link (also outside card)
            if (widget.onSwitchToQrScanner != null)
              GestureDetector(
                onTap: widget.onSwitchToQrScanner,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: h * 0.015),
                  child: TextComponent(
                    labelText: t.get(TextConstants.scanTagNumberLink),
                    fontSize: w * 0.042,
                    fontWeight: FontWeight.w500,
                    color: AppColors.mutedText,
                    textAlign: TextAlign.center,
                    textDecoration: TextDecoration.underline,
                  ),
                ),
              ),
            SizedBox(height: h * 0.02),
            // Submit button – same styling as preview Done button for consistency
            BlocBuilder<TagSubmissionBloc, TagSubmissionState>(
              builder: (context, state) {
                final isLoading = state is TagSubmissionLoading;
                final canSubmit = _canSubmitTagNumber && !isLoading;
                final buttonHeight = h * 0.085;
                final textSize = w * 0.072;

                return SizedBox(
                  width: double.infinity,
                  height: buttonHeight,
                  child: ElevatedButton(
                    onPressed: canSubmit ? _handleSubmit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.grey.withOpacity(0.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(w * 0.025),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextComponent(
                                labelText: t.getByKey(
                                    'submitButton', TextConstants.submitButton),
                                fontSize: textSize,
                                fontWeight: FontWeight.w600,
                                color: AppColors.white,
                              ),
                              SizedBox(width: w * 0.02),
                              Icon(
                                Icons.arrow_forward,
                                color: AppColors.white,
                                size: textSize,
                              ),
                            ],
                          ),
                  ),
                );
              },
            ),
            // Extra bottom space so user can scroll submit button above keyboard
            SizedBox(height: h * 0.12),
          ],
        ),
      ),
    );
  }
}
