import 'package:evalet/api/operator/operator_grouping/operator_driver_groups_api_service.dart';
import 'package:evalet/api/operator/operator_valet/valet_list_api_service.dart';
import 'package:evalet/models/operator/operator_grouping/add_group_member_request.dart';
import 'package:evalet/models/operator/operator_grouping/driver_group.dart';
import 'package:evalet/models/operator/operator_grouping/driver_group_member.dart';
import 'package:evalet/models/operator/operator_valet/valet_response.dart';

/// Driver groups for an outlet: the one place the grouping screens go to
/// read or change groups, so they do not call the API services themselves.
class DriverGroupsRepository {
  static Future<List<DriverGroup>> groups({required String outletId}) {
    return OperatorDriverGroupsApiService.getDriverGroups(
      outletId: outletId,
    ).then((res) => res.groups);
  }

  static Future<List<DriverGroupMember>> members({
    required String outletId,
    required int groupId,
  }) {
    return OperatorDriverGroupsApiService.getDriverGroupMembers(
      outletId: outletId,
      groupId: groupId,
    ).then((res) => res.members);
  }

  /// A group's name together with its members.
  static Future<({String groupName, List<DriverGroupMember> members})>
      groupWithMembers({
    required String outletId,
    required int groupId,
  }) {
    return OperatorDriverGroupsApiService.getDriverGroupMembers(
      outletId: outletId,
      groupId: groupId,
    ).then((res) => (groupName: res.groupName, members: res.members));
  }

  /// Every valet at the outlet, for picking group members.
  static Future<List<ValetResponse>> valets({required String outletId}) {
    return ValetListApiService.getValets(outletId: outletId)
        .then((r) => r.valets);
  }

  /// User ids of drivers that already belong to a group.
  static Future<Set<String>> assignedDriverUserIds({
    required String outletId,
  }) {
    return OperatorDriverGroupsApiService.getAssignedDriverUserIds(
      outletId: outletId,
    );
  }

  /// Adds the drivers to the group one after another, stopping at the first
  /// failure.
  static Future<void> addMembers({
    required String outletId,
    required int groupId,
    required Iterable<String> driverUserIds,
  }) async {
    for (final driverUserId in driverUserIds) {
      await OperatorDriverGroupsApiService.addDriverGroupMember(
        outletId: outletId,
        groupId: groupId,
        request: AddGroupMemberRequest(driverUserId: driverUserId),
      );
    }
  }

  /// Creates the group, then adds the drivers to it.
  static Future<void> createGroupWithMembers({
    required String outletId,
    required String name,
    required Iterable<String> driverUserIds,
  }) async {
    final created = await OperatorDriverGroupsApiService.createDriverGroup(
      outletId: outletId,
      name: name,
    );
    await addMembers(
      outletId: outletId,
      groupId: created.id,
      driverUserIds: driverUserIds,
    );
  }

  static Future<void> removeMember({
    required String outletId,
    required int groupId,
    required String driverUserId,
  }) {
    return OperatorDriverGroupsApiService.removeDriverGroupMember(
      outletId: outletId,
      groupId: groupId,
      driverUserId: driverUserId,
    );
  }
}
