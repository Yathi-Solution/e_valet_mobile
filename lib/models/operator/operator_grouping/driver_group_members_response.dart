import 'package:evalet/models/operator/operator_grouping/driver_group_member.dart';

class DriverGroupMembersResponse {
  final int groupId;
  final String groupName;
  final List<DriverGroupMember> members;

  DriverGroupMembersResponse({
    required this.groupId,
    required this.groupName,
    required this.members,
  });

  factory DriverGroupMembersResponse.fromJson(Map<String, dynamic> json) {
    return DriverGroupMembersResponse(
      groupId: (json['groupId'] as num?)?.toInt() ?? 0,
      groupName: (json['groupName'] as String?) ?? '',
      members: (json['members'] as List<dynamic>?)
              ?.whereType<Map<String, dynamic>>()
              .map(DriverGroupMember.fromJson)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'groupName': groupName,
      'members': members.map((m) => m.toJson()).toList(),
    };
  }
}
