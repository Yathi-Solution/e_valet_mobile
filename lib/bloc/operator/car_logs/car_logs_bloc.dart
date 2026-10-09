import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:niloufer_valet_mobile/api/operator/car_logs/operator_car_logs_api_service.dart';
import 'package:niloufer_valet_mobile/api/operator/car_logs/operator_update_session_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/car_logs_kpis_response.dart';
import 'package:niloufer_valet_mobile/models/operator/operator_dashboard/car_logs_response.dart';
import 'car_logs_event.dart';
import 'car_logs_state.dart';

class CarLogsBloc extends Bloc<CarLogsEvent, CarLogsState> {
  String? _lastSearch;

  CarLogsBloc() : super(const CarLogsInitial()) {
    on<FetchCarLogs>(_onFetchCarLogs);
    on<UpdateCarLogStatus>(_onUpdateCarLogStatus);
  }

  Future<void> _onFetchCarLogs(
    FetchCarLogs event,
    Emitter<CarLogsState> emit,
  ) async {
    _lastSearch = event.search;
    emit(const CarLogsLoading());
    try {
      final results = await Future.wait([
        OperatorCarLogsApiService.getCarLogs(
          outletId: event.outletId,
          page: event.page,
          pageSize: event.pageSize,
          search: event.search,
        ),
        OperatorCarLogsApiService.getCarLogsKpis(outletId: event.outletId),
      ]);
      final carLogs = results[0] as CarLogsResponse;
      final kpis = results[1] as CarLogsKpisResponse;
      emit(CarLogsLoaded(carLogsResponse: carLogs, kpis: kpis));
    } catch (e) {
      emit(CarLogsError(getDisplayErrorMessage(e)));
    }
  }

  Future<void> _onUpdateCarLogStatus(
    UpdateCarLogStatus event,
    Emitter<CarLogsState> emit,
  ) async {
    try {
      await OperatorUpdateSessionApiService.updateSessionStatus(
        sessionId: event.sessionId,
        newStatus: event.newStatus,
      );

      // After successful update, refresh the car logs (preserve search)
      if (state is CarLogsLoaded) {
        final currentState = state as CarLogsLoaded;
        add(FetchCarLogs(
          outletId: dotenv.env['OUTLET_ID']!,
          page: currentState.carLogsResponse.page,
          pageSize: currentState.carLogsResponse.pageSize,
          search: _lastSearch,
        ));
      }
    } catch (e) {
      // For now, just print the error. You might want to emit an error state
      print('Error updating car log status: $e');
    }
  }
}
