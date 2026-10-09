import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';

class PageSizeDropdownWidget extends StatelessWidget {
  final int itemsPerPage;
  final List<int> pageSizeOptions;
  final Function(int) onPageSizeChanged;

  const PageSizeDropdownWidget({
    super.key,
    required this.itemsPerPage,
    required this.pageSizeOptions,
    required this.onPageSizeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Row(
      children: [
        TextComponent(
          labelText: t.getByKey(
              'paginationShowLabel', TextConstants.paginationShowLabel),
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedText,
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.grey.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButton<int>(
            value: itemsPerPage,
            onChanged: (int? newValue) {
              if (newValue != null) {
                onPageSizeChanged(newValue);
              }
            },
            items: pageSizeOptions.map<DropdownMenuItem<int>>((int value) {
              return DropdownMenuItem<int>(
                value: value,
                child: TextComponent(
                  labelText: value.toString(),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              );
            }).toList(),
            underline: const SizedBox.shrink(),
            icon: Icon(
              Icons.arrow_drop_down,
              size: 20,
              color: AppColors.mutedText,
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}
