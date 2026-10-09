import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/api/driver/driver_status_api_service.dart';
import 'package:niloufer_valet_mobile/api/oauth/logout_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/status/clock_out_request.dart';
import 'package:niloufer_valet_mobile/services/location/location_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'operator_menu_event.dart';
import 'operator_menu_state.dart';

class OperatorMenuBloc extends Bloc<OperatorMenuEvent, OperatorMenuState> {
  OperatorMenuBloc() : super(const OperatorMenuInitial()) {
    on<OperatorMenuLogoutRequested>(_onLogoutRequested);
  }

  Future<void> _onLogoutRequested(
    OperatorMenuLogoutRequested event,
    Emitter<OperatorMenuState> emit,
  ) async {
    // Try to clock out first (will fail gracefully if not clocked in or not applicable)
    await _tryClockOutForOperator();
    await TokenStorage.clearAll();
    await SessionManager.clearSessionFlags();

    try {
      final response = await LogoutApiService.logout();
      emit(OperatorMenuLogoutSuccess(response.message));
    } on ApiException catch (e) {
      print(
          '🔵 OPERATOR LOGOUT ERROR: Logout API failed with ApiException: ${e.message}');
      // Ensure local logout even if API fails

      emit(OperatorMenuLogoutFailure(e.message));
    } catch (e) {
      print(
          '🔵 OPERATOR LOGOUT ERROR: Logout API failed with unknown error: $e');
      // Ensure local logout even if API fails

      emit(OperatorMenuLogoutFailure('Logout failed: ${getDisplayErrorMessage(e)}'));
    }
  }

  /// Try to clock out if the user is clocked in (for valets/drivers).
  /// This will fail gracefully if not applicable.
  Future<void> _tryClockOutForOperator() async {
    try {
      // Get location - try stored location first, then current location
      double latitude;
      double longitude;
      double accuracy;

      try {
        var locationData = await TokenStorage.getCurrentLocation();
        if (locationData != null) {
          latitude = locationData['latitude'] as double;
          longitude = locationData['longitude'] as double;
          accuracy = locationData['accuracy'] as double? ?? 0.0;
        } else {
          // Fallback: Get current location if stored location not available
          final coordinates = await LocationService.getCurrentCoordinates();
          latitude = coordinates['latitude']!;
          longitude = coordinates['longitude']!;
          accuracy = coordinates['accuracy']!;
        }
      } catch (e) {
        log('Failed to get location for operator clock-out: $e');
        // If location fails, use default values (0, 0) - API might handle this
        latitude = 0.0;
        longitude = 0.0;
        accuracy = 0.0;
      }

      // Try to call clock-out API (will work for drivers/valets who are clocked in)
      final clockOutRequest = ClockOutRequest(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );

      await DriverStatusApiService.clockOut(clockOutRequest);
      log('Operator clock-out successful before logout');
    } catch (e) {
      print('🟡 OPERATOR CLOCK-OUT ERROR: Clock-out failed: $e');
      log('Failed to clock out operator before logout: $e');
      // Don't fail the logout if clock-out fails - this is expected for users not clocked in
    }
  }
}
