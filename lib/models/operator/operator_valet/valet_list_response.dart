import 'package:evalet/models/operator/operator_valet/valet_response.dart';

class ValetListResponse {
  final List<ValetResponse> valets;
  final int total;

  ValetListResponse({
    required this.valets,
    required this.total,
  });

  factory ValetListResponse.fromJson(Map<String, dynamic> json) {
    return ValetListResponse(
      valets: (json['valets'] as List<dynamic>?)
              ?.map((item) => ValetResponse.fromJson(item))
              .toList() ??
          [],
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'valets': valets.map((valet) => valet.toJson()).toList(),
      'total': total,
    };
  }
}
