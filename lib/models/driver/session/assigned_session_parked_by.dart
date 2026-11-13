import 'package:evalet/services/oauth/token_interceptor.dart';

class AssignedSessionParkedBy {
  final String userId;
  final String name;
  final String phone;

  AssignedSessionParkedBy({
    required this.userId,
    required this.name,
    required this.phone,
  });

  factory AssignedSessionParkedBy.fromJson(Map<String, dynamic> json) {
    return AssignedSessionParkedBy(
      userId: (json['userId'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
    );
  }

  /// True when the logged-in valet is the one who parked the car. The
  /// retrieval screens then show "Parked By You" and hide the call button,
  /// since the valet would only be calling their own number.
  bool get isCurrentUser {
    final currentUserId = TokenStorage.getCachedUserIdSync()?.trim() ?? '';
    return currentUserId.isNotEmpty && userId.trim() == currentUserId;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'phone': phone,
    };
  }
}
