import 'dart:async';
import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:niloufer_valet_mobile/api/driver/config_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/driver_status_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/my_cards_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/my_parked_sessions_api_service.dart';
import 'package:niloufer_valet_mobile/api/outlet/outlet_api_service.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/oauth/login/outlet_location_retry_state.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/status/clock_in_request.dart';
import 'package:niloufer_valet_mobile/models/oauth/profile.dart';
import 'package:niloufer_valet_mobile/models/outlet/outlet.dart';
import 'package:niloufer_valet_mobile/models/outlet/verify_location_request.dart';
import 'package:niloufer_valet_mobile/models/outlet/verify_location_response.dart';
import 'package:niloufer_valet_mobile/services/location/location_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/connectivity/driver_connectivity_log_service.dart';
import 'package:niloufer_valet_mobile/services/websocket/websocket_helper.dart';

class OutletLocationRetryCubit extends Cubit<OutletLocationRetryState> {
  final WebSocketBloc? webSocketBloc;
  String _displayMessage;

  OutletLocationRetryCubit({
    required String initialMessage,
    this.webSocketBloc,
  })  : _displayMessage = initialMessage,
        super(OutletLocationRetryIdle(initialMessage));

  void acknowledgeTransientFailure() {
    final s = state;
    if (s is OutletLocationRetryTransientFailure) {
      _displayMessage = s.resumeDisplayMessage;
      emit(OutletLocationRetryIdle(_displayMessage));
    }
  }

  Future<void> retryDriverClockIn({
    required Profile profile,
    required Outlet outlet,
  }) async {
    emit(OutletLocationRetryBusy(_displayMessage));

    double latitude;
    double longitude;
    double accuracy;

    try {
      await TokenStorage.clearCurrentLocation();
      final coordinates = await LocationService.getCurrentCoordinates();
      latitude = coordinates['latitude']!;
      longitude = coordinates['longitude']!;
      accuracy = coordinates['accuracy']!;

      final location =
          '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      await TokenStorage.saveCurrentLocation(
        latitude: latitude,
        longitude: longitude,
        location: location,
      );
    } catch (e) {
      log('Retry driver clock-in: failed to get location: $e');
      emit(OutletLocationRetryTransientFailure(
        notification: 'Could not read your location. Please try again.',
        resumeDisplayMessage: _displayMessage,
      ));
      return;
    }

    try {
      final clockInRequest = ClockInRequest(
        outletId: outlet.id,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
      final clockInResponse =
          await DriverStatusApiService.clockIn(clockInRequest);
      await DriverConnectivityLogService.instance.onShiftActiveAfterClockIn(
        shiftId: clockInResponse.shiftId,
        outletId: clockInResponse.outletId,
      );
    } on ApiException catch (e) {
      log('Retry driver clock-in failed: ${e.message}');
      if (_isLocationTooFarMessage(e.message)) {
        await TokenStorage.clearCurrentLocation();
        _displayMessage = e.message;
        emit(OutletLocationRetryIdle(_displayMessage));
        return;
      }
      emit(OutletLocationRetryTransientFailure(
        notification: e.message,
        resumeDisplayMessage: _displayMessage,
      ));
      return;
    } catch (e) {
      log('Retry driver clock-in failed: $e');
      emit(OutletLocationRetryTransientFailure(
        notification: 'Clock-in failed. Please try again.',
        resumeDisplayMessage: _displayMessage,
      ));
      return;
    }

    final userId = profile.user.id;

    await TokenStorage.saveSelectedOutlet(
      outletId: outlet.id,
      outletName: outlet.name,
    );
    dotenv.env['OUTLET_ID'] = outlet.id.toString();

    try {
      if (webSocketBloc != null) {
        await WebSocketHelper.connectAfterLogin(
          webSocketBloc: webSocketBloc!,
          outletId: null,
          operatorId: null,
          driverId: userId,
          initialDelay: const Duration(milliseconds: 500),
        );
      }
    } catch (e) {
      log('Retry driver: WebSocket connect failed: $e');
    }

    await _fetchAndStoreConfig();

    // Fetch assigned cards in the background for local scan validation.
    unawaited(MyCardsApiService.refreshAssignedCardsInBackground());

    try {
      final parkedResponse =
          await MyParkedSessionsApiService.refreshParkedSessionsForDisplay();
      log(
        'Driver parked cars refreshed on clock-in retry success: ${parkedResponse.sessionCount} sessions',
      );
    } catch (e) {
      log('Failed to refresh parked cars on clock-in retry (non-fatal): $e');
    }

    emit(OutletLocationRetrySuccess(_displayMessage, profile: profile));
  }

