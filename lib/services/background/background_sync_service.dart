import 'package:workmanager/workmanager.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';
import 'package:niloufer_valet_mobile/models/driver/session/checkin_request_adapter.dart';
import 'package:niloufer_valet_mobile/models/driver/session/offline_checkin_request.dart';
import 'package:niloufer_valet_mobile/models/driver/park/offline_parking_photo.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';

const String taskName = 'syncPendingParkingData';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint("Native called background task: $task");

    try {
      // Initialize Hive for background isolate
      await Hive.initFlutter();

      // Register adapter if not already registered
      if (!Hive.isAdapterRegistered(CheckinRequestAdapter().typeId)) {
        Hive.registerAdapter(CheckinRequestAdapter());
      }
      if (!Hive.isAdapterRegistered(OfflineParkingPhotoAdapter().typeId)) {
        Hive.registerAdapter(OfflineParkingPhotoAdapter());
      }
      if (!Hive.isAdapterRegistered(OfflineCheckinRequestAdapter().typeId)) {
        Hive.registerAdapter(OfflineCheckinRequestAdapter());
      }

      switch (task) {
        case taskName:
          await OfflineParkingService.syncPendingData();
          break;
        case Workmanager.iOSBackgroundTask:
          debugPrint("iOS background task triggered");
          await OfflineParkingService.syncPendingData();
          break;
      }
      return Future.value(true);
    } catch (e) {
      debugPrint("Background task failed: $e");
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);

    // Register periodic task (every 15 mins)
    if (Platform.isAndroid) {
      await Workmanager().registerPeriodicTask(
        "periodic-parking-sync",
        taskName,
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.connected,
        ),
      );
    }
  }

  static Future<void> triggerSync() async {
    // Trigger an immediate/one-off sync
    await Workmanager().registerOneOffTask(
      "one-off-sync-${DateTime.now().millisecondsSinceEpoch}",
      taskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
      existingWorkPolicy: ExistingWorkPolicy.append,
    );
  }
}
