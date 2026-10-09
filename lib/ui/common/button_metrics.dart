import 'package:flutter/material.dart';

/// Responsive button dimensions from the app button inventory (390×844 reference).
class ButtonMetrics {
  ButtonMetrics._();

  // Auth / common full-width CTA (#1, #13, etc.)
  static const double authRadius = 8;
  static const double authFontSize = 16;
  static const FontWeight authFontWeight = FontWeight.w600;
  static const EdgeInsets authVerticalPadding =
      EdgeInsets.symmetric(vertical: 14);

  // Driver submit (#31, #41)
  static double submitHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.085;
  static double submitRadius(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.025;
  static double submitFontSize(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.072;

  // Confirm arrival / handover (#50–53)
  static double confirmHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.07;
  /// Countdown seconds badge on confirm arrival, handover, and re-park CTAs.
  static const double countdownBadgeSize = 40;
  static const double countdownBadgeFontSize = 18;
  static const double confirmRadius = 12;
  static double confirmFontSize(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.025;
  static double confirmBigFontSize(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.06;

  // Camera submit parking (#47)
  static double cameraSubmitMinHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.052;
  static EdgeInsets cameraSubmitPadding(BuildContext context) =>
      EdgeInsets.symmetric(
        vertical: MediaQuery.sizeOf(context).height * 0.018,
      );
  static const double cameraSubmitRadius = 8;
  static double cameraSubmitFontSize(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.04;

  // Return to home (#49)
  static double returnHomeHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.07;
  static double returnHomeRadius(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.02;
  static double returnHomeFontSize(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.06;

  // Preview retake (#42)
  static double retakeWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.7;
  static double retakeHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height * 0.055;
  static double retakeRadius(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.08;
  static double retakeFontSize(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.04;
  static double retakeIconSize(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.05;

  // Driver action card inner bar (#28)
  static EdgeInsets actionBarPadding(BuildContext context) =>
      EdgeInsets.symmetric(
        vertical: MediaQuery.sizeOf(context).height * 0.018,
      );
  static double actionBarRadius(BuildContext context) =>
      MediaQuery.sizeOf(context).width * 0.025;
  static double actionBarFontSize(
    BuildContext context, {
    required bool isTablet,
    required bool isDesktop,
  }) {
    final w = MediaQuery.sizeOf(context).width;
    if (isDesktop) return w * 0.018;
    if (isTablet) return w * 0.028;
    return w * 0.048;
  }

  // Permissions (#15, #19)
  static const double permissionsMainHeight = 52;
  static const double permissionsSheetHeight = 48;
  static const double permissionsRadius = 12;
  static const double permissionsFontSize = 16;

  // Mandatory update (#14)
  static const double updateNowHeight = 48;
  static const double updateNowRadius = 12;
  static const double updateNowFontSize = 18;
}
