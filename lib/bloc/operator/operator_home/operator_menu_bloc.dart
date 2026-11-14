import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/driver/driver_status_api_service.dart';
import 'package:evalet/api/oauth/logout_api_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/status/clock_out_request.dart';
import 'package:evalet/services/location/location_service.dart';
import 'package:evalet/services/oauth/session_manager.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'operator_menu_event.dart';
import 'operator_menu_state.dart';

class OperatorMenuBloc extends Bloc<OperatorMenuEvent, OperatorMenuState> {
  OperatorMenuBloc() : super(const OperatorMenuInitial()) {
    on<OperatorMenuLogoutRequested>(_onLogoutRequested);
  }

  /// Upper bound on the best-effort clock-out so it can never stall logout.
  static const Duration _clockOutTimeout = Duration(seconds: 5);

  /// True from the Logout tap until logout finishes; repeated taps are ignored.
  bool _logoutInProgress = false;

  Future<void> _onLogoutRequested(
    OperatorMenuLogoutRequested event,
    Emitter<OperatorMenuState> emit,
  ) async {
    if (_logoutInProgress) return;
    _logoutInProgress = true;
    emit(const OperatorMenuLogoutLoading());

    try {
      // Best-effort clock-out (fails gracefully if not clocked in or not
      // applicable). Bounded so a slow network or GPS fix cannot hold up logout.
      try {
        await _tryClockOutForOperator().timeout(_clockOutTimeout);
      } catch (e) {
        log('Operator clock-out skipped before logout: $e');
      }

      // LogoutApiService calls the server while the token is still valid and
      // then clears tokens and session flags, even when the API call fails.
      final response = await LogoutApiService.logout();
      emit(OperatorMenuLogoutSuccess(response.message));
    } on ApiException catch (e) {
      print(
          '🔵 OPERATOR LOGOUT ERROR: Logout API failed with ApiException: ${e.message}');
      await _clearLocalSession();
      emit(OperatorMenuLogoutFailure(e.message));
    } catch (e) {
      print(
          '🔵 OPERATOR LOGOUT ERROR: Logout API failed with unknown error: $e');
      await _clearLocalSession();
      emit(OperatorMenuLogoutFailure('Logout failed: ${getDisplayErrorMessage(e)}'));
    } finally {
      _logoutInProgress = false;
    }
  }

  /// Ensure local logout even if the logout flow threw before clearing.
  Future<void> _clearLocalSession() async {
    try {
      await TokenStorage.clearAll();
      await SessionManager.clearSessionFlags();
    } catch (e) {
      log('Failed to clear local session on operator logout: $e');
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
          // Fallback: quick fix (reuses last known position) if no stored location
          final coordinates = await LocationService.getFastCoordinates()
              .timeout(const Duration(seconds: 3));
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
