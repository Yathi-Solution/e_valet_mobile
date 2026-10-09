import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/phone_Number/phone_number%20validation.dart';
import 'package:niloufer_valet_mobile/ui/common/phone_Number/phone_number_field.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';

class PhoneNumberFieldState extends State<PhoneNumberField> {
  late FocusNode _internalFocusNode;
  bool _isFocused = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = widget.focusNode ?? FocusNode();
    _internalFocusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _internalFocusNode.dispose();
    } else {
      _internalFocusNode.removeListener(_onFocusChange);
    }
    super.dispose();
  }

  void _onFocusChange() {
    setState(() {
      _isFocused = _internalFocusNode.hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final effectiveFocusNode = widget.focusNode ?? _internalFocusNode;
    final inputDecoration = InputDecoration(
      hintText: widget.hintText,
      hintStyle: TextStyle(
        fontSize: 14,
        color: AppColors.mutedText,
      ),
      filled: true,
      fillColor: AppColors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 12,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.surfaceBorder,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.accent,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(
          color: AppColors.error,
          width: 2,
        ),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(
          color: AppColors.surfaceBorder.withOpacity(0.5),
          width: 1,
        ),
      ),
      // Hide maxLength counter like "0/10"
      counterText: '',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextComponent(
          labelText: widget.labelText,
          fontSize: 14,
          color: AppColors.black,
          fontWeight: FontWeight.w500,
        ),
        const SizedBox(height: 8),
        if (widget.disableCountryPicker)
          // Use regular TextField with +91 prefix when country picker is disabled
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppColors.error
                        : (_isFocused
                            ? AppColors.accent
                            : AppColors.surfaceBorder),
                    width: _isFocused || _errorMessage != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: TextComponent(
                        labelText: t.get(TextConstants.countryCode),
                        fontSize: 14,
                        color: AppColors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: widget.controller,
                        focusNode: effectiveFocusNode,
                        textInputAction: widget.textInputAction,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          IndianPhoneNumberFormatter(),
                          LengthLimitingTextInputFormatter(10),
                        ],
                        onSubmitted: widget.onSubmitted,
                        onChanged: (value) {
                          setState(() {
                            _errorMessage = validateIndianPhoneNumber(value);
                          });

                          if (widget.onChanged != null) {
                            // Always prepend country code since country picker is disabled
                            widget.onChanged!(
                                '${t.get(TextConstants.countryCode)}$value');
                          }
                          // Auto-advance to next field when phone number is complete (10 digits)
                          if (value.length == 10 && widget.onComplete != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              widget.onComplete?.call();
                            });
                          }
                        },
                        decoration: inputDecoration.copyWith(
                          hintText: widget.hintText,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 12,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 12),
                  child: TextComponent(
                    labelText: _errorMessage!,
                    fontSize: 12,
                    color: AppColors.error,
                  ),
                ),
            ],
          )
        else
          IntlPhoneField(
            initialCountryCode: widget.initialCountryCode,
            controller: widget.controller,
            focusNode: widget.focusNode,
            textInputAction: widget.textInputAction,
            decoration: inputDecoration,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.black,
            ),
            onSubmitted: widget.onSubmitted,
            onChanged: (PhoneNumber phone) {
              // Validate if it's an Indian number
              if (phone.countryCode == '91') {
                setState(() {
                  _errorMessage = validateIndianPhoneNumber(phone.number);
                });
              } else {
                setState(() {
                  _errorMessage = null;
                });
              }

              if (widget.onChanged != null) {
                widget.onChanged!(phone.completeNumber);
              }
              // Auto-advance to next field when phone number is complete (10 digits for India)
              if (phone.countryCode == '91' &&
                  phone.number.length == 10 &&
                  widget.onComplete != null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  widget.onComplete?.call();
                });
              }
            },
            validator: (phone) {
              if (phone != null && phone.countryCode == '91') {
                return validateIndianPhoneNumber(phone.number);
              }
              return null;
            },
          ),
      ],
    );
  }
}
