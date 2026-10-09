import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';

/// Design-system typography: Jost (labeled buttons and body via [TextComponent]).
class AppTypography {
  AppTypography._();

  static const String primaryFamily = 'Jost';

  /// Used when [primaryFamily] is unavailable (e.g. before Google Fonts loads).
  /// Used by [ThemeData.fontFamilyFallback] when Jost is unavailable.
  static const List<String> fallbackFamilies = [
    'Roboto',
    'Helvetica',
    'Arial',
    'sans-serif',
  ];

  // Type scale (px)
  static const double hero = 48;
  static const double section = 32;
  static const double subheading = 20;
  static const double body = 15;
  static const double label = 12;
  static const double cta = 15;

  static TextStyle style({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
    TextDecoration? decoration,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.jost(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
      decoration: decoration,
      fontStyle: fontStyle,
    );
  }

  static TextStyle get heroStyle => style(
        fontSize: hero,
        fontWeight: FontWeight.bold,
        color: AppColors.bodyText,
      );
  static TextStyle get sectionStyle => style(
        fontSize: section,
        fontWeight: FontWeight.bold,
        color: AppColors.bodyText,
      );
  static TextStyle get subheadingStyle => style(
        fontSize: subheading,
        fontWeight: FontWeight.w600,
        color: AppColors.bodyText,
      );
  static TextStyle get bodyStyle =>
      style(fontSize: body, color: AppColors.bodyText);
  /// Secondary labels (12px, muted gray).
  static TextStyle get labelStyle => style(
        fontSize: label,
        fontWeight: FontWeight.w500,
        color: AppColors.mutedText,
      );
  static TextStyle get mutedLabelStyle => labelStyle;
  static TextStyle get ctaStyle => style(
        fontSize: cta,
        fontWeight: FontWeight.w600,
        color: AppColors.bodyText,
      );

  /// Merges [base] with the app font stack; widget-level overrides win.
  static TextStyle merge(TextStyle? base) {
    final resolved = GoogleFonts.jost();
    if (base == null) return resolved;
    return resolved.merge(base);
  }
}
