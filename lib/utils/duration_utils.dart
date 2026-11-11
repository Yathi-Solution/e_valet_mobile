import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/text_constants.dart';

class DurationUtils {
  DurationUtils._();

  /// Splits a total minutes value into (hours, minutes) with minutes in 0..59.
  /// Negative values are clamped to 0.
  static ({int hours, int minutes}) splitToHoursMinutes(int totalMinutes) {
    final clamped = totalMinutes < 0 ? 0 : totalMinutes;
    return (hours: clamped ~/ 60, minutes: clamped % 60);
  }

  /// Formats a total minutes value into a human readable label like:
  /// - "2 hours 5 minutes"
  /// - "1 hour"
  /// - "15 minutes"
  ///
  /// Uses translations (with [TextConstants] fallbacks) for unit labels.
  static String formatHoursMinutes(
      AppTranslationsNotifier t, int totalMinutes) {
    final split = splitToHoursMinutes(totalMinutes);
    final hours = split.hours;
    final minutes = split.minutes;

    String hourLabel(int h) => h == 1
        ? t.getByKey('hourUnit', TextConstants.hourUnit)
        : t.getByKey('hoursUnit', TextConstants.hoursUnit);

    String minuteLabel(int m) => m == 1
        ? t.getByKey('minuteUnit', TextConstants.minuteUnit)
        : t.getByKey('minutesUnit', TextConstants.minutesUnit);

    if (hours > 0 && minutes > 0) {
      return '$hours ${hourLabel(hours)} $minutes ${minuteLabel(minutes)}';
    }
    if (hours > 0) {
      return '$hours ${hourLabel(hours)}';
    }
    return '$minutes ${minuteLabel(minutes)}';
  }

  /// Formats minutes into a compact label like "1h 05m" or "45m".
  /// Negative values are clamped to 0.
  static String formatCompactHoursMinutes(int totalMinutes) {
    final split = splitToHoursMinutes(totalMinutes);
    final hours = split.hours;
    final minutes = split.minutes;

    if (hours <= 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
}
