import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/typography.dart';

class TextFieldComponent extends StatefulWidget {
  final String labelText;
  final String? hintText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final FocusNode? focusNode;
  final Color? borderColor;
  final double? borderRadius;
  final Color? backgroundColor;
  final int? maxLines;
  final bool enabled;
  final EdgeInsets? contentPadding;
  final VoidCallback? onSubmitEditing;
  final TextInputAction? textInputAction;
  final double? fontSize;
  final double? labelFontSize;

  const TextFieldComponent({
    super.key,
    required this.labelText,
    this.hintText,
    this.controller,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.onChanged,
    this.focusNode,
    this.borderColor,
    this.borderRadius,
    this.backgroundColor,
    this.maxLines = 1,
    this.enabled = true,
    this.contentPadding,
    this.onSubmitEditing,
    this.textInputAction,
    this.fontSize,
    this.labelFontSize,
  });

  @override
  State<TextFieldComponent> createState() => _TextFieldComponentState();
}

class _TextFieldComponentState extends State<TextFieldComponent> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (widget.prefixIcon != null) ...[
              widget.prefixIcon!,
              const SizedBox(width: 8),
            ],
            TextComponent(
              labelText: widget.labelText,
              fontSize: widget.labelFontSize ?? 13,
              color: AppColors.nearBlack,
              fontWeight: FontWeight.w500,
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          validator: widget.validator,
          onChanged: widget.onChanged,
          focusNode: widget.focusNode,
          maxLines: widget.maxLines,
          enabled: widget.enabled,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onSubmitEditing != null
              ? (_) => widget.onSubmitEditing!()
              : null,
          style: AppTypography.merge(
            TextStyle(
              fontSize: widget.fontSize ?? AppTypography.body,
              color: AppColors.nearBlack,
            ),
          ),
          decoration: InputDecoration(
            hintText: widget.hintText,
            hintStyle: TextStyle(
              fontSize: widget.fontSize ?? 14,
              color: AppColors.mutedText,
            ),
            filled: true,
            fillColor: widget.backgroundColor ?? AppColors.white,
            contentPadding: widget.contentPadding ??
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? 8,
              ),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppColors.surfaceBorder,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? 8,
              ),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppColors.surfaceBorder,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? 8,
              ),
              borderSide: BorderSide(
                color: widget.borderColor ?? AppColors.accent,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? 8,
              ),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? 8,
              ),
              borderSide: const BorderSide(
                color: AppColors.error,
                width: 2,
              ),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                widget.borderRadius ?? 8,
              ),
              borderSide: BorderSide(
                color: AppColors.surfaceBorder.withOpacity(0.5),
                width: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
