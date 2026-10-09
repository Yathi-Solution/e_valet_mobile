import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

/// Main title with accent bar and subtle background.
class GuidelinesMainTitle extends StatelessWidget {
  final String title;

  const GuidelinesMainTitle({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.accentSoft,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: AppColors.accent, width: 4),
        ),
      ),
      child: TextComponent(
        labelText: title,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.black,
      ),
    );
  }
}
