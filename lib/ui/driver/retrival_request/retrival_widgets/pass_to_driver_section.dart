import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';

class PassToDriverSection extends StatelessWidget {
  final double screenWidth;
  final bool isPassing;
  final bool isDisabled;
  final VoidCallback? onPass;

  const PassToDriverSection({
    super.key,
    required this.screenWidth,
    required this.isPassing,
    this.isDisabled = false,
    required this.onPass,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: AppColors.divider, height: 24),

        // Section header

        const SizedBox(height: 10),
        SizedBox(
          height: 55,
          child: ElevatedButton.icon(
            onPressed: (isPassing || isDisabled) ? null : onPass,
            icon: isPassing
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.black),
                    ),
                  )
                : const Icon(
                    Icons.swap_horiz_rounded,
                    size: 18,
                    color: AppColors.black,
                  ),
            label: Text(
              isPassing ? 'Passing...' : 'Pass To Another Driver',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w600,
                color: AppColors.black,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF87171),
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
