import 'package:flutter/material.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class OperatorDrawerItem extends StatelessWidget {
  final String? asset;
  final IconData? iconData;
  final String title;
  final bool isSelected;
  final VoidCallback? onTap;
  final double fontSize;
  final double rowHeight;
  final double iconSize;
  final double verticalMargin;

  const OperatorDrawerItem({
    super.key,
    this.asset,
    this.iconData,
    required this.title,
    this.isSelected = false,
    this.onTap,
    this.fontSize = 18,
    this.rowHeight = 44,
    this.iconSize = 35,
    this.verticalMargin = 8,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: verticalMargin),
        child: Row(
          children: [
            Expanded(
              child: Stack(
                children: [
                  if (isSelected)
                    Positioned.fill(
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: const BorderRadius.horizontal(
                                left: Radius.circular(4),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Container(
                                height: rowHeight,
                                margin: const EdgeInsets.only(left: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.cardBackground,
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(22),
                                    bottomLeft: Radius.circular(22),
                                  ),
                                  border: Border.all(
                                    color: AppColors.accent.withOpacity(0.35),
                                    width: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Container(
                    height: rowHeight,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    child: TextComponent(
                      labelText: title,
                      color: isSelected ? AppColors.black : AppColors.white,
                      fontSize: fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (iconData != null)
              Icon(
                iconData,
                size: iconSize,
                // Icons sit on the dark drawer strip (right of the pill), not on
                // the white selected background — keep them white when selected.
                color: AppColors.white,
              )
            else if (asset != null)
              Image.asset(
                asset!,
                width: iconSize,
                height: iconSize,
                color: AppColors.white,
              ),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.02,
            ),
          ],
        ),
      ),
    );
  }
}
