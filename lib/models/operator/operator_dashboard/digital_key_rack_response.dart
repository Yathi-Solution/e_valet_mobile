import 'package:evalet/models/operator/operator_dashboard/key_rack_item.dart';

class DigitalKeyRackResponse {
  final List<KeyRackItem> keyRack;
  final int total;

  DigitalKeyRackResponse({
    required this.keyRack,
    required this.total,
  });

  factory DigitalKeyRackResponse.fromJson(Map<String, dynamic> json) {
    final keyRackList = json['keyRack'] as List<dynamic>? ?? [];
    return DigitalKeyRackResponse(
      keyRack: keyRackList
          .map((item) => KeyRackItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      total: json['total'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'keyRack': keyRack.map((item) => item.toJson()).toList(),
      'total': total,
    };
  }
}
