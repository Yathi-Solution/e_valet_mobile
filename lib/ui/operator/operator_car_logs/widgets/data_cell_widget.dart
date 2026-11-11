import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/text.dart';

class DataCellWidget extends StatelessWidget {
  final String text;

  const DataCellWidget({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(color: AppColors.grey.withOpacity(0.3)),
        ),
      ),
      child: TextComponent(
        labelText: text,
        color: AppColors.black,
        fontSize: 13,
        fontWeight: FontWeight.normal,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        softWrap: true,
        textAlign: TextAlign.left,
      ),
    );
  }
}
