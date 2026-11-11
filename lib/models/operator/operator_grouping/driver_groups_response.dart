import 'package:evalet/models/operator/operator_grouping/driver_group.dart';

class DriverGroupsResponse {
  final List<DriverGroup> groups;

  DriverGroupsResponse({required this.groups});

  factory DriverGroupsResponse.fromJson(Map<String, dynamic> json) {
    return DriverGroupsResponse(
      groups: (json['groups'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DriverGroup.fromJson)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groups': groups.map((g) => g.toJson()).toList(),
    };
  }
}
