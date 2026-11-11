import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'code_input_field.dart';

class CodeInputSection extends StatefulWidget {
  final Function(String) onCodeChanged;

  const CodeInputSection({
    super.key,
    required this.onCodeChanged,
  });

  @override
  State<CodeInputSection> createState() => _CodeInputSectionState();
}

class _CodeInputSectionState extends State<CodeInputSection> {
  final List<TextEditingController> _controllers = List.generate(
    2,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    2,
    (_) => FocusNode(),
  );

  @override
  void initState() {
    super.initState();
    // Notify parent when code changes
    for (var controller in _controllers) {
      controller.addListener(_onCodeChanged);
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _onCodeChanged() {
    final code = _controllers[0].text + _controllers[1].text;
    widget.onCodeChanged(code);
  }

  void _onFieldChanged(String value, int index) {
    if (value.isNotEmpty && index < 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Column(
      children: [
        // Instruction Text
        Padding(
          padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
          child: TextComponent(
            labelText: t.get(TextConstants.enterTwoDigitCode),
            textAlign: TextAlign.center,
            fontSize: screenWidth * 0.04,
            color: AppColors.black,
            height: 1.5,
          ),
        ),

        SizedBox(height: screenHeight * 0.05),

        // 2-Digit Code Input Fields
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(2, (index) {
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
              child: CodeInputField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                onChanged: (value) => _onFieldChanged(value, index),
              ),
            );
          }),
        ),

        SizedBox(height: screenHeight * 0.04),

        // Customer has no phone? Link
        GestureDetector(
          onTap: () {
            // TODO: Handle customer has no phone
          },
          child: TextComponent(
            labelText: t.get(TextConstants.customerHasNoPhone),
            fontSize: screenWidth * 0.035,
            color: AppColors.secondary,
            textDecoration: TextDecoration.underline,
          ),
        ),
      ],
    );
  }
}
