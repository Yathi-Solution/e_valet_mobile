import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/driver/session_api_service.dart';
import 'package:evalet/bloc/driver/tag_submission/tag_submission_event.dart';
import 'package:evalet/bloc/driver/tag_submission/tag_submission_state.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/session/checkin_request.dart';
import 'package:evalet/models/driver/session/offline_checkin_request.dart';
import 'package:evalet/services/background/background_sync_service.dart';
import 'package:evalet/services/offline_sync/offline_parking_service.dart';
import 'package:evalet/services/offline_sync/parked_card_availability_service.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/ui/common/text_constants.dart';

class TagSubmissionBloc extends Bloc<TagSubmissionEvent, TagSubmissionState> {
  TagSubmissionBloc() : super(const TagSubmissionInitial()) {
    on<QrCodeSubmitted>(_onQrCodeSubmitted);
    on<TagNumberSubmitted>(_onTagNumberSubmitted);
    on<TagSubmissionReset>(_onReset);
  }

  Future<void> _onQrCodeSubmitted(
    QrCodeSubmitted event,
    Emitter<TagSubmissionState> emit,
  ) async {
    final request = CheckinRequest(
      outletId: event.qrData.outletId,
      cardNumber: event.qrData.cardNumber,
      outletCode: event.qrData.outletCode,
    );
    await _submitCheckin(request, emit);
  }

  Future<void> _onTagNumberSubmitted(
    TagNumberSubmitted event,
    Emitter<TagSubmissionState> emit,
  ) async {
    final request = CheckinRequest(
      outletId: event.outletId,
      cardNumber: event.cardNumber,
    );
    await _submitCheckin(request, emit);
  }

  Future<void> _submitCheckin(
    CheckinRequest request,
    Emitter<TagSubmissionState> emit,
  ) async {
    if (!TokenStorage.isDriverAssignedCardsLoadedSync()) {
      emit(const TagSubmissionError(TextConstants.driverCardsLoading));
      return;
    }

    if (!TokenStorage.isDriverCardNumberAllowedSync(request.cardNumber)) {
      emit(TagSubmissionError(
        '${TextConstants.driverCardNotAssigned} Please contact Operator.',
      ));
      return;
    }

    emit(const TagSubmissionLoading());

    try {
      final response = await SessionApiService.checkin(request);

      if (response.sessionId.isNotEmpty) {
        await TokenStorage.saveSessionId(response.sessionId);
      }

      emit(TagSubmissionSuccess(response.message));
    } on ApiException catch (e) {
      if (e.code == 'session_expired') {
        emit(const TagSubmissionSessionExpired());
        return;
      }

      if (_shouldFallbackToOffline(e)) {
        await _saveOfflineAndEmitSuccess(request, emit);
        return;
      }

      if (_isDifferentOutletError(e)) {
        emit(const TagSubmissionError(TextConstants.driverCardDifferentOutlet));
        return;
      }

      emit(TagSubmissionError(e.message));
    } catch (e) {
      // Not a connectivity failure, so don't report it as "saved offline".
      debugPrint('Check-in failed: $e');
      emit(const TagSubmissionError(
        'Failed to check in. Please try again.',
      ));
    }
  }

  /// Only a real connectivity failure may be saved offline. Anything else
  /// (a server refusal, a bad response) must surface as an error rather than
  /// look like a successful check-in.
  bool _shouldFallbackToOffline(ApiException e) {
    return e.code == 'network_error' || e.code == 'timeout';
  }

  /// The server refused the card because it belongs to another outlet:
  /// 400 CARD_NOT_AT_OUTLET (Outlet Code mismatch) or the 403 raised when the
  /// card's outlet is not the one the driver is clocked in at.
  bool _isDifferentOutletError(ApiException e) {
    return e.code == 'CARD_NOT_AT_OUTLET' ||
        (e.statusCode == 403 &&
            e.message.toLowerCase().contains('not valid for your outlet'));
  }

  Future<void> _saveOfflineAndEmitSuccess(
    CheckinRequest request,
    Emitter<TagSubmissionState> emit,
  ) async {
    try {
      if (await ParkedCardAvailabilityService.isCardNumberAlreadyInUse(
        request.cardNumber,
      )) {
        emit(TagSubmissionError(TextConstants.tagSubmissionError));
        return;
      }

      final clientSessionId =
          'offline-${DateTime.now().millisecondsSinceEpoch}-${request.cardNumber}';
      final offlineCheckin = OfflineCheckinRequest(
        outletId: request.outletId,
        cardNumber: request.cardNumber,
        clientSessionId: clientSessionId,
        timestamp: DateTime.now().toIso8601String(),
        outletCode: request.outletCode,
      );

      await OfflineParkingService.savePendingCheckin(offlineCheckin);
      await TokenStorage.saveSessionId(clientSessionId);
      await BackgroundSyncService.triggerSync();

      emit(const TagSubmissionSuccess(
        'Saved offline. Will sync when connected.',
      ));
    } catch (dbError) {
      debugPrint('Failed to save offline check-in: $dbError');
      emit(const TagSubmissionError(
        'Failed to save check-in. Please try again.',
      ));
    }
  }

  void _onReset(
    TagSubmissionReset event,
    Emitter<TagSubmissionState> emit,
  ) {
    emit(const TagSubmissionInitial());
  }
}
