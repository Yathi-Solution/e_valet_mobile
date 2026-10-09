import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class SnackBars {
  static void showErrorSnackBar(BuildContext context, String message) {
    if (isNetworkConnectivityMessage(message)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: TextComponent(
          labelText: message,
          fontSize: 14.0,
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        content: TextComponent(
          labelText: message,
          fontSize: 14.0,
          color: AppColors.white,
          fontWeight: FontWeight.w500,
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
