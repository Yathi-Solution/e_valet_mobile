import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/models/driver/session/checkin_request.dart';

class OfflineCheckinRequest {
  final int outletId;
  final int cardNumber;
  final String clientSessionId;
  final String timestamp;

  /// Outlet Code read from the scanned card, kept so the server can still
  /// check the card's outlet when this check-in syncs. Null when unknown.
  final String? outletCode;

  OfflineCheckinRequest({
    required this.outletId,
    required this.cardNumber,
    required this.clientSessionId,
    required this.timestamp,
    this.outletCode,
  });

  CheckinRequest toCheckinRequest() {
    return CheckinRequest(
      outletId: outletId,
      cardNumber: cardNumber,
      outletCode: outletCode,
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
      // Absent on entries saved before this field existed.
      outletCode: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineCheckinRequest obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.outletId)
      ..writeByte(1)
      ..write(obj.cardNumber)
      ..writeByte(2)
      ..write(obj.clientSessionId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.outletCode);
  }
}
