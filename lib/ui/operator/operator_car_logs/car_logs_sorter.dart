import 'package:evalet/models/operator/operator_dashboard/car_log.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/operator/operator_car_logs/widgets/table_header_row_widget.dart';

/// Returns [logs] ordered by the column the operator tapped.
///
/// [sortColumn] is the column's header text. The list is returned unchanged
/// when no column is selected.
List<CarLog> sortCarLogs(
  List<CarLog> logs,
  String sortColumn,
  SortDirection sortDirection,
) {
  if (sortColumn.isEmpty || sortDirection == SortDirection.none) {
    return logs;
  }

  final sortedLogs = List<CarLog>.from(logs);

  sortedLogs.sort((a, b) {
    dynamic aValue;
    dynamic bValue;

    switch (sortColumn) {
      case TextConstants.carLogsTagNumber:
        aValue = a.tagNumber;
        bValue = b.tagNumber;
        break;
      case TextConstants.carLogsCarStatus:
        aValue = a.displayStatus;
        bValue = b.displayStatus;
        break;
      case TextConstants.carLogsDuration:
        aValue = a.duration;
        bValue = b.duration;
        break;
      case TextConstants.carLogsParkLocation:
        aValue = a.parkingLocation;
        bValue = b.parkingLocation;
        break;
      case TextConstants.carLogsParkedAt:
        aValue = DateTime.tryParse(a.parkedAt) ?? DateTime.now();
        bValue = DateTime.tryParse(b.parkedAt) ?? DateTime.now();
        break;
      case TextConstants.carLogsParkedBy:
        aValue = a.parkedBy.name;
        bValue = b.parkedBy.name;
        break;
      case TextConstants.carLogsRequestedMode:
        aValue = a.requestedMode;
        bValue = b.requestedMode;
        break;
      case TextConstants.carLogsRequestedAt:
        aValue = a.requestedAt.isEmpty
            ? null
            : DateTime.tryParse(a.requestedAt) ?? DateTime(0);
        bValue = b.requestedAt.isEmpty
            ? null
            : DateTime.tryParse(b.requestedAt) ?? DateTime(0);
        if (aValue == null && bValue == null) return 0;
        if (aValue == null)
          return sortDirection == SortDirection.ascending ? 1 : -1;
        if (bValue == null)
          return sortDirection == SortDirection.ascending ? -1 : 1;
        break;
      case TextConstants.carLogsHandoveredBy:
        aValue = a.handoveredBy.name;
        bValue = b.handoveredBy.name;
        break;
      case TextConstants.carLogsHandoverAt:
        aValue = a.handoveredAt.isEmpty
            ? null
            : DateTime.tryParse(a.handoveredAt) ?? DateTime(0);
        bValue = b.handoveredAt.isEmpty
            ? null
            : DateTime.tryParse(b.handoveredAt) ?? DateTime(0);
        if (aValue == null && bValue == null) return 0;
        if (aValue == null)
          return sortDirection == SortDirection.ascending ? 1 : -1;
        if (bValue == null)
          return sortDirection == SortDirection.ascending ? -1 : 1;
        break;
      default:
        return 0;
    }

    int comparison = 0;
    if (aValue is String && bValue is String) {
      comparison = aValue.toLowerCase().compareTo(bValue.toLowerCase());
    } else if (aValue is int && bValue is int) {
      comparison = aValue.compareTo(bValue);
    } else if (aValue is DateTime && bValue is DateTime) {
      comparison = aValue.compareTo(bValue);
    }

    return sortDirection == SortDirection.ascending ? comparison : -comparison;
  });

  return sortedLogs;
}
