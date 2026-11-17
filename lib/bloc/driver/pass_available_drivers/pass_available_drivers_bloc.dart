import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/driver/pass_available_drivers_api_service.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'pass_available_drivers_event.dart';
import 'pass_available_drivers_state.dart';

/// Backend often returns "no available drivers ..." for pass attempts.
/// We convert that to a clear instruction for the user.
const String kNoAvailableDriversCollectKeysMessage =
    'No available drivers. You need to collect the keys.';

String _rawMessageFromError(Object e) {
  if (e is ApiException) return e.message;
  final s = e is Exception ? e.toString() : 'Unknown error';
  if (s.startsWith('Exception: ')) return s.substring('Exception: '.length);
  return s;
}

String _userMessageForPassFailure(Object e) {
  final raw = _rawMessageFromError(e).trim();
  if (raw.isEmpty) return 'Something went wrong. Please try again.';

  final lower = raw.toLowerCase();
  final noDriversHint = lower.contains('no available drivers') ||
      lower.contains('no drivers') ||
      (lower.contains('no driver') && lower.contains('pass')) ||
      (lower.contains('not available') && lower.contains('driver'));

  if (noDriversHint) return kNoAvailableDriversCollectKeysMessage;
  return raw;
}

class PassAvailableDriversBloc
    extends Bloc<PassAvailableDriversEvent, PassAvailableDriversState> {
  PassAvailableDriversBloc() : super(const PassAvailableDriversInitial()) {
    on<FetchPassAvailableDrivers>(_onFetch);
    on<PassSessionToDriver>(_onPass);
  }

  Future<void> _onFetch(
    FetchPassAvailableDrivers event,
    Emitter<PassAvailableDriversState> emit,
  ) async {
    emit(const PassAvailableDriversLoading());
    try {
      final drivers = await PassAvailableDriversApiService.getAvailableDrivers(
        sessionId: event.sessionId,
      );
      emit(PassAvailableDriversLoaded(drivers));
    } catch (e) {
      print('[PASS BLOC] Fetch drivers error: $e');
      final msg = _rawMessageFromError(e);
      emit(PassAvailableDriversError(msg));
    }
  }

  Future<void> _onPass(
    PassSessionToDriver event,
    Emitter<PassAvailableDriversState> emit,
  ) async {
    emit(const PassingSessionToDriver(drivers: []));

    try {
      final message = await PassAvailableDriversApiService.passSessionToDriver(
        sessionId: event.sessionId,
      );
      emit(SessionPassedToDriver(message));
    } catch (e) {
      print('[PASS BLOC] Pass error: $e');
      final msg = _userMessageForPassFailure(e);
      emit(const PassAvailableDriversLoaded([]));
      emit(PassToDriverError(message: msg, drivers: const []));
    }
  }
}
