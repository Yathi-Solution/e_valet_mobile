import 'package:evalet/models/oauth/user_profile.dart';

class Profile {
  final UserProfile user;
  final String applicationId;
  final List<String> roles;

  Profile({
    required this.user,
    required this.applicationId,
    required this.roles,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? {};
    final rolesList = json['roles'] as List<dynamic>? ?? [];

    return Profile(
      user: UserProfile.fromJson(userJson),
      applicationId: (json['applicationId'] ?? '').toString(),
      roles: rolesList.map((r) => r.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'applicationId': applicationId,
      'roles': roles,
    };
  }
}