  Future<void> retryOutletVerify({
    required Profile profile,
    required int outletId,
  }) async {
    emit(OutletLocationRetryBusy(_displayMessage));

    double latitude;
    double longitude;
    double accuracy;

    try {
      await TokenStorage.clearCurrentLocation();
      final coordinates = await LocationService.getCurrentCoordinates();
      latitude = coordinates['latitude']!;
      longitude = coordinates['longitude']!;
      accuracy = coordinates['accuracy']!;

      final location =
          '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      await TokenStorage.saveCurrentLocation(
        latitude: latitude,
        longitude: longitude,
        location: location,
      );
    } catch (e) {
      log('Retry verify-location: failed to get location: $e');
      emit(OutletLocationRetryTransientFailure(
        notification: 'Could not read your location. Please try again.',
        resumeDisplayMessage: _displayMessage,
      ));
      return;
    }

    late final VerifyLocationResponse verifyResponse;
    try {
      verifyResponse = await OutletApiService.verifyLocation(
        outletId,
        VerifyLocationRequest(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
        ),
      );
    } on ApiException catch (e) {
      log('Retry verify-location ApiException: ${e.message}');
      if (_isLocationTooFarMessage(e.message)) {
        await TokenStorage.clearCurrentLocation();
        _displayMessage = e.message;
        emit(OutletLocationRetryIdle(_displayMessage));
        return;
      }
      emit(OutletLocationRetryTransientFailure(
        notification: e.message,
        resumeDisplayMessage: _displayMessage,
      ));
      return;
    } catch (e) {
      log('Retry verify-location failed: $e');
      emit(OutletLocationRetryTransientFailure(
        notification: 'Location check failed. Please try again.',
        resumeDisplayMessage: _displayMessage,
      ));
      return;
    }

    if (!verifyResponse.withinBounds) {
      await TokenStorage.clearCurrentLocation();
      _displayMessage = _userFacingVerifyFailure(verifyResponse);
      emit(OutletLocationRetryIdle(_displayMessage));
      return;
    }

    await _fetchAndStoreConfig();
    emit(OutletLocationRetrySuccess(_displayMessage, profile: profile));
  }

  String _userFacingVerifyFailure(VerifyLocationResponse verifyResponse) {
    final outletName = verifyResponse.outletName;
    final distanceMeters = verifyResponse.distanceMeters;
    final allowedRadiusMeters = verifyResponse.allowedRadiusMeters;

    String fmt(double m) => m >= 1000
        ? '${(m / 1000).toStringAsFixed(1)} km'
        : '${m.toStringAsFixed(0)} m';

    final buf = StringBuffer();
    if (outletName.isNotEmpty) {
      buf.write('Outlet: $outletName');
    }
    if (distanceMeters > 0 || allowedRadiusMeters > 0) {
      if (buf.isNotEmpty) buf.write('\n\n');
      buf.write('Your distance: ${fmt(distanceMeters)}\n');
      buf.write('Allowed radius: ${fmt(allowedRadiusMeters)}');
    }
    final s = buf.toString();
    if (s.isEmpty) {
      return 'You are outside the allowed area for this outlet.';
    }
    return s;
  }

  Future<void> _fetchAndStoreConfig() async {
    try {
      final config = await ConfigApiService.getConfig();
      await TokenStorage.saveButtonConfig(
        confirmArrivalDisableSeconds: config.confirmArrivalDisableSeconds,
        customerMissingDisableSeconds: config.customerMissingDisableSeconds,
        confirmHandoverDisableSeconds: config.confirmHandoverDisableSeconds,
        scannerButtonStatus: config.scannerButtonStatus,
        imageCompressionQuality: config.imageCompressionQuality,
        imageCompressionMaxSizeKB: config.imageCompressionMaxSizeKB,
      );
    } catch (e) {
      log('OutletLocationRetryCubit: Failed to fetch config: $e');
    }
  }

  bool _isLocationTooFarMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('too far') ||
        (lower.contains('distance') && lower.contains('allowed'));
  }
}
