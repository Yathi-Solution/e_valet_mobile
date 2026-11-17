import 'package:evalet/models/operator/operator_dashboard/car_log.dart';

class CarLogsResponse {
  final List<CarLog> logs;
  final int total;
  final int page;
  final int pageSize;

  CarLogsResponse({
    required this.logs,
    required this.total,
    required this.page,
    required this.pageSize,
  });

  factory CarLogsResponse.fromJson(Map<String, dynamic> json) {
    return CarLogsResponse(
      logs: (json['logs'] as List<dynamic>?)
              ?.map((log) => CarLog.fromJson(log as Map<String, dynamic>))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 0,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logs': logs.map((log) => log.toJson()).toList(),
      'total': total,
      'page': page,
      'pageSize': pageSize,
    };
  }
}
