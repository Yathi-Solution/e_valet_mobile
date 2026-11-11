import 'package:evalet/models/operator/operator_dashboard/car_logs_kpis_response.dart';
import 'package:evalet/models/operator/operator_dashboard/car_logs_response.dart';

abstract class CarLogsState {
  const CarLogsState();
}

class CarLogsInitial extends CarLogsState {
  const CarLogsInitial();
}

class CarLogsLoading extends CarLogsState {
  const CarLogsLoading();
}

class CarLogsLoaded extends CarLogsState {
  final CarLogsResponse carLogsResponse;
  final CarLogsKpisResponse? kpis;

  const CarLogsLoaded({
    required this.carLogsResponse,
    this.kpis,
  });

  List<Object?> get props => [carLogsResponse, kpis];
}

class CarLogsError extends CarLogsState {
  final String message;

  const CarLogsError(this.message);

  List<Object> get props => [message];
}
