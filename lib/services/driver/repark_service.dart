import 'package:geolocator/geolocator.dart';
import 'package:evalet/api/driver/initiate_repark_api_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/re-park/initiate_repark_request.dart';
import 'package:evalet/models/driver/re-park/initiate_repark_response.dart';
import 'package:evalet/services/location/location_service.dart';

/// Starts a re-park when the customer does not turn up.
class ReparkService {
  /// Reads the driver's location (asking for permission if needed) and tells
  /// the server to start a re-park for [sessionId].
  ///
  /// Throws [ApiException] when location permission is refused or the server
  /// rejects the request.
  static Future<InitiateReparkResponse> initiateFromCurrentLocation(
    String sessionId,
  ) async {
    LocationPermission permission = await LocationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await LocationService.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw ApiException(
        'Location permission is required to initiate repark.',
        code: 'location_permission_denied',
      );
    }

    final coordinates = await LocationService.getFastCoordinates();

    final request = InitiateReparkRequest(
      latitude: coordinates['latitude']!,
      longitude: coordinates['longitude']!,
      accuracy: coordinates['accuracy']!,
    );

    return InitiateReparkApiService.initiateRepark(
      sessionId: sessionId,
      request: request,
    );
  }
}
