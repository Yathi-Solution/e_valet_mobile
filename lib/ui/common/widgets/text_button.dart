import 'package:flutter/material.dart';
import 'package:evalet/ui/common/widgets/text.dart';

class TextButtonComponent extends StatelessWidget {
  final String labelText;
  final void Function()? onPressed;
  final double? fontSize;
  final Color? fontColor;
  final FontWeight? fontWeight;
  final String? fontFamily;
  final EdgeInsets? padding;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final Color? textbackgroundColor;
  final FontStyle? fontStyle;

  const TextButtonComponent({
    super.key,
    required this.labelText,
    this.onPressed,
    this.fontSize,
    this.fontColor,
    this.maxLines,
    this.textbackgroundColor,
    this.padding,
    this.overflow,
    this.textAlign,
    this.fontWeight,
    this.fontFamily,
    this.fontStyle,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: padding,
      ),
      child: TextComponent(
        labelText: labelText,
        fontSize: fontSize,
        color: fontColor,
        fontWeight: fontWeight,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
        textBackgroundColor: textbackgroundColor,
        fontStyle: fontStyle,
      ),
    );
  }
}
