import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';

class SortableHeaderCellWidget extends StatelessWidget {
  final String text;
  final bool isActive;
  final IconData? sortIcon;
  final VoidCallback onTap;

  const SortableHeaderCellWidget({
    super.key,
    required this.text,
    required this.isActive,
    this.sortIcon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(color: AppColors.grey.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextComponent(
                labelText: text,
                color: isActive ? AppColors.primary : AppColors.black,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
                textAlign: TextAlign.left,
              ),
            ),
            if (sortIcon != null) ...[
              const SizedBox(width: 4),
              Icon(
                sortIcon,
                size: 16,
                color: AppColors.primary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
