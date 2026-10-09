import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'retrival_request_event.dart';
import 'retrival_requesy_state.dart';
import 'package:niloufer_valet_mobile/api/driver/assigned_sessions_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/retrival_accept_api.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/location/location_service.dart';

class RetrivalRequestBloc
    extends Bloc<RetrivalRequestEvent, RetrivalRequestState> {
  RetrivalRequestBloc() : super(const RetrivalRequestInitial()) {
    on<FetchRetrivalRequests>(_onFetch);
    on<AcceptRetrivalRequest>(_onAccept);
    on<AcceptAllRetrivalRequests>(_onAcceptAll);
    on<UpdateAssignedSessions>(_onUpdateSessions);
  }

  Future<void> _onFetch(
    FetchRetrivalRequests event,
    Emitter<RetrivalRequestState> emit,
  ) async {
    emit(const RetrivalRequestLoading());
    try {
      final sessions = await AssignedSessionsApiService.fetchAssignedSessions();
      emit(RetrivalRequestLoaded(sessions));
    } catch (e) {
      final msg = getDisplayErrorMessage(e);
      emit(RetrivalRequestError(msg));
    }
  }

  void _onUpdateSessions(
    UpdateAssignedSessions event,
    Emitter<RetrivalRequestState> emit,
  ) {
    emit(RetrivalRequestLoaded(event.sessions));
  }

  static String _messageOf(Object e) {
    if (e is ApiException) return e.displayMessage;
    return getDisplayErrorMessage(e);
  }

  static bool _isAlreadyAcceptedCase(String raw) {
    final msg = raw.toUpperCase();
    final hasAssignedExpectation = msg.contains('EXPECTED ASSIGNED') ||
        (msg.contains('EXPECTED') && msg.contains('ASSIGNED'));
    final hasTerminalOrAcceptedStatus = msg.contains('ACCEPTED') ||
        msg.contains('RETRIEVING') ||
        msg.contains('ARRIVED');
    final hasAlreadyAcceptedPhrase = msg.contains('ALREADY ACCEPT');

    return (hasAssignedExpectation && hasTerminalOrAcceptedStatus) ||
        hasAlreadyAcceptedPhrase;
  }

  Future<({double lat, double lon, double acc})> _getLocationForAccept() async {
    LocationPermission permission = await LocationService.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await LocationService.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to accept session');
    }

    final coordinates = await LocationService.getCurrentCoordinates();
    final latitude = coordinates['latitude']!;
    final longitude = coordinates['longitude']!;
    final accuracy = coordinates['accuracy']!;

    if (latitude == 0.0 && longitude == 0.0) {
      throw Exception(
          'Invalid location. Please ensure GPS is enabled and try again.');
    }

    final location =
        '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
    await TokenStorage.saveCurrentLocation(
      latitude: latitude,
      longitude: longitude,
      location: location,
    );

    return (lat: latitude, lon: longitude, acc: accuracy);
  }

  Future<void> _onAccept(
    AcceptRetrivalRequest event,
    Emitter<RetrivalRequestState> emit,
  ) async {
    emit(const RetrivalRequestLoading());
    try {
      final loc = await _getLocationForAccept();

      print('[Accept Request] Session ID: ${event.sessionId}');
      print(
          '[Accept Request] Latitude: ${loc.lat}, Longitude: ${loc.lon}, Accuracy: ${loc.acc}');

      final response = await RetrievalAcceptApiService.acceptSession(
        sessionId: event.sessionId,
        latitude: loc.lat,
        longitude: loc.lon,
        accuracy: loc.acc,
      );
      emit(RetrivalRequestAccepted(
        response.message,
        acceptedIds: [event.sessionId],
      ));
    } catch (e) {
      final errorMsg = _messageOf(e);
      if (_isAlreadyAcceptedCase(errorMsg)) {
        print(
            '[Accept Request] Already accepted on backend, treating as success: $errorMsg');
        emit(RetrivalRequestAccepted(
          'Retrieval already accepted — continuing',
          acceptedIds: [event.sessionId],
        ));
      } else {
        print('❌ Accept API failed: $errorMsg');
        emit(RetrivalRequestError(errorMsg));
      }
    }
  }

  Future<void> _onAcceptAll(
    AcceptAllRetrivalRequests event,
    Emitter<RetrivalRequestState> emit,
  ) async {
    final raw = event.sessionIds
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    if (raw.isEmpty) {
      emit(const RetrivalRequestError('No retrieval sessions to accept'));
      return;
    }

    emit(const RetrivalRequestLoading());
    try {
      final loc = await _getLocationForAccept();
      final accepted = <String>[];

      for (final sessionId in raw) {
        try {
          final response = await RetrievalAcceptApiService.acceptSession(
            sessionId: sessionId,
            latitude: loc.lat,
            longitude: loc.lon,
            accuracy: loc.acc,
          );
          accepted.add(sessionId);
          print('[Accept All] OK $sessionId: ${response.message}');
        } catch (e) {
          final errorMsg = _messageOf(e);
          if (_isAlreadyAcceptedCase(errorMsg)) {
            accepted.add(sessionId);
            print('[Accept All] Skip duplicate state $sessionId');
          } else {
            emit(RetrivalRequestError(
              'Failed on session $sessionId: $errorMsg',
            ));
            return;
          }
        }
      }

      emit(RetrivalRequestAccepted(
        'Accepted ${accepted.length} retrieval request(s)',
        acceptedIds: accepted,
      ));
    } catch (e) {
      emit(RetrivalRequestError(_messageOf(e)));
    }
  }
}
