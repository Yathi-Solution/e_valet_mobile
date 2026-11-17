import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';

class PageButtonWidget extends StatelessWidget {
  final int page;
  final int currentPage;
  final VoidCallback onPressed;

  const PageButtonWidget({
    super.key,
    required this.page,
    required this.currentPage,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = page == currentPage;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor:
              isSelected ? AppColors.primary : AppColors.transparent,
          foregroundColor: isSelected ? AppColors.white : AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: TextComponent(
          labelText: page.toString(),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
