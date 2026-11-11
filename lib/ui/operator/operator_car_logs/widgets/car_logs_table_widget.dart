import 'package:flutter/material.dart';
import 'package:evalet/models/operator/operator_dashboard/car_log.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/table_header_row_widget.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/table_data_row_widget.dart';

class CarLogsTableWidget extends StatelessWidget {
  final List<CarLog> logs;
  final String sortColumn;
  final SortDirection sortDirection;
  final Function(String) onHeaderTap;
  final IconData? Function(String) getSortIcon;
  final List<CarLog> Function(List<CarLog>) sortLogs;
  final Function(CarLog)? onRowTap;

  const CarLogsTableWidget({
    super.key,
    required this.logs,
    required this.sortColumn,
    required this.sortDirection,
    required this.onHeaderTap,
    required this.getSortIcon,
    required this.sortLogs,
    this.onRowTap,
  });

  @override
  Widget build(BuildContext context) {
    // Sort the logs based on current sorting state
    final sortedLogs = sortLogs(logs);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportWidth = constraints.maxWidth;
        // Use minimum table width on all platforms so data is fully visible via horizontal scroll (same as iOS)
        const minTableWidth = 1060.0;
        final tableWidth =
            viewportWidth < minTableWidth ? minTableWidth : viewportWidth;

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: tableWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                TableHeaderRowWidget(
                  availableWidth: tableWidth,
                  sortColumn: sortColumn,
                  sortDirection: sortDirection,
                  onHeaderTap: onHeaderTap,
                  getSortIcon: getSortIcon,
                ),
                // Data rows
                ...sortedLogs.asMap().entries.map((entry) {
                  final index = entry.key;
                  final log = entry.value;
                  return TableDataRowWidget(
                    log: log,
                    index: index,
                    availableWidth: tableWidth,
                    onTap: onRowTap != null ? () => onRowTap!(log) : null,
                  );
                }).toList(),
              ],
            ),
          ),
        );
      },
    );
  }
}
