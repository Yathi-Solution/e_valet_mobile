import 'package:flutter/material.dart';

/// App Color Scheme — design-system tokens.
class AppColors {
  AppColors._();

  // Dark / header — top bar, primary buttons (#1C1C1E).
  static const Color headerDark = Color(0xFF1C1C1E);
  static const Color nearBlack = headerDark;

  // Brand — charcoal for headers/primary CTAs; coral for logo, highlights, active UI.
  static const Color primary = headerDark;
  static const Color primaryDark = headerDark;

  /// Accent — logo highlights, key highlights, active states only (#D85A30).
  static const Color coral = Color(0xFFD85A30);
  static const Color orange = coral;
  static const Color accent = coral;
  static const Color actionButtonYellow = coral;
  static const Color accentSoft = Color(0x1AD85A30);
  static const Color primarySoft = accentSoft;
  static const Color coralLight = Color(0x33D85A30);

  /// Legacy alias — prefer [headerDark] for app bars.
  static const Color headerYellow = headerDark;

  // Neutrals
  static const Color offWhite = Color(0xFFF5F5F0);
  static const Color trackGray = Color(0xFFE8E8E4);
  /// Muted text — secondary labels, hints, captions (#6B7280).
  static const Color mutedText = Color(0xFF6B7280);
  static const Color secondaryLabel = mutedText;
  /// @deprecated Prefer [mutedText] for secondary labels.
  static const Color footerGray = mutedText;
  static const Color disabledBackground = trackGray;
  static const Color disabledText = mutedText;

  // Semantic
  static const Color infoBlue = Color(0xFF378ADD);
  static const Color secondary = Color(0xFF39756A);

  // Surfaces
  /// Primary surface — page backgrounds and cards (#FFFFFF).
  static const Color primarySurface = Color(0xFFFFFFFF);
  static const Color background = primarySurface;
  static const Color lightBeigeBackground = primarySurface;
  static const Color surface = primarySurface;
  static const Color cardBackground = primarySurface;
  static const Color surfaceBorder = trackGray;
  static const Color divider = Color(0xFFE5E7EB);
  static const Color shadow10 = Color(0x1A000000);

  /// Body text on white / light surfaces (#1C1C1E).
  static const Color bodyText = headerDark;

  /// Text on dark surfaces — app bar titles, primary button labels (#FFFFFF).
  static const Color textOnDark = Color(0xFFFFFFFF);

  static const Color greyLight = Color(0xFFE0E0E0);
  static const Color success = Colors.green;
  static const Color error = Colors.red;
  static const Color cancelAssignmentIcon = Color(0xFFFF5722);
  static const Color black = bodyText;
  static const Color grey = Colors.grey;
  static const Color white = textOnDark;
  static const Color blue = Colors.blue;
  static const Color purple = Colors.purple;
  static const Color transparent = Colors.transparent;

  // QR Scanner
  static const Color qrSuccessBackground = Color(0x1A4CAF50);
  static const Color qrSuccessBorder = Color(0xFF4CAF50);
  static const Color qrSuccessText = Color(0xFF4CAF50);
  static const Color qrErrorBackground = Color(0x1AF44336);
  static const Color qrProcessingOverlay = Color(0x80000000);
  static const Color qrSuccessBorderLight = Color(0x4D4CAF50);
  static const Color qrSuccessColor = Color(0xFF10B981);
  static const Color qrErrorColor = Color(0xFFEF4444);
  static const Color qrSuccessBg = Color(0xFFECFDF5);
  static const Color qrErrorBg = Color(0xFFFEF2F2);

  static const Color manualRequestFillColor = Color(0xFFE0E0E0);
}
