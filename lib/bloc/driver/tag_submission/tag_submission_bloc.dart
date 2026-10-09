import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/api/driver/session_api_service.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/tag_submission/tag_submission_state.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/session/checkin_request.dart';
import 'package:niloufer_valet_mobile/models/driver/session/offline_checkin_request.dart';
import 'package:niloufer_valet_mobile/services/background/background_sync_service.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/parked_card_availability_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';

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

      emit(TagSubmissionError(e.message));
    } catch (e) {
      debugPrint('Check-in failed, falling back to offline storage: $e');
      await _saveOfflineAndEmitSuccess(request, emit);
    }
  }

  bool _shouldFallbackToOffline(ApiException e) {
    return e.code == 'network_error' ||
        e.code == 'timeout' ||
        e.code == 'unknown_error';
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
