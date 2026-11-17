import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/driver/initiate_repark_api_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/re-park/initiate_repark_request.dart';
import 'initiate_repark_event.dart';
import 'initiate_repark_state.dart';

class InitiateReparkBloc
    extends Bloc<InitiateReparkEvent, InitiateReparkState> {
  InitiateReparkBloc() : super(const InitiateReparkInitial()) {
    on<InitiateReparkRequested>(_onInitiateReparkRequested);
  }

  Future<void> _onInitiateReparkRequested(
    InitiateReparkRequested event,
    Emitter<InitiateReparkState> emit,
  ) async {
    // Guard: ignore duplicate requests when already loading or succeeded
    if (state is InitiateReparkLoading || state is InitiateReparkSuccess) {
      return;
    }
    emit(const InitiateReparkLoading());

    try {
      final request = InitiateReparkRequest(
        latitude: event.latitude,
        longitude: event.longitude,
        accuracy: event.accuracy,
      );

      final response = await InitiateReparkApiService.initiateRepark(
        sessionId: event.sessionId,
        request: request,
      );

      emit(InitiateReparkSuccess(response: response));
    } on ApiException catch (e) {
      emit(InitiateReparkError(message: e.message));
    } catch (e) {
      emit(InitiateReparkError(
        message: 'Failed to initiate repark. Please try again.',
      ));
    }
  }
}
