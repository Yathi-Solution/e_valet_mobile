import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/button_metrics.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class ElevatedButtonComponent extends StatefulWidget {
  final String labelText;
  final void Function() onPressed;
  final Color? elevatedButtonBackgroundColor;
  final double? radius;
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
  final Widget? icon;
  const ElevatedButtonComponent(
      {super.key,
      required this.labelText,
      required this.onPressed,
      this.elevatedButtonBackgroundColor,
      this.radius,
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
      this.icon});

  @override
  State<ElevatedButtonComponent> createState() =>
      _ElevatedButtonComponentState();
}

class _ElevatedButtonComponentState extends State<ElevatedButtonComponent> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          padding: widget.padding,
          backgroundColor:
              widget.elevatedButtonBackgroundColor ?? AppColors.primary,
          foregroundColor: widget.fontColor ?? AppColors.textOnDark,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              widget.radius ?? ButtonMetrics.authRadius,
            ),
          ),
        ),
        child: widget.icon != null
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextComponent(
                    labelText: widget.labelText,
                    fontSize: widget.fontSize,
                    color: widget.fontColor ?? AppColors.textOnDark,
                    fontWeight: widget.fontWeight,
                    maxLines: widget.maxLines,
                    overflow: widget.overflow,
                    textAlign: widget.textAlign,
                    textBackgroundColor: widget.textbackgroundColor,
                    fontStyle: widget.fontStyle,
                  ),
                  const SizedBox(width: 8),
                  widget.icon!,
                ],
              )
            : TextComponent(
                labelText: widget.labelText,
                fontSize: widget.fontSize,
                color: widget.fontColor ?? AppColors.textOnDark,
                fontWeight: widget.fontWeight,
                maxLines: widget.maxLines,
                overflow: widget.overflow,
                textAlign: widget.textAlign,
                textBackgroundColor: widget.textbackgroundColor,
                fontStyle: widget.fontStyle,
              ));
  }
}
