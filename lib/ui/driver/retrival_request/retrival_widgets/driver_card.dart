import 'package:flutter/material.dart';
import 'package:evalet/models/driver/session/pass_available_driver.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';

class DriverCard extends StatelessWidget {
  final PassAvailableDriver driver;
  final double screenWidth;
  final bool isPassing;
  final bool isAnyPassing;
  final VoidCallback? onTap;

  const DriverCard({
    super.key,
    required this.driver,
    required this.screenWidth,
    required this.isPassing,
    required this.isAnyPassing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = isAnyPassing && !isPassing;

    return Opacity(
      opacity: disabled ? 0.45 : 1.0,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: (isAnyPassing || onTap == null) ? null : onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPassing ? AppColors.primary : AppColors.surfaceBorder,
                width: isPassing ? 1.5 : 1,
              ),
            ),
            child: isPassing
                ? const SizedBox(
                    height: 36,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : Row(
                    children: [
                      // Round avatar with initials
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: TextComponent(
                          labelText: driver.initials,
                          fontSize: screenWidth * 0.03,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 4),
                      // Name
                      Expanded(
                        child: TextComponent(
                          labelText: driver.name,
                          fontSize: screenWidth * 0.035,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
