import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/api/driver/pre_break_info_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/my_cards_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/driver_status_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/my_parked_sessions_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/sessions_pending_api.dart';
import 'package:niloufer_valet_mobile/api/oauth/logout_api_service.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_state.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/parked/my_parked_sessions_response.dart';
import 'package:niloufer_valet_mobile/models/driver/status/clock_out_request.dart';
import 'package:niloufer_valet_mobile/services/location/location_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';

class DriverMenuBloc extends Bloc<DriverMenuEvent, DriverMenuState> {
  DriverMenuBloc() : super(const DriverMenuInitial()) {
    on<DriverLogoutPressed>(_onLogoutPressed);
    on<DriverProfilePressed>((event, emit) {
      emit(const DriverMenuAction(DriverMenuActionType.profile));
    });
    on<DriverGuidelinesPressed>((event, emit) {
      emit(const DriverMenuAction(DriverMenuActionType.guidelines));
    });
    on<DriverHelpPressed>((event, emit) {
      emit(const DriverMenuAction(DriverMenuActionType.help));
    });
    on<DriverMenuReset>((event, emit) {
      emit(const DriverMenuInitial());
    });
    on<DriverHomeStarted>(_onDriverHomeStarted);
    on<DriverPendingSessionsRefresh>(_onPendingSessionsRefresh);
    on<DriverOnBreakToggled>(_onOnBreakToggled);
    on<DriverOnlineStatusToggled>(_onOnlineStatusToggled);
  }

  Future<void> _onLogoutPressed(
    DriverLogoutPressed event,
    Emitter<DriverMenuState> emit,
  ) async {
    emit(const DriverMenuLogoutPrecheckLoading());
    try {
      final preBreakInfo = await PreBreakInfoApiService.getPreBreakInfo();
      if (preBreakInfo.hasBlockingData) {
        emit(DriverMenuLogoutBlockedByPendingWork(preBreakInfo));
        return;
      }
    } on ApiException catch (e) {
      emit(DriverMenuLogoutFailure(e.message));
      return;
    } catch (e) {
      emit(const DriverMenuLogoutFailure(
        'Unable to validate pending assignments. Please try again.',
      ));
      return;
    }

    emit(const DriverMenuLogoutLoading());

    // Automatically clock out (go offline) in background before logout
    await _clockOutBeforeLogout();

    try {
      final response = await LogoutApiService.logout();
      emit(DriverMenuLogoutSuccess(response));
    } on ApiException catch (e) {
      print(
          '🔵 DRIVER LOGOUT ERROR: Logout API failed with ApiException: ${e.message}');
      emit(DriverMenuLogoutFailure(e.message));
    } catch (e) {
      print('🔵 DRIVER LOGOUT ERROR: Logout API failed with unknown error: $e');
      emit(DriverMenuLogoutFailure(
        TextConstants.genericError,
      ));
    }
  }

  /// Automatically clock out (go offline) before logout
  /// This runs in the background and doesn't block the logout flow
  Future<void> _clockOutBeforeLogout() async {
    try {
      log('Starting automatic clock-out before logout...');

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
          log('Using stored location for clock-out');
        } else {
          // Fallback: Get current location if stored location not available
          final coordinates = await LocationService.getCurrentCoordinates();
          latitude = coordinates['latitude']!;
          longitude = coordinates['longitude']!;
          accuracy = coordinates['accuracy']!;
          log('Using current location for clock-out');
        }
      } catch (e) {
        log('Failed to get location for clock-out: $e');
        // If location fails, use default values (0, 0) - API might handle this
        latitude = 0.0;
        longitude = 0.0;
        accuracy = 0.0;
        log('Using default location (0, 0) for clock-out');
      }

      // Call clock-out API
      final clockOutRequest = ClockOutRequest(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );

      await DriverStatusApiService.clockOut(clockOutRequest);
      log('Automatic clock-out successful before logout');
    } catch (e) {
      log('Failed to clock out automatically before logout: $e');
      // Don't fail the logout if clock-out fails - this is a background operation
    }
  }

  Future<MyParkedSessionsResponse?> _fetchParkedCarsData({
    MyParkedSessionsResponse? prefetched,
  }) async {
    try {
      return await MyParkedSessionsApiService.loadParkedSessionsForDisplay(
        prefetched: prefetched,
      );
    } catch (_) {
      return prefetched ??
          await MyParkedSessionsApiService.getCachedParkedSessions();
    }
  }

  Future<void> _onDriverHomeStarted(
    DriverHomeStarted event,
    Emitter<DriverMenuState> emit,
  ) async {
    unawaited(MyCardsApiService.refreshAssignedCardsInBackground());

    final firstName = await TokenStorage.getFirstName() ?? '';
    final driverName =
        firstName.isNotEmpty ? firstName : TextConstants.driverFallbackName;

    final parkedCarsData = await _fetchParkedCarsData();
    final parkedCarsCount = parkedCarsData?.sessionCount ?? 0;

    // Fetch pending sessions
    try {
      final pendingSessions =
          await SessionsPendingApiService.getPendingSessions();
      emit(DriverHomeLoaded(
        driverName: driverName,
        isOnBreak: false,
        isOnline: true,
        pendingSessions: pendingSessions,
        parkedCarsCount: parkedCarsCount,
        parkedCarsData: parkedCarsData,
      ));
    } catch (e) {
      // If API call fails, still emit loaded state without pending sessions
      // This allows the screen to load even if the API fails
      emit(DriverHomeLoaded(
        driverName: driverName,
        isOnBreak: false,
        isOnline: true,
        parkedCarsCount: parkedCarsCount,
        parkedCarsData: parkedCarsData,
      ));
    }
  }

  Future<void> _onPendingSessionsRefresh(
    DriverPendingSessionsRefresh event,
    Emitter<DriverMenuState> emit,
  ) async {
    if (state is! DriverHomeLoaded) {
      add(const DriverHomeStarted());
      return;
    }

    final currentState = state as DriverHomeLoaded;
    final parkedCarsData = await _fetchParkedCarsData(
      prefetched: currentState.parkedCarsData,
    );
    final parkedCarsCount = parkedCarsData?.sessionCount ?? 0;
    try {
      final pendingSessions =
          await SessionsPendingApiService.getPendingSessions();
      emit(currentState.copyWith(
        pendingSessions: pendingSessions,
        parkedCarsCount: parkedCarsCount,
        parkedCarsData: parkedCarsData,
      ));
    } catch (e) {
      // Keep existing pending sessions if refresh fails; still update parked data
      emit(currentState.copyWith(
        parkedCarsCount: parkedCarsCount,
        parkedCarsData: parkedCarsData,
      ));
    }
  }

  void _onOnBreakToggled(
    DriverOnBreakToggled event,
    Emitter<DriverMenuState> emit,
  ) {
    if (state is DriverHomeLoaded) {
      final currentState = state as DriverHomeLoaded;
      emit(currentState.copyWith(isOnBreak: event.isOnBreak));
    }
  }

  void _onOnlineStatusToggled(
    DriverOnlineStatusToggled event,
    Emitter<DriverMenuState> emit,
  ) {
    if (state is DriverHomeLoaded) {
      final currentState = state as DriverHomeLoaded;
      emit(currentState.copyWith(isOnline: event.isOnline));
    }
  }
}
