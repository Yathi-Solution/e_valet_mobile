import 'package:evalet/models/operator/operator_dashboard/available_tags.dart';
import 'package:evalet/models/operator/operator_dashboard/available_valets.dart';

class OperatorDashboardKpisResponse {
  final AvailableTags availableTags;
  final AvailableValets availableValets;
  final int vehiclesInTransit;
  final int totalVehiclesParked;

  OperatorDashboardKpisResponse({
    required this.availableTags,
    required this.availableValets,
    required this.vehiclesInTransit,
    required this.totalVehiclesParked,
  });

  factory OperatorDashboardKpisResponse.fromJson(Map<String, dynamic> json) {
    return OperatorDashboardKpisResponse(
      availableTags: AvailableTags.fromJson(json['availableTags'] ?? {}),
      availableValets: AvailableValets.fromJson(json['availableValets'] ?? {}),
      vehiclesInTransit: json['vehiclesInTransit'] ?? 0,
      totalVehiclesParked: json['totalVehiclesParked'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'availableTags': availableTags.toJson(),
      'availableValets': availableValets.toJson(),
      'vehiclesInTransit': vehiclesInTransit,
      'totalVehiclesParked': totalVehiclesParked,
    };
  }
}
