import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/services/storage/auth_box.dart';

/// Server-provided app config: button cooldown lengths, scanner button status and image compression limits.
///
/// Stored in the shared [AuthBox].
class AppConfigStorage {
  static const String _confirmArrivalDisableSecondsKey =
      'confirm_arrival_disable_seconds';
  static const String _customerMissingDisableSecondsKey =
      'customer_missing_disable_seconds';
  static const String _confirmHandoverDisableSecondsKey =
      'confirm_handover_disable_seconds';
  static const String _scannerButtonStatusKey = 'scanner_button_status';
  static const String _imageCompressionQualityKey = 'image_compression_quality';
  static const String _imageCompressionMaxSizeKbKey =
      'image_compression_max_size_kb';

  // Button config management
  static Future<void> saveButtonConfig({
    required int confirmArrivalDisableSeconds,
    required int customerMissingDisableSeconds,
    required int confirmHandoverDisableSeconds,
    required bool scannerButtonStatus,
    required int imageCompressionQuality,
    required int imageCompressionMaxSizeKB,
  }) async {
    try {
      await AuthBox.box
          .put(_confirmArrivalDisableSecondsKey, confirmArrivalDisableSeconds);
      await AuthBox.box.put(
          _customerMissingDisableSecondsKey, customerMissingDisableSeconds);
      await AuthBox.box.put(
          _confirmHandoverDisableSecondsKey, confirmHandoverDisableSeconds);
      await AuthBox.box.put(_scannerButtonStatusKey, scannerButtonStatus);
      await AuthBox.box
          .put(_imageCompressionQualityKey, imageCompressionQuality);
      await AuthBox.box
          .put(_imageCompressionMaxSizeKbKey, imageCompressionMaxSizeKB);
    } catch (e) {
      print('[AppConfigStorage] ❌ Error saving button config: $e');
      rethrow;
    }
  }

  static Future<int?> getConfirmArrivalDisableSeconds() async {
    try {
      final value = AuthBox.box.get(_confirmArrivalDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print('[AppConfigStorage] ❌ Error reading confirm arrival config: $e');
      return null;
    }
  }

  static int? getConfirmArrivalDisableSecondsSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return null;
      final value =
          Hive.box(AuthBox.name).get(_confirmArrivalDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getCustomerMissingDisableSeconds() async {
    try {
      final value = AuthBox.box.get(_customerMissingDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print('[AppConfigStorage] ❌ Error reading customer missing config: $e');
      return null;
    }
  }

  static int? getCustomerMissingDisableSecondsSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return null;
      final value =
          Hive.box(AuthBox.name).get(_customerMissingDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getConfirmHandoverDisableSeconds() async {
    try {
      final value = AuthBox.box.get(_confirmHandoverDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print('[AppConfigStorage] ❌ Error reading confirm handover config: $e');
      return null;
    }
  }

  static int? getConfirmHandoverDisableSecondsSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return null;
      final value =
          Hive.box(AuthBox.name).get(_confirmHandoverDisableSecondsKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  static Future<bool?> getScannerButtonStatus() async {
    try {
      final value = AuthBox.box.get(_scannerButtonStatusKey);
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return null;
    } catch (e) {
      print('[AppConfigStorage] ❌ Error reading scanner button status: $e');
      return null;
    }
  }

  static bool? getScannerButtonStatusSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return null;
      final value = Hive.box(AuthBox.name).get(_scannerButtonStatusKey);
      if (value is bool) return value;
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') return true;
        if (normalized == 'false') return false;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<int?> getImageCompressionQuality() async {
    try {
      final value = AuthBox.box.get(_imageCompressionQualityKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print('[AppConfigStorage] ❌ Error reading image compression quality: $e');
      return null;
    }
  }

  static Future<int?> getImageCompressionMaxSizeKB() async {
    try {
      final value = AuthBox.box.get(_imageCompressionMaxSizeKbKey);
      if (value is int) return value;
      return int.tryParse(value?.toString() ?? '');
    } catch (e) {
      print(
          '[AppConfigStorage] ❌ Error reading image compression max size: $e');
      return null;
    }
  }

  /// Removes the stored config. Called on logout.
  static Future<void> clear() async {
    await AuthBox.box.delete(_confirmArrivalDisableSecondsKey);
    await AuthBox.box.delete(_customerMissingDisableSecondsKey);
    await AuthBox.box.delete(_confirmHandoverDisableSecondsKey);
    await AuthBox.box.delete(_scannerButtonStatusKey);
    await AuthBox.box.delete(_imageCompressionQualityKey);
    await AuthBox.box.delete(_imageCompressionMaxSizeKbKey);
  }
}
