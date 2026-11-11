import 'package:flutter/material.dart';
import 'package:evalet/ui/driver/driver_home/status/driver_qr_scanner_content.dart';

/// Vehicle details screen (QR/tag entry) shown after tapping Park Vehicle.
class DriverVehicleDetailsScreen extends StatelessWidget {
  final double screenWidth;
  final double screenHeight;
  final bool isTablet;
  final bool isDesktop;
  final VoidCallback onReturnFromCarCamera;

  const DriverVehicleDetailsScreen({
    super.key,
    required this.screenWidth,
    required this.screenHeight,
    required this.isTablet,
    required this.isDesktop,
    required this.onReturnFromCarCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: DriverQrScannerContent(
            key: const ValueKey('vehicle_details'),
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            isTablet: isTablet,
            isDesktop: isDesktop,
            onReturnFromCarCamera: onReturnFromCarCamera,
          ),
        ),
      ],
    );
  }
}
