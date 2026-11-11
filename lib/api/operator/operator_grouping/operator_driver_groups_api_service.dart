import 'package:evalet/api/core/api_config.dart';
import 'package:evalet/api/core/base_dio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/operator/operator_grouping/add_group_member_request.dart';
import 'package:evalet/models/operator/operator_grouping/create_driver_group_response.dart';
import 'package:evalet/models/operator/operator_grouping/driver_group_members_response.dart';
import 'package:evalet/models/operator/operator_grouping/driver_groups_response.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';

class OperatorDriverGroupsApiService {
  OperatorDriverGroupsApiService._();

  static String get _baseUrl => ApiConfig.valetBaseUrl;

  static void _errorLog(String message) {
    if (!kDebugMode) return;
    debugPrint('[OperatorDriverGroupsApiService] $message');
  }

  static Future<DriverGroupsResponse> getDriverGroups({
    required String outletId,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.get(
        '/operators/driver-groups',
        queryParameters: {
          'outletId': int.tryParse(outletId) ?? 1,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          final message =
              data is String ? data : 'Invalid response format from server.';
          throw ApiException(
            message,
            code: 'driver_groups_error',
            statusCode: response.statusCode,
          );
        }
        return DriverGroupsResponse.fromJson(data);
      }

      throw ApiException(
        'Failed to load driver groups. Status: ${response.statusCode}',
        code: 'driver_groups_error',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error fetching driver groups: $e',
        code: 'driver_groups_exception',
      );
    }
  }

  static Future<DriverGroupMembersResponse> getDriverGroupMembers({
    required String outletId,
    required int groupId,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.get(
        '/operators/driver-groups/$groupId/members',
        queryParameters: {
          'outletId': int.tryParse(outletId) ?? 1,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          final message =
              data is String ? data : 'Invalid response format from server.';
          throw ApiException(
            message,
            code: 'driver_group_members_error',
            statusCode: response.statusCode,
          );
        }
        return DriverGroupMembersResponse.fromJson(data);
      }

      throw ApiException(
        'Failed to load group members. Status: ${response.statusCode}',
        code: 'driver_group_members_error',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error fetching group members: $e',
        code: 'driver_group_members_exception',
      );
    }
  }

  static Future<CreateDriverGroupResponse> createDriverGroup({
    required String outletId,
    required String name,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.post(
        '/operators/driver-groups',
        queryParameters: {
          'outletId': int.tryParse(outletId) ?? 1,
        },
        data: {
          'name': name,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          final message =
              data is String ? data : 'Invalid response format from server.';
          throw ApiException(
            message,
            code: 'create_driver_group_error',
            statusCode: response.statusCode,
          );
        }

        // Swagger example wraps payload as { "group": { ... } }
        final groupJson = (data['group'] is Map<String, dynamic>)
            ? (data['group'] as Map<String, dynamic>)
            : data;

        var created = CreateDriverGroupResponse.fromJson(groupJson);

        // Fallback: if backend returns wrapper without id at expected place,
        // refetch groups and find the created group by name (latest id wins).
        if (created.id == 0) {
          try {
            final groups = await getDriverGroups(outletId: outletId);
            final match = groups.groups
                .where((g) => g.name.trim() == name.trim())
                .fold<int>(0, (maxId, g) => g.id > maxId ? g.id : maxId);
            if (match != 0) {
              created = CreateDriverGroupResponse(
                id: match,
                outletId: int.tryParse(outletId) ?? 0,
                name: name,
                memberCount: 0,
                createdAt: '',
                updatedAt: '',
              );
            }
          } catch (e) {
            _errorLog('Failed to resolve created group id from GET: $e');
          }
        }

        return created;
      }

      throw ApiException(
        'Failed to create driver group. Status: ${response.statusCode}',
        code: 'create_driver_group_error',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error creating driver group: $e',
        code: 'create_driver_group_exception',
      );
    }
  }

  static Future<void> addDriverGroupMember({
    required String outletId,
    required int groupId,
    required AddGroupMemberRequest request,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.post(
        '/operators/driver-groups/$groupId/members',
        queryParameters: {
          'outletId': int.tryParse(outletId) ?? 1,
        },
        data: request.toJson(),
      );

      // Swagger says 201 success
      if (response.statusCode == 201 || response.statusCode == 200) return;

      throw ApiException(
        'Failed to add group member. Status: ${response.statusCode}',
        code: 'add_group_member_error',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error adding group member: $e',
        code: 'add_group_member_exception',
      );
    }
  }

  static Future<void> removeDriverGroupMember({
    required String outletId,
    required int groupId,
    required String driverUserId,
  }) async {
    final accessToken = await TokenStorage.getAccessToken();

    if (accessToken == null || accessToken.isEmpty) {
      throw ApiException(
        'Access token not found. Please login again.',
        code: 'no_token',
      );
    }

    final base = BaseDioService(
      _baseUrl,
      ApiConfig.authorizedHeaders(accessToken),
    );

    try {
      final response = await base.delete(
        '/operators/driver-groups/$groupId/members/$driverUserId',
        queryParameters: {
          'outletId': int.tryParse(outletId) ?? 1,
        },
      );

      // Swagger shows 200 on successful delete
      if (response.statusCode == 200 || response.statusCode == 204) return;

      throw ApiException(
        'Failed to remove group member. Status: ${response.statusCode}',
        code: 'remove_group_member_error',
        statusCode: response.statusCode,
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        'Error removing group member: $e',
        code: 'remove_group_member_exception',
      );
    }
  }

  static Future<Set<String>> getAssignedDriverUserIds({
    required String outletId,
  }) async {
    final groupsRes = await getDriverGroups(outletId: outletId);
    if (groupsRes.groups.isEmpty) return <String>{};

    final membersResponses = await Future.wait(
      groupsRes.groups.map(
        (g) => getDriverGroupMembers(
          outletId: outletId,
          groupId: g.id,
        ),
      ),
    );

    final ids = <String>{};
    for (final res in membersResponses) {
      for (final member in res.members) {
        if (member.driverUserId.isNotEmpty) {
          ids.add(member.driverUserId);
        }
      }
    }
    return ids;
  }
}
