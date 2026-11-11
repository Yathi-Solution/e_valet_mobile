import 'package:flutter/material.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/utils/duration_utils.dart';
import 'package:evalet/utils/time_utils.dart';

class RetrievalRequestUtils {
  RetrievalRequestUtils._();

  /// Converts a waiting time string into a duration label like "1h 05m" or "45m".
  /// The API often provides `waitingTime` like "10 mins"; we normalize to hours/mins.
  static String formatWaitingTime(String waitingTime) {
    final minutesStr = waitingTime.replaceAll(RegExp(r'[^0-9]'), '');
    final minutes = int.tryParse(minutesStr);
    if (minutes == null) return waitingTime;
    return DurationUtils.formatCompactHoursMinutes(minutes);
  }

  static Color getPriorityColor(String waitingTime) {
    final minutesStr = waitingTime.replaceAll(RegExp(r'[^0-9]'), '');
    final minutes = int.tryParse(minutesStr) ?? 0;

    if (minutes >= 30) {
      return AppColors.error;
    } else if (minutes >= 15) {
      return AppColors.primary;
    }
    return AppColors.success;
  }

  static String getPriorityLabel(String waitingTime) {
    final minutesStr = waitingTime.replaceAll(RegExp(r'[^0-9]'), '');
    final minutes = int.tryParse(minutesStr) ?? 0;

    if (minutes >= 30) {
      return 'High';
    } else if (minutes >= 15) {
      return 'Medium';
    }
    return 'Low';
  }

  static String formatTime(String dateTimeStr) {
    return TimeUtils.formatUtcToIst12Hour(dateTimeStr);
  }

  /// Whether this retrieval request is assignable based on its status
  static bool isAssignable(String status) {
    final normalized = status.toUpperCase();
    return normalized == 'RETRIEVAL_REQUESTED';
  }

  /// Status-based color for the request card / status pill (no High/Medium/Low).
  static Color getStatusColor({
    required String status,
    required String waitingTime,
  }) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        return AppColors.orange;
      case 'ACCEPTED':
        return AppColors.blue;
      case 'ARRIVED':
        return AppColors.success;
      case 'RETRIEVAL_REQUESTED':
        return AppColors.primary;
      default:
        return AppColors.primary;
    }
  }

  /// Status label to show in UI (actual status from API, no High/Medium/Low).
  static String getStatusLabel({
    required String status,
    required String waitingTime,
  }) {
    switch (status.toUpperCase()) {
      case 'ASSIGNED':
        return 'Assigned';
      case 'ACCEPTED':
        return 'Accepted';
      case 'ARRIVED':
        return 'Arrived';
      case 'RETRIEVAL_REQUESTED':
        return 'Retrieval Requested';
      default:
        return status
            .split('_')
            .map((e) => e.isEmpty
                ? e
                : e[0].toUpperCase() + e.substring(1).toLowerCase())
            .join(' ');
    }
  }
}
