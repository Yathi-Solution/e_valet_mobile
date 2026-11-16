import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/page_button_widget.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/page_size_dropdown_widget.dart';

/// Page-size picker, page buttons and the "1-10 of 42" label under the table.
class CarLogsPaginationBar extends StatelessWidget {
  const CarLogsPaginationBar({
    super.key,
    required this.currentPage,
    required this.itemsPerPage,
    required this.totalItems,
    required this.pageSizeOptions,
    required this.onPageSizeChanged,
    required this.onGoToPage,
  });

  final int currentPage;
  final int itemsPerPage;
  final int totalItems;
  final List<int> pageSizeOptions;
  final ValueChanged<int> onPageSizeChanged;
  final ValueChanged<int> onGoToPage;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final totalPages = (totalItems / itemsPerPage).ceil();
    final pageInfoText =
        '${(currentPage - 1) * itemsPerPage + 1}-${currentPage * itemsPerPage > totalItems ? totalItems : currentPage * itemsPerPage} of $totalItems';

    // Simplified bar when only one page (total from API reflects search)
    if (totalPages <= 1) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PageSizeDropdownWidget(
              itemsPerPage: itemsPerPage,
              pageSizeOptions: pageSizeOptions,
              onPageSizeChanged: onPageSizeChanged,
            ),
            const Spacer(),
            Flexible(
              child: TextComponent(
                labelText: pageInfoText,
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: AppColors.mutedText,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }

    final paginationRow = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Page size dropdown
        PageSizeDropdownWidget(
          itemsPerPage: itemsPerPage,
          pageSizeOptions: pageSizeOptions,
          onPageSizeChanged: onPageSizeChanged,
        ),
        const SizedBox(width: 8),
        // First page button (<<) - only show if not on first page
        if (currentPage > 1)
          IconButton(
            icon: TextComponent(
              labelText: t.get(TextConstants.paginationFirst),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onPressed: () => onGoToPage(1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        // Previous page button (<) - only show if not on first page
        if (currentPage > 1)
          IconButton(
            icon: TextComponent(
              labelText: t.get(TextConstants.paginationPrev),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onPressed: () => onGoToPage(currentPage - 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        if (currentPage > 1) const SizedBox(width: 8),
        ..._buildPageNumbers(totalPages),
        if (currentPage < totalPages) const SizedBox(width: 8),
        if (currentPage < totalPages)
          IconButton(
            icon: TextComponent(
              labelText: t.get(TextConstants.paginationNext),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onPressed: () => onGoToPage(currentPage + 1),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        if (currentPage < totalPages)
          IconButton(
            icon: TextComponent(
              labelText: t.get(TextConstants.paginationLast),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            onPressed: () => onGoToPage(totalPages),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
          ),
        const SizedBox(width: 8),
        TextComponent(
          labelText: pageInfoText,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.mutedText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: paginationRow,
      ),
    );
  }

  List<Widget> _buildPageNumbers(int totalPages) {
    final widgets = <Widget>[];
    const maxVisiblePages = 5;

    if (totalPages <= maxVisiblePages) {
      // Show all pages if total is small
      for (int i = 1; i <= totalPages; i++) {
        widgets.add(PageButtonWidget(
          page: i,
          currentPage: currentPage,
          onPressed: () => onGoToPage(i),
        ));
      }
    } else {
      // Show pages with ellipsis for large totals
      if (currentPage <= 3) {
        // Current page is near the beginning
        for (int i = 1; i <= 4; i++) {
          widgets.add(PageButtonWidget(
            page: i,
            currentPage: currentPage,
            onPressed: () => onGoToPage(i),
          ));
        }
        widgets.add(const Text('...', style: TextStyle(fontSize: 14)));
        widgets.add(PageButtonWidget(
          page: totalPages,
          currentPage: currentPage,
          onPressed: () => onGoToPage(totalPages),
        ));
      } else if (currentPage >= totalPages - 2) {
        // Current page is near the end
        widgets.add(PageButtonWidget(
          page: 1,
          currentPage: currentPage,
          onPressed: () => onGoToPage(1),
        ));
        widgets.add(const Text('...', style: TextStyle(fontSize: 14)));
        for (int i = totalPages - 3; i <= totalPages; i++) {
          widgets.add(PageButtonWidget(
            page: i,
            currentPage: currentPage,
            onPressed: () => onGoToPage(i),
          ));
        }
      } else {
        // Current page is in the middle
        widgets.add(PageButtonWidget(
          page: 1,
          currentPage: currentPage,
          onPressed: () => onGoToPage(1),
        ));
        widgets.add(const Text('...', style: TextStyle(fontSize: 14)));
        for (int i = currentPage - 1; i <= currentPage + 1; i++) {
          widgets.add(PageButtonWidget(
            page: i,
            currentPage: currentPage,
            onPressed: () => onGoToPage(i),
          ));
        }
        widgets.add(const Text('...', style: TextStyle(fontSize: 14)));
        widgets.add(PageButtonWidget(
          page: totalPages,
          currentPage: currentPage,
          onPressed: () => onGoToPage(totalPages),
        ));
      }
    }

    return widgets;
  }
}
