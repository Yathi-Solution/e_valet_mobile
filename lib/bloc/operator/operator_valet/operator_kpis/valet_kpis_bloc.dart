import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/api/operator/operator_valet/valet_kpis_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'valet_kpis_event.dart';
import 'valet_kpis_state.dart';

class ValetKpisBloc extends Bloc<ValetKpisEvent, ValetKpisState> {
  ValetKpisBloc() : super(const ValetKpisInitial()) {
    on<FetchValetKpis>(_onFetchValetKpis);
  }

  Future<void> _onFetchValetKpis(
    FetchValetKpis event,
    Emitter<ValetKpisState> emit,
  ) async {
    emit(const ValetKpisLoading());
    try {
      final kpis = await ValetKpisApiService.getValetKpis(
        outletId: event.outletId,
      );

      emit(ValetKpisLoaded(kpis: kpis));
    } catch (e) {
      emit(ValetKpisError(getDisplayErrorMessage(e)));
    }
  }
}
