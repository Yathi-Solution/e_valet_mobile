import 'package:evalet/models/operator/operator_dashboard/available_drivers.dart';

class OperatorAvailableDriversResponse {
  final List<AvailableDriver> drivers;

  OperatorAvailableDriversResponse({
    required this.drivers,
  });

  factory OperatorAvailableDriversResponse.fromJson(Map<String, dynamic> json) {
    return OperatorAvailableDriversResponse(
      drivers: (json['drivers'] as List<dynamic>?)
              ?.map((driver) =>
                  AvailableDriver.fromJson(driver as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drivers': drivers.map((driver) => driver.toJson()).toList(),
    };
  }
}
