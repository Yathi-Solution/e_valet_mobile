import 'package:evalet/models/operator/operator_valet/valet_kpis_response.dart';

abstract class ValetKpisState {
  const ValetKpisState();
}

class ValetKpisInitial extends ValetKpisState {
  const ValetKpisInitial();
}

class ValetKpisLoading extends ValetKpisState {
  const ValetKpisLoading();
}

class ValetKpisLoaded extends ValetKpisState {
  final ValetKpisResponse kpis;

  const ValetKpisLoaded({
    required this.kpis,
  });
}

class ValetKpisError extends ValetKpisState {
  final String message;

  const ValetKpisError(this.message);
}
