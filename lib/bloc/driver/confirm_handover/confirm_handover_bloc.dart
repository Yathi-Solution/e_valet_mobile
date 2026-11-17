import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:evalet/api/driver/handover_api.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/services/location/location_service.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'confirm_handover_event.dart';
import 'confirm_handover_state.dart';

class ConfirmHandoverBloc
    extends Bloc<ConfirmHandoverEvent, ConfirmHandoverState> {
  ConfirmHandoverBloc() : super(const ConfirmHandoverInitial()) {
    on<ConfirmHandoverStarted>(_onStarted);
    on<ConfirmHandoverRequested>(_onConfirmHandover);
  }

  Future<void> _onStarted(
    ConfirmHandoverStarted event,
    Emitter<ConfirmHandoverState> emit,
  ) async {
    emit(const ConfirmHandoverInitial());
  }

  Future<void> _onConfirmHandover(
    ConfirmHandoverRequested event,
    Emitter<ConfirmHandoverState> emit,
  ) async {
    emit(const ConfirmHandoverLoading());

    try {
      // Always fetch fresh location with accuracy for handover API
      // Request permission if needed
      LocationPermission permission = await LocationService.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await LocationService.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw ApiException(
          TextConstants.locationPermissionRequiredHandover,
          code: 'location_permission_denied',
        );
      }

      // Driver has just moved the car: only reuse a fix from the last few
      // seconds, otherwise wait briefly for a fresh one.
      final coordinates = await LocationService.getFastCoordinates(
        maxAge: const Duration(seconds: 15),
      );
      final latitude = coordinates['latitude']!;
      final longitude = coordinates['longitude']!;
      final accuracy = coordinates['accuracy']!;

      // Validate location is not 0,0
      if (latitude == 0.0 && longitude == 0.0) {
        throw ApiException(
          'Invalid location. Please ensure GPS is enabled and try again.',
          code: 'invalid_location',
        );
      }

      // Save location for future use
      final location =
          '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      await TokenStorage.saveCurrentLocation(
        latitude: latitude,
        longitude: longitude,
        location: location,
      );

      // Call handover API
      final response = await HandoverApiService.confirmHandover(
        sessionId: event.sessionId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );

      emit(ConfirmHandoverSuccess(message: response.message));
    } on ApiException catch (e) {
      emit(ConfirmHandoverError(message: e.message));
    } catch (e) {
      emit(ConfirmHandoverError(
        message: TextConstants.genericError,
      ));
    }
  }
}
