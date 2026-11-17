import 'package:equatable/equatable.dart';
import 'package:evalet/models/notification/notification_priority.dart';
import 'package:evalet/models/notification/notification_type.dart';

/// Notification model representing a push notification
class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isRead;
  final String? imageUrl;
  final NotificationPriority priority;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.data,
    required this.timestamp,
    this.isRead = false,
    this.imageUrl,
    this.priority = NotificationPriority.normal,
  });

  /// Create from Firebase RemoteMessage data
  factory NotificationModel.fromFirebase(
    Map<String, dynamic> data, {
    String? title,
    String? body,
  }) {
    return NotificationModel(
      id: data['id'] ??
          data['messageId'] ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: title ?? data['title'] ?? 'Notification',
      body: body ?? data['body'] ?? '',
      type: NotificationType.fromString(data['type']),
      data: data,
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
      isRead: false,
      imageUrl: data['image_url'],
      priority: NotificationPriority.fromString(data['priority']),
    );
  }

  /// Create from JSON
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      type: NotificationType.fromString(json['type']),
      data: Map<String, dynamic>.from(json['data'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['isRead'] as bool? ?? false,
      imageUrl: json['imageUrl'] as String?,
      priority: NotificationPriority.fromString(json['priority']),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.value,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'imageUrl': imageUrl,
      'priority': priority.value,
    };
  }

  /// Copy with method
  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    NotificationType? type,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    bool? isRead,
    String? imageUrl,
    NotificationPriority? priority,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl ?? this.imageUrl,
      priority: priority ?? this.priority,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        data,
        timestamp,
        isRead,
        imageUrl,
        priority,
      ];
}
