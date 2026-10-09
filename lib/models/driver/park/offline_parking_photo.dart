import 'package:hive_flutter/hive_flutter.dart';

class OfflineParkingPhoto {
  final String? imagePath;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final String? parkingLocation;
  final String? vehicleNumber;
  final String? sessionId;
  final bool isReparking;
  final String timestamp;
  /// Card number for this park (used for local parked-cars list and offline check-in sync).
  final int? cardNumber;
  /// True when scanner/check-in submit already reached the server; only park API remains.
  final bool checkinSubmittedOnServer;

  OfflineParkingPhoto({
    this.imagePath,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.parkingLocation,
    this.vehicleNumber,
    this.sessionId,
    required this.isReparking,
    required this.timestamp,
    this.cardNumber,
    this.checkinSubmittedOnServer = false,
  });
}

class OfflineParkingPhotoAdapter extends TypeAdapter<OfflineParkingPhoto> {
  @override
  final int typeId = 2; // Unique ID for this adapter (CheckinRequest is 1)

  @override
  OfflineParkingPhoto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final sessionId = fields[5] as String?;
    final offlineSession = (sessionId ?? '').trim().startsWith('offline-');
    return OfflineParkingPhoto(
      imagePath: fields[0] as String?,
      latitude: fields[1] as double,
      longitude: fields[2] as double,
      accuracy: fields[3] as double?,
      parkingLocation: fields[4] as String?,
      vehicleNumber: fields[8] as String?,
      sessionId: sessionId,
      isReparking: fields[6] as bool,
      timestamp: fields[7] as String,
      cardNumber: fields.containsKey(9) ? fields[9] as int? : null,
      checkinSubmittedOnServer: fields.containsKey(10)
          ? (fields[10] as bool? ?? false)
          : !offlineSession,
    );
  }

  @override
  void write(BinaryWriter writer, OfflineParkingPhoto obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.imagePath)
      ..writeByte(1)
      ..write(obj.latitude)
      ..writeByte(2)
      ..write(obj.longitude)
      ..writeByte(3)
      ..write(obj.accuracy)
      ..writeByte(4)
      ..write(obj.parkingLocation)
      ..writeByte(5)
      ..write(obj.sessionId)
      ..writeByte(6)
      ..write(obj.isReparking)
      ..writeByte(7)
      ..write(obj.timestamp)
      ..writeByte(8)
      ..write(obj.vehicleNumber)
      ..writeByte(9)
      ..write(obj.cardNumber)
      ..writeByte(10)
      ..write(obj.checkinSubmittedOnServer);
  }
}
