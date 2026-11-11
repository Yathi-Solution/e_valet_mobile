import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/models/driver/session/checkin_request.dart';

class CheckinRequestAdapter extends TypeAdapter<CheckinRequest> {
  @override
  final int typeId = 1; // Unique ID for this adapter

  @override
  CheckinRequest read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CheckinRequest(
      outletId: fields[0] as int,
      cardNumber: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CheckinRequest obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.outletId)
      ..writeByte(1)
      ..write(obj.cardNumber)
      ..writeByte(2);
  }
}
