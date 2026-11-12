import 'package:geolocator/geolocator.dart';
import 'package:evalet/models/core/api_exceptions.dart';

class LocationService {
  LocationService._();

  /// Check if location services are enabled
  static Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  /// Check location permission status
  static Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  /// Request location permission
  static Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  /// Open location settings (Android only)
  static Future<bool> openLocationSettings() async {
    return await Geolocator.openLocationSettings();
  }

  /// Open app settings (for permissions)
  static Future<bool> openAppSettings() async {
    return await Geolocator.openAppSettings();
  }

  /// Throws an [ApiException] unless location services are on and the app
  /// has location permission (prompting the user where possible).
  static Future<void> _ensureServiceAndPermission() async {
    // Check if location services are enabled
    bool serviceEnabled = await isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Try to open location settings to help user enable it
      final opened = await openLocationSettings();
      if (opened) {
        // Wait a moment for user to potentially enable location
        await Future.delayed(const Duration(seconds: 1));
        // Check again
        serviceEnabled = await isLocationServiceEnabled();
        if (!serviceEnabled) {
          throw ApiException(
            'Location services are disabled. Please enable location services in your device settings and try again.',
            code: 'location_disabled',
          );
        }
      } else {
        throw ApiException(
          'Location services are disabled. Please enable location services in your device settings.',
          code: 'location_disabled',
        );
      }
    }

    // Check location permission
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await requestPermission();
      if (permission == LocationPermission.denied) {
        throw ApiException(
          'Location permissions are denied. Please grant location permission to update your status.',
          code: 'location_permission_denied',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Try to open app settings
      await openAppSettings();
      throw ApiException(
        'Location permissions are permanently denied. Please enable them in app settings to update your status.',
        code: 'location_permission_denied_forever',
      );
    }
  }

  /// Get current location with latitude and longitude
  static Future<Position> getCurrentLocation() async {
    await _ensureServiceAndPermission();

    // Get current position - try high accuracy first, then fallback to lower accuracy
    try {
      // First attempt: Try high accuracy with shorter timeout
      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 10),
        );
      } catch (e) {
        // If high accuracy fails, try with lower accuracy (network location)
        // This is useful when GPS signal is weak but network location is available
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
      }
    } catch (e) {
      if (e is ApiException) {
        rethrow;
      }
      // Check if it's a timeout or location unavailable error
      final errorString = e.toString().toLowerCase();
      if (errorString.contains('timeout') ||
          errorString.contains('location unavailable') ||
          errorString.contains('location service')) {
        throw ApiException(
          'Unable to get location. Please ensure location services are enabled and try again. If GPS is available, ensure you have a clear view of the sky.',
          code: 'location_timeout',
        );
      }
      throw ApiException(
        'Failed to get current location. Please check your location settings and try again.',
        code: 'location_error',
      );
    }
  }

  /// Get current location coordinates (latitude, longitude, and accuracy)
  static Future<Map<String, double>> getCurrentCoordinates() async {
    final position = await getCurrentLocation();
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'accuracy': position.accuracy,
    };
  }

  /// Faster variant for flows where the user is waiting on a button (e.g. park
  /// submit). Reuses the device's last known position when it is newer than
  /// [maxAge]; otherwise waits at most [freshTimeout] for a fresh fix and falls
  /// back to the last known position of any age before giving up.
  static Future<Map<String, double>> getFastCoordinates({
    Duration maxAge = const Duration(minutes: 2),
    Duration freshTimeout = const Duration(seconds: 4),
  }) async {
    await _ensureServiceAndPermission();

    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {
      lastKnown = null;
    }

    if (lastKnown != null &&
        DateTime.now().difference(lastKnown.timestamp).abs() <= maxAge) {
      return _toCoordinates(lastKnown);
    }

    try {
      final fresh = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: freshTimeout,
      );
      return _toCoordinates(fresh);
    } catch (_) {
      // Weak GPS (e.g. basement parking): an older fix beats making the user wait.
      if (lastKnown != null) return _toCoordinates(lastKnown);
    }

    try {
      final coarse = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: freshTimeout,
      );
      return _toCoordinates(coarse);
    } catch (_) {
      throw ApiException(
        'Unable to get location. Please ensure location services are enabled and try again.',
        code: 'location_timeout',
      );
    }
  }

  static Map<String, double> _toCoordinates(Position position) => {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
      };

  /// Get address from coordinates (placeholder - can be enhanced with reverse geocoding)
  /// For now, returns a formatted string with coordinates
  static String getAddressFromCoordinates(double latitude, double longitude) {
    // TODO: Implement reverse geocoding if needed
    // For now, return a formatted string
    return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
  }
}
