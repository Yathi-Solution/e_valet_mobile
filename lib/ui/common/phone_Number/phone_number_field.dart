import 'package:flutter/material.dart';
import 'package:evalet/ui/common/phone_Number/phone_number_field_state.dart';

class PhoneNumberField extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final void Function(String)? onChanged;
  final String initialCountryCode;
  final TextInputAction? textInputAction;
  final void Function(String)? onSubmitted;

  /// Called when the phone number reaches full length (e.g. 10 digits), so focus can move to next field.
  final VoidCallback? onComplete;
  final bool disableCountryPicker;

  const PhoneNumberField({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.initialCountryCode = 'IN',
    this.textInputAction,
    this.onSubmitted,
    this.onComplete,
    this.disableCountryPicker = false,
  });

  @override
  State<PhoneNumberField> createState() => PhoneNumberFieldState();
}
