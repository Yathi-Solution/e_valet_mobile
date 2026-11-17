import 'package:flutter/material.dart';
import 'package:evalet/ui/driver/car_Camera/car_camera_screen.dart';

class CustomerMissingService {
  /// Handles the customer missing workflow and navigates directly to camera screen
  static Future<void> handleCustomerMissing({
    required BuildContext context,
    required String sessionId,
    required VoidCallback onSuccess,
  }) async {
    // Wait a moment to ensure dialog is fully closed before navigating
    await Future.delayed(const Duration(milliseconds: 100));

    // Check if widget is still mounted before using context
    if (!context.mounted) return;

    // Navigate directly to CarCameraScreen for re-parking
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => CarCameraScreen(
          sessionId: sessionId,
          isReparking: true,
          preventBackNavigation: true,
        ),
      ),
    );

    // Call success callback
    onSuccess();
  }
}
