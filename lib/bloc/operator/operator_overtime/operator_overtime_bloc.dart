import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_overtime/grant_overtime_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_valet/valet_list_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_overtime/grant_overtime_request.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_overtime/operator_overtime_event.dart';
import 'package:niloufer_valet_mobile/bloc/operator/operator_overtime/operator_overtime_state.dart';

class OperatorOvertimeBloc
    extends Bloc<OperatorOvertimeEvent, OperatorOvertimeState> {
  OperatorOvertimeBloc() : super(OperatorOvertimeInitial()) {
    on<OvertimeLoadValets>(_onLoadValets);
    on<OvertimeGrantRequested>(_onGrantOvertime);
  }

  Future<void> _onLoadValets(
    OvertimeLoadValets event,
    Emitter<OperatorOvertimeState> emit,
  ) async {
    emit(OperatorOvertimeLoading());
    try {
      final response =
          await ValetListApiService.getValets(outletId: event.outletId);
      emit(OperatorOvertimeLoaded(valets: response.valets));
    } catch (e) {
      emit(OperatorOvertimeLoadError(message: getDisplayErrorMessage(e)));
    }
  }

  Future<void> _onGrantOvertime(
    OvertimeGrantRequested event,
    Emitter<OperatorOvertimeState> emit,
  ) async {
    final currentState = state;
    if (currentState is! OperatorOvertimeLoaded) return;

    final valets = currentState.valets;
    final request = GrantOvertimeRequest(
      driverUserId: event.driverUserId,
      outletId: event.outletId,
      extraMinutes: event.extraMinutes,
      reason: 'Granted from operator app',
    );

    try {
      final res = await GrantOvertimeApiService.grantOvertime(request: request);
      final refreshedResponse = await ValetListApiService.getValets(
        outletId: event.outletId.toString(),
      );
      final refreshedValets = refreshedResponse.valets;
      final msg = (res.message?.trim().isNotEmpty ?? false)
          ? res.message!.trim()
          : 'Overtime granted';
      emit(OperatorOvertimeGrantSuccess(
        valets: refreshedValets,
        driverUserId: event.driverUserId,
        message: msg,
      ));
      emit(OperatorOvertimeLoaded(valets: refreshedValets));
    } catch (e) {
      emit(OperatorOvertimeGrantError(
        valets: valets,
        message: getDisplayErrorMessage(e),
      ));
      emit(OperatorOvertimeLoaded(valets: valets));
    }
  }
}
