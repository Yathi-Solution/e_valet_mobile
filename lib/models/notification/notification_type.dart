/// The server's FCM type for a new assignment (`retrieval_assigned`) is handled
/// exactly like the legacy `retrieval_request`.
bool isRetrievalAlertType(String? type) =>
    type == 'retrieval_request' || type == 'retrieval_assigned';

/// Notification types for the valet system
enum NotificationType {
  retrievalRequest('retrieval_request'),
  driverAssigned('driver_assigned'),
  driverUpdate('driver_update'),
  vehicleReady('vehicle_ready'),
  vehicleDelivered('vehicle_delivered'),
  systemAlert('system_alert'),
  general('general'),
  unknown('unknown');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'retrieval_request':
      case 'retrieval_assigned':
        return NotificationType.retrievalRequest;
      case 'driver_assigned':
        return NotificationType.driverAssigned;
      case 'driver_update':
        return NotificationType.driverUpdate;
      case 'vehicle_ready':
        return NotificationType.vehicleReady;
      case 'vehicle_delivered':
        return NotificationType.vehicleDelivered;
      case 'system_alert':
        return NotificationType.systemAlert;
      case 'general':
        return NotificationType.general;
      default:
        return NotificationType.unknown;
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.retrievalRequest:
        return 'Retrieval Request';
      case NotificationType.driverAssigned:
        return 'Driver Assigned';
      case NotificationType.driverUpdate:
        return 'Driver Update';
      case NotificationType.vehicleReady:
        return 'Vehicle Ready';
      case NotificationType.vehicleDelivered:
        return 'Vehicle Delivered';
      case NotificationType.systemAlert:
        return 'System Alert';
      case NotificationType.general:
        return 'General';
      case NotificationType.unknown:
        return 'Notification';
    }
  }
}
