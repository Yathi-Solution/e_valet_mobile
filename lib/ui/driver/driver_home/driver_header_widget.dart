import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_state.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/status/driver_break_toggle_widget.dart';

class DriverHeaderWidget extends StatelessWidget {
  final bool isOnline;
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;

  /// When true, show back button on the left (same line as break toggle, other side).
  final bool showBackButton;
  final VoidCallback? onBackPressed;

  const DriverHeaderWidget({
    super.key,
    required this.isOnline,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
    this.showBackButton = false,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    // Responsive content height (excluding AppBar) - slightly increased for better spacing
    final contentHeight = isDesktop
        ? screenHeight * 0.06
        : isTablet
            ? screenHeight * 0.07
            : screenHeight * 0.06;

    final padding = screenWidth * 0.02;

    return Container(
      width: screenWidth,
      height: contentHeight,
      decoration: const BoxDecoration(
        color: AppColors.headerDark,
      ),
      child: BlocBuilder<DriverStatusBloc, DriverStatusState>(
        builder: (context, statusState) {
          // Get online status from API, fallback to prop if not loaded yet
          final isCurrentlyOnline = statusState is DriverStatusLoaded
              ? statusState.status.isOnline
              : isOnline;

          return Stack(
            children: [
              // Back button on the left (same line as break toggle, other side)
              if (showBackButton && onBackPressed != null)
                Positioned(
                  top: 4,
                  left: padding * 0.5,
                  child: IconButton(
                    onPressed: onBackPressed,
                    icon: const Icon(Icons.arrow_back, color: AppColors.white),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              // On Break toggle only on first screen (home with Park Vehicle). Hide on QR scan / vehicle details / any screen with back button.
              if (isCurrentlyOnline && !showBackButton)
                Positioned(
                  top: 4, // Minimal offset from top (4 pixels)
                  right: padding, // Gap from right edge
                  child: DriverBreakToggleWidget(
                    screenWidth: screenWidth,
                    isTablet: isTablet,
                    isDesktop: isDesktop,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
