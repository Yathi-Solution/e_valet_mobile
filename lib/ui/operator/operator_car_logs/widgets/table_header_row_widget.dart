import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/sortable_header_cell_widget.dart';

enum SortDirection { none, ascending, descending }

class TableHeaderRowWidget extends StatelessWidget {
  final double availableWidth;
  final String sortColumn;
  final SortDirection sortDirection;
  final Function(String) onHeaderTap;
  final IconData? Function(String) getSortIcon;

  const TableHeaderRowWidget({
    super.key,
    required this.availableWidth,
    required this.sortColumn,
    required this.sortDirection,
    required this.onHeaderTap,
    required this.getSortIcon,
  });

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return Container(
      width: availableWidth,
      decoration: BoxDecoration(
        color: AppColors.grey.withOpacity(0.1),
        border: Border(
          bottom: BorderSide(color: AppColors.grey.withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 12,
            child: SortableHeaderCellWidget(
              text: t.get(TextConstants.carLogsTagNumber),
              isActive: sortColumn == TextConstants.carLogsTagNumber,
              sortIcon: getSortIcon(TextConstants.carLogsTagNumber),
              onTap: () => onHeaderTap(TextConstants.carLogsTagNumber),
            ),
          ),
          Expanded(
            flex: 16,
            child: SortableHeaderCellWidget(
              text: t.getByKey(
                  'carLogsCarStatus', TextConstants.carLogsCarStatus),
              isActive: sortColumn == TextConstants.carLogsCarStatus,
              sortIcon: getSortIcon(TextConstants.carLogsCarStatus),
              onTap: () => onHeaderTap(TextConstants.carLogsCarStatus),
            ),
          ),
          Expanded(
            flex: 16,
            child: SortableHeaderCellWidget(
              text:
                  t.getByKey('carLogsDuration', TextConstants.carLogsDuration),
              isActive: sortColumn == TextConstants.carLogsDuration,
              sortIcon: getSortIcon(TextConstants.carLogsDuration),
              onTap: () => onHeaderTap(TextConstants.carLogsDuration),
            ),
          ),
          Expanded(
            flex: 20,
            child: SortableHeaderCellWidget(
              text: t.getByKey(
                  'carLogsParkLocation', TextConstants.carLogsParkLocation),
              isActive: sortColumn == TextConstants.carLogsParkLocation,
              sortIcon: getSortIcon(TextConstants.carLogsParkLocation),
              onTap: () => onHeaderTap(TextConstants.carLogsParkLocation),
            ),
          ),
          Expanded(
            flex: 20,
            child: SortableHeaderCellWidget(
              text: t.get(TextConstants.carLogsParkedBy),
              isActive: sortColumn == TextConstants.carLogsParkedBy,
              sortIcon: getSortIcon(TextConstants.carLogsParkedBy),
              onTap: () => onHeaderTap(TextConstants.carLogsParkedBy),
            ),
          ),
          Expanded(
            flex: 16,
            child: SortableHeaderCellWidget(
              text:
                  t.getByKey('carLogsParkedAt', TextConstants.carLogsParkedAt),
              isActive: sortColumn == TextConstants.carLogsParkedAt,
              sortIcon: getSortIcon(TextConstants.carLogsParkedAt),
              onTap: () => onHeaderTap(TextConstants.carLogsParkedAt),
            ),
          ),
          Expanded(
            flex: 16,
            child: SortableHeaderCellWidget(
              text: t.get(TextConstants.carLogsRequestedMode),
              isActive: sortColumn == TextConstants.carLogsRequestedMode,
              sortIcon: getSortIcon(TextConstants.carLogsRequestedMode),
              onTap: () => onHeaderTap(TextConstants.carLogsRequestedMode),
            ),
          ),
          Expanded(
            flex: 16,
            child: SortableHeaderCellWidget(
              text: t.get(TextConstants.carLogsRequestedAt),
              isActive: sortColumn == TextConstants.carLogsRequestedAt,
              sortIcon: getSortIcon(TextConstants.carLogsRequestedAt),
              onTap: () => onHeaderTap(TextConstants.carLogsRequestedAt),
            ),
          ),
          Expanded(
            flex: 16,
            child: SortableHeaderCellWidget(
              text: t.getByKey(
                  'carLogsHandoveredBy', TextConstants.carLogsHandoveredBy),
              isActive: sortColumn == TextConstants.carLogsHandoveredBy,
              sortIcon: getSortIcon(TextConstants.carLogsHandoveredBy),
              onTap: () => onHeaderTap(TextConstants.carLogsHandoveredBy),
            ),
          ),
          Expanded(
            flex: 16,
            child: SortableHeaderCellWidget(
              text: t.getByKey(
                  'carLogsHandoverAt', TextConstants.carLogsHandoverAt),
              isActive: sortColumn == TextConstants.carLogsHandoverAt,
              sortIcon: getSortIcon(TextConstants.carLogsHandoverAt),
              onTap: () => onHeaderTap(TextConstants.carLogsHandoverAt),
            ),
          ),
        ],
      ),
    );
  }
}
