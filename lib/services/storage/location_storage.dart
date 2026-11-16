import 'package:evalet/services/storage/auth_box.dart';

/// Last known parking, arrival and current locations.
///
/// Stored in the shared [AuthBox].
class LocationStorage {
  static const String _parkingLocationKey = 'parking_location';
  static const String _arrivalLocationKey = 'arrival_location';
  static const String _arrivalLatitudeKey = 'arrival_latitude';
  static const String _arrivalLongitudeKey = 'arrival_longitude';
  static const String _currentLocationKey = 'current_location';
  static const String _currentLatitudeKey = 'current_latitude';
  static const String _currentLongitudeKey = 'current_longitude';

  // Parking Location management
  static Future<void> saveParkingLocation(String location) async {
    try {
      await AuthBox.box.put(_parkingLocationKey, location);
    } catch (e) {
      print('[LocationStorage] ❌ Error saving parking location: $e');
      rethrow;
    }
  }

  static Future<String?> getParkingLocation() async {
    try {
      return AuthBox.box.get(_parkingLocationKey) as String?;
    } catch (e) {
      print('[LocationStorage] ❌ Error retrieving parking location: $e');
      return null;
    }
  }

  static Future<void> clearParkingLocation() async {
    try {
      await AuthBox.box.delete(_parkingLocationKey);
    } catch (e) {
      print('[LocationStorage] ❌ Error clearing parking location: $e');
    }
  }

  // Arrival Location management
  static Future<void> saveArrivalLocation({
    required double latitude,
    required double longitude,
    required String location,
  }) async {
    try {
      await AuthBox.box.put(_arrivalLatitudeKey, latitude);
      await AuthBox.box.put(_arrivalLongitudeKey, longitude);
      await AuthBox.box.put(_arrivalLocationKey, location);
    } catch (e) {
      print('[LocationStorage] ❌ Error saving arrival location: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getArrivalLocation() async {
    try {
      final latitude = AuthBox.box.get(_arrivalLatitudeKey) as double?;
      final longitude = AuthBox.box.get(_arrivalLongitudeKey) as double?;
      final location = AuthBox.box.get(_arrivalLocationKey) as String?;

      if (latitude != null && longitude != null && location != null) {
        return {
          'latitude': latitude,
          'longitude': longitude,
          'location': location,
        };
      }
      return null;
    } catch (e) {
      print('[LocationStorage] ❌ Error retrieving arrival location: $e');
      return null;
    }
  }

  static Future<void> clearArrivalLocation() async {
    try {
      await AuthBox.box.delete(_arrivalLatitudeKey);
      await AuthBox.box.delete(_arrivalLongitudeKey);
      await AuthBox.box.delete(_arrivalLocationKey);
    } catch (e) {
      print('[LocationStorage] ❌ Error clearing arrival location: $e');
    }
  }

  // Current Location management (used for accept, arrived, handover APIs)
  static Future<void> saveCurrentLocation({
    required double latitude,
    required double longitude,
    required String location,
  }) async {
    try {
      await AuthBox.box.put(_currentLatitudeKey, latitude);
      await AuthBox.box.put(_currentLongitudeKey, longitude);
      await AuthBox.box.put(_currentLocationKey, location);
    } catch (e) {
      print('[LocationStorage] ❌ Error saving current location: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> getCurrentLocation() async {
    try {
      final latitude = AuthBox.box.get(_currentLatitudeKey) as double?;
      final longitude = AuthBox.box.get(_currentLongitudeKey) as double?;
      final location = AuthBox.box.get(_currentLocationKey) as String?;

      if (latitude != null && longitude != null && location != null) {
        return {
          'latitude': latitude,
          'longitude': longitude,
          'location': location,
        };
      }
      return null;
    } catch (e) {
      print('[LocationStorage] ❌ Error retrieving current location: $e');
      return null;
    }
  }

  static Future<void> clearCurrentLocation() async {
    try {
      await AuthBox.box.delete(_currentLatitudeKey);
      await AuthBox.box.delete(_currentLongitudeKey);
      await AuthBox.box.delete(_currentLocationKey);
    } catch (e) {
      print('[LocationStorage] ❌ Error clearing current location: $e');
    }
  }
}
