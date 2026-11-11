import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/api/oauth/logout_api_service.dart';
import 'package:evalet/bloc/scanner/scanner_menu/scanner_menu_event.dart';
import 'package:evalet/bloc/scanner/scanner_menu/scanner_menu_state.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/ui/common/text_constants.dart';

class ScannerMenuBloc extends Bloc<ScannerMenuEvent, ScannerMenuState> {
  ScannerMenuBloc() : super(const ScannerMenuInitial()) {
    on<ScannerLogoutPressed>(_onLogoutPressed);
    on<ScannerProfilePressed>((event, emit) {
      emit(const ScannerMenuAction(ScannerMenuActionType.profile));
    });
    on<ScannerMenuReset>((event, emit) {
      emit(const ScannerMenuInitial());
    });
  }

  Future<void> _onLogoutPressed(
    ScannerLogoutPressed event,
    Emitter<ScannerMenuState> emit,
  ) async {
    emit(const ScannerMenuLogoutLoading());
    try {
      final response = await LogoutApiService.logout();
      emit(ScannerMenuLogoutSuccess(response));
    } on ApiException catch (e) {
      emit(ScannerMenuLogoutFailure(e.message));
    } catch (e) {
      emit(const ScannerMenuLogoutFailure(TextConstants.genericError));
    }
  }
}
