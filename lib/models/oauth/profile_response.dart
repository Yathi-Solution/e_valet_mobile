import 'package:niloufer_valet_mobile/models/oauth/user_profile.dart';

class ProfileResponse {
  final UserProfile user;
  final String applicationId;
  final List<String> roles;

  ProfileResponse({
    required this.user,
    required this.applicationId,
    required this.roles,
  });

  /// Parses JSON response from profile API.
  /// Handles both top-level roles and nested application.roles.
  factory ProfileResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};

    // Roles can be at top-level or nested under application
    List<dynamic> rolesList = [];

    // Try top-level roles first (most common in actual responses)
    if (json['roles'] is List<dynamic>) {
      rolesList = json['roles'] as List<dynamic>;
    }
    // Fallback to nested application.roles
    else if (json['application'] is Map<String, dynamic>) {
      final app = json['application'] as Map<String, dynamic>;
      if (app['roles'] is List<dynamic>) {
        rolesList = app['roles'] as List<dynamic>;
      }
    }

    // Normalize role entries: they might be strings or objects
    final parsedRoles = rolesList.map<String>((r) {
      if (r is String) return r;
      if (r is Map<String, dynamic>) {
        // Common keys that might contain role name
        if (r['name'] != null) return r['name'].toString();
        if (r['role'] != null) return r['role'].toString();
      }
      return r.toString();
    }).toList();

    // applicationId can be at top-level or nested under application.id
    String applicationId = '';
    if (json['applicationId'] != null) {
      applicationId = json['applicationId'].toString();
    } else if (json['application'] is Map<String, dynamic> &&
        json['application']['id'] != null) {
      applicationId = json['application']['id'].toString();
    }

    return ProfileResponse(
      user: UserProfile.fromJson(userJson),
      applicationId: applicationId,
      roles: parsedRoles,
    );
  }

  /// Parses GET /auth/me: { user: {id,name,phone,email}, client, role }.
  /// The single `role` (DRIVER | OPERATOR | CLIENT_ADMIN) becomes the roles
  /// list and the Client id stands in for the old application id.
  factory ProfileResponse.fromMe(Map<String, dynamic> json) {
    final u = json['user'] as Map<String, dynamic>? ?? const {};
    final client = json['client'] as Map<String, dynamic>? ?? const {};
    final name = (u['name'] ?? '').toString().trim();
    final space = name.indexOf(' ');
    return ProfileResponse(
      user: UserProfile(
        id: (u['id'] ?? '').toString(),
        email: (u['email'] ?? '').toString(),
        username: '',
        firstName: space == -1 ? name : name.substring(0, space),
        lastName: space == -1 ? '' : name.substring(space + 1).trim(),
        fullName: name,
        phoneNumber: (u['phone'] ?? '').toString(),
        isActive: true,
        createdAt: '',
      ),
      applicationId: (client['id'] ?? '').toString(),
      roles: [
        if (json['role'] != null) json['role'].toString(),
      ],
    );
  }

  /// Lowercased, trimmed roles for easy matching.
  List<String> get normalizedRoles =>
      roles.map((r) => r.toLowerCase().trim()).toList();

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'applicationId': applicationId,
      'roles': roles,
    };
  }

  @override
  String toString() =>
      'ProfileResponse(applicationId: $applicationId, roles: $roles)';
}
