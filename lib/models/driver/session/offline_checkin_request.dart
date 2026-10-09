import 'package:hive_flutter/hive_flutter.dart';
import 'package:niloufer_valet_mobile/models/driver/session/checkin_request.dart';

class OfflineCheckinRequest {
  final int outletId;
  final int cardNumber;
  final String clientSessionId;
  final String timestamp;

  OfflineCheckinRequest({
    required this.outletId,
    required this.cardNumber,
    required this.clientSessionId,
    required this.timestamp,
  });

  CheckinRequest toCheckinRequest() {
    return CheckinRequest(
      outletId: outletId,
      cardNumber: cardNumber,
    );
  }
}

class OfflineCheckinRequestAdapter extends TypeAdapter<OfflineCheckinRequest> {
  @override
  final int typeId = 3;

  @override
  OfflineCheckinRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OfflineCheckinRequest(
      outletId: fields[0] as int,
      cardNumber: fields[1] as int,
      clientSessionId: fields[2] as String,
      timestamp: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineCheckinRequest obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.outletId)
      ..writeByte(1)
      ..write(obj.cardNumber)
      ..writeByte(2)
      ..write(obj.clientSessionId)
      ..writeByte(3)
      ..write(obj.timestamp);
  }
}
