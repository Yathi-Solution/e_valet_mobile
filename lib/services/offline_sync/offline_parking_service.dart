import 'package:hive_flutter/hive_flutter.dart';
import 'package:niloufer_valet_mobile/api/driver/image_API.dart';
import 'package:niloufer_valet_mobile/api/driver/re-park_api.dart';
import 'package:niloufer_valet_mobile/api/driver/session_api_service.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/driver/park/offline_parking_photo.dart';
import 'package:niloufer_valet_mobile/models/driver/park/park_request.dart';
import 'package:niloufer_valet_mobile/models/driver/re-park/repark_photo_request.dart';
import 'package:niloufer_valet_mobile/models/driver/parked/my_parked_sessions_response.dart';
import 'package:niloufer_valet_mobile/models/driver/session/offline_checkin_request.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:flutter/foundation.dart';

class OfflineParkingService {
  static const String _photoBoxName = 'offline_photos';
  static const String _checkinBoxName = 'offline_checkins';

  static Future<void> init() async {
    await Hive.openBox<OfflineParkingPhoto>(_photoBoxName);
    await Hive.openBox<OfflineCheckinRequest>(_checkinBoxName);
  }

  static bool isOfflineSessionId(String? sessionId) {
    return (sessionId ?? '').trim().startsWith('offline-');
  }

  static Future<void> saveParkingPhoto(OfflineParkingPhoto photo) async {
    final box = Hive.box<OfflineParkingPhoto>(_photoBoxName);
    await box.add(photo);
    debugPrint(
        'Offline photo saved: ${photo.imagePath} for session ${photo.sessionId}');
  }

  static Future<void> savePendingCheckin(OfflineCheckinRequest checkin) async {
    if (!Hive.isBoxOpen(_checkinBoxName)) {
      await Hive.openBox<OfflineCheckinRequest>(_checkinBoxName);
    }
    final box = Hive.box<OfflineCheckinRequest>(_checkinBoxName);
    await box.add(checkin);
    debugPrint(
        'Offline check-in saved: card ${checkin.cardNumber} with session ${checkin.clientSessionId}');
  }

  static Future<List<OfflineParkingPhoto>> getPendingPhotos() async {
    final box = Hive.box<OfflineParkingPhoto>(_photoBoxName);
    return box.values.toList();
  }

  static Future<List<OfflineCheckinRequest>> getPendingCheckins() async {
    if (!Hive.isBoxOpen(_checkinBoxName)) {
      await Hive.openBox<OfflineCheckinRequest>(_checkinBoxName);
    }
    final box = Hive.box<OfflineCheckinRequest>(_checkinBoxName);
    return box.values.toList();
  }

  static int? cardNumberFromOfflineSessionId(String? sessionId) {
    final id = (sessionId ?? '').trim();
    if (!isOfflineSessionId(id)) return null;
    final lastDash = id.lastIndexOf('-');
    if (lastDash < 0 || lastDash >= id.length - 1) return null;
    return int.tryParse(id.substring(lastDash + 1));
  }

  /// Parked cars saved locally while offline, waiting to sync with the server.
  static Future<List<MyParkedSession>> getLocalParkedSessions() async {
    final photos = await getPendingPhotos();
    final checkins = await getPendingCheckins();
    final checkinBySession = {
      for (final checkin in checkins) checkin.clientSessionId.trim(): checkin,
    };

    final sessions = <MyParkedSession>[];
    for (final photo in photos) {
      if (photo.isReparking) continue;

      final sessionId = (photo.sessionId ?? '').trim();
      if (sessionId.isEmpty) continue;

      final checkin = checkinBySession[sessionId];
      final cardNumber = photo.cardNumber ??
          checkin?.cardNumber ??
          cardNumberFromOfflineSessionId(sessionId) ??
          0;
      if (cardNumber <= 0) continue;

      sessions.add(
        MyParkedSession(
          sessionId: sessionId,
          cardNumber: cardNumber,
          vehicleNumber: photo.vehicleNumber,
          parkingLocation: photo.parkingLocation,
          parkedAt: photo.timestamp,
          source: 'OWN',
          isPendingLocalSync: true,
        ),
      );
    }

    return sessions;
  }

  static Future<void> clearAll() async {
    final photoBox = Hive.box<OfflineParkingPhoto>(_photoBoxName);
    await photoBox.clear();
    if (Hive.isBoxOpen(_checkinBoxName)) {
      await Hive.box<OfflineCheckinRequest>(_checkinBoxName).clear();
    }
  }

  /// Sync-safe read used by UI guards to avoid false "incomplete" prompts
  /// while an already-submitted offline park is waiting for network sync.
  static bool hasPendingPhotoForSessionSync(String? sessionId) {
    final target = (sessionId ?? '').trim();
    if (target.isEmpty) return false;
    try {
      if (!Hive.isBoxOpen(_photoBoxName)) return false;
      final box = Hive.box<OfflineParkingPhoto>(_photoBoxName);
      for (final photo in box.values) {
        if ((photo.sessionId ?? '').trim() == target) {
          return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  static bool hasPendingCheckinForSessionSync(String? sessionId) {
    final target = (sessionId ?? '').trim();
    if (target.isEmpty) return false;
    try {
      if (!Hive.isBoxOpen(_checkinBoxName)) return false;
      final box = Hive.box<OfflineCheckinRequest>(_checkinBoxName);
      for (final checkin in box.values) {
        if (checkin.clientSessionId.trim() == target) {
          return true;
        }
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  static bool hasPendingSyncForSession(String? sessionId) {
    return hasPendingPhotoForSessionSync(sessionId) ||
        hasPendingCheckinForSessionSync(sessionId);
  }

  static Future<void> syncPendingData() async {
    await _ensureCheckinBoxOpen();
    await _ensurePhotoBoxOpen();

    final photoBox = Hive.box<OfflineParkingPhoto>(_photoBoxName);
    final photoEntries = photoBox.toMap().entries.toList();

    for (final entry in photoEntries) {
      await _syncPendingPhotoEntry(entry.key, entry.value);
    }

    await _syncRemainingCheckins();
  }

  static Future<void> _ensureCheckinBoxOpen() async {
    if (!Hive.isBoxOpen(_checkinBoxName)) {
      await Hive.openBox<OfflineCheckinRequest>(_checkinBoxName);
    }
  }

  static Future<void> _ensurePhotoBoxOpen() async {
    if (!Hive.isBoxOpen(_photoBoxName)) {
      await Hive.openBox<OfflineParkingPhoto>(_photoBoxName);
    }
  }

  /// Returns true when scanner/check-in submit already happened (online or synced).
  static bool isCheckinAlreadySubmittedForPhoto(OfflineParkingPhoto photo) {
    if (photo.checkinSubmittedOnServer) return true;
    final sessionId = (photo.sessionId ?? '').trim();
    if (sessionId.isEmpty) return false;
    return !isOfflineSessionId(sessionId);
  }

  static Future<void> _syncPendingPhotoEntry(
    dynamic photoKey,
    OfflineParkingPhoto photo,
  ) async {
    if (!Hive.isBoxOpen(_photoBoxName)) {
      await Hive.openBox<OfflineParkingPhoto>(_photoBoxName);
    }
    final photoBox = Hive.box<OfflineParkingPhoto>(_photoBoxName);
    if (!photoBox.containsKey(photoKey)) return;

    if (photo.isReparking) {
      await _syncPhotoEntry(photoKey, photo);
      return;
    }

    if (!isCheckinAlreadySubmittedForPhoto(photo)) {
      final checkinSynced = await _syncCheckinForPhoto(photo);
      if (!checkinSynced) {
        debugPrint(
          'Waiting to sync scanner check-in before park upload for session ${photo.sessionId}',
        );
        return;
      }

      photo = photoBox.get(photoKey) ?? photo;
    }

    if (isOfflineSessionId(photo.sessionId)) {
      debugPrint(
        'Park upload deferred until check-in resolves session ${photo.sessionId}',
      );
      return;
    }

    await _syncPhotoEntry(photoKey, photo);
  }

  static Future<bool> _syncCheckinForPhoto(OfflineParkingPhoto photo) async {
    await _ensureCheckinBoxOpen();
    final box = Hive.box<OfflineCheckinRequest>(_checkinBoxName);
    final sessionId = (photo.sessionId ?? '').trim();

    MapEntry<dynamic, OfflineCheckinRequest>? matchedEntry;
    for (final entry in box.toMap().entries) {
      if (entry.value.clientSessionId.trim() == sessionId) {
        matchedEntry = entry;
        break;
      }
    }

    if (matchedEntry != null) {
      return _syncSingleCheckinEntry(matchedEntry.key, matchedEntry.value);
    }

    final cardNumber = photo.cardNumber ??
        cardNumberFromOfflineSessionId(sessionId);
    if (cardNumber == null || cardNumber <= 0) {
      debugPrint('Cannot sync check-in: missing card number for $sessionId');
      return false;
    }

    final outletId = int.tryParse(
          (await TokenStorage.getSelectedOutletId())?.toString() ?? '',
        ) ??
        0;
    if (outletId <= 0) {
      debugPrint('Cannot sync check-in: outlet id unavailable');
      return false;
    }

    final fallbackCheckin = OfflineCheckinRequest(
      outletId: outletId,
      cardNumber: cardNumber,
      clientSessionId: sessionId,
      timestamp: photo.timestamp,
    );
    return _syncSingleCheckinEntry(null, fallbackCheckin, remapSessionId: sessionId);
  }

  static Future<void> _syncRemainingCheckins() async {
    await _ensureCheckinBoxOpen();
    final box = Hive.box<OfflineCheckinRequest>(_checkinBoxName);
    if (box.isEmpty) return;

    final checkins = box.toMap().entries.toList();
    for (final entry in checkins) {
      await _syncSingleCheckinEntry(entry.key, entry.value);
    }
  }

  static Future<bool> _syncSingleCheckinEntry(
    dynamic key,
    OfflineCheckinRequest checkin, {
    String? remapSessionId,
  }) async {
    await _ensureCheckinBoxOpen();
    final box = Hive.box<OfflineCheckinRequest>(_checkinBoxName);
    final clientSessionId =
        remapSessionId ?? checkin.clientSessionId.trim();

    if (!TokenStorage.isDriverCardNumberAllowedSync(checkin.cardNumber)) {
      debugPrint(
        'Deferring check-in sync for card ${checkin.cardNumber} until cards allocation is loaded',
      );
      return false;
    }

    bool success = false;
    var attempts = 0;

    while (!success && attempts < 3) {
      try {
        debugPrint(
          'Syncing scanner check-in for card ${checkin.cardNumber} (attempt ${attempts + 1})',
        );

        final response =
            await SessionApiService.checkin(checkin.toCheckinRequest());
        final realSessionId = response.sessionId.trim();

        if (realSessionId.isNotEmpty) {
          await _remapPhotosSessionId(clientSessionId, realSessionId);

          final currentSessionId = await TokenStorage.getSessionId();
          if (currentSessionId == clientSessionId) {
            await TokenStorage.saveSessionId(realSessionId);
          }
        }

        if (key != null) {
          await box.delete(key);
        }
        debugPrint('Scanner check-in synced for card ${checkin.cardNumber}');
        success = true;
      } catch (e) {
        if (_isAlreadyCheckedInError(e)) {
          if (key != null) {
            await box.delete(key);
          }
          final currentSessionId =
              (await TokenStorage.getSessionId())?.trim() ?? '';
          if (currentSessionId.isNotEmpty &&
              !isOfflineSessionId(currentSessionId)) {
            await _remapPhotosSessionId(clientSessionId, currentSessionId);
          }
          debugPrint('Check-in already exists on server for card ${checkin.cardNumber}');
          success = true;
          continue;
        }

        attempts++;
        debugPrint('Failed to sync check-in for card ${checkin.cardNumber}: $e');
        if (attempts < 3) {
          await Future.delayed(const Duration(seconds: 5));
        }
      }
    }

    return success;
  }

  static Future<void> _syncPhotoEntry(
    dynamic key,
    OfflineParkingPhoto photo,
  ) async {
    await _ensurePhotoBoxOpen();
    final box = Hive.box<OfflineParkingPhoto>(_photoBoxName);
    if (!box.containsKey(key)) return;

    var success = false;
    var attempts = 0;

    while (!success && attempts < 3) {
      try {
        debugPrint(
          'Syncing park upload for session ${photo.sessionId} (attempt ${attempts + 1})',
        );

        if (photo.isReparking) {
          final reparkRequest = ReparkPhotoRequest(
            imagePath: photo.imagePath,
            latitude: photo.latitude,
            longitude: photo.longitude,
            accuracy: photo.accuracy,
            parkingLocation: photo.parkingLocation,
          );
          await ReparkApiService.uploadReparkPhoto(
            sessionId: photo.sessionId,
            request: reparkRequest,
          );
        } else {
          final parkRequest = ParkRequest(
            imagePath: photo.imagePath,
            latitude: photo.latitude,
            longitude: photo.longitude,
            accuracy: photo.accuracy,
            parkingLocation: photo.parkingLocation,
            vehicleNumber: photo.vehicleNumber,
          );
          await ImageApiService.uploadParkingPhoto(
            request: parkRequest,
            sessionId: photo.sessionId,
          );
        }

        await box.delete(key);
        debugPrint('Park upload synced and removed local entry: $key');
        success = true;
      } catch (e) {
        if (_isAlreadyParkedError(e)) {
          await box.delete(key);
          debugPrint('Park already exists on server, removing local entry: $key');
          success = true;
          continue;
        }

        attempts++;
        debugPrint('Failed to sync park upload $key: $e');
        if (attempts < 3) {
          await Future.delayed(const Duration(seconds: 5));
        }
      }
    }
  }

  static bool _isAlreadyParkedError(Object error) {
    final msg = (error is ApiException ? error.message : error.toString())
        .toUpperCase();
    return (msg.contains('PARKED') && msg.contains('CHECKED_IN')) ||
        (msg.contains('ALREADY') && msg.contains('CHECKED'));
  }

  static bool _isAlreadyCheckedInError(Object error) {
    final msg = (error is ApiException ? error.message : error.toString())
        .toUpperCase();
    return (msg.contains('ALREADY') && msg.contains('CHECK')) ||
        (msg.contains('PARKED') && msg.contains('CHECKED_IN'));
  }

  static Future<void> _remapPhotosSessionId(
    String oldSessionId,
    String newSessionId,
  ) async {
    if (!Hive.isBoxOpen(_photoBoxName)) {
      await Hive.openBox<OfflineParkingPhoto>(_photoBoxName);
    }

    final box = Hive.box<OfflineParkingPhoto>(_photoBoxName);
    for (final key in box.keys) {
      final photo = box.get(key);
      if (photo == null || (photo.sessionId ?? '').trim() != oldSessionId) {
        continue;
      }

      await box.put(
        key,
        OfflineParkingPhoto(
          imagePath: photo.imagePath,
          latitude: photo.latitude,
          longitude: photo.longitude,
          accuracy: photo.accuracy,
          parkingLocation: photo.parkingLocation,
          vehicleNumber: photo.vehicleNumber,
          sessionId: newSessionId,
          isReparking: photo.isReparking,
          timestamp: photo.timestamp,
          cardNumber: photo.cardNumber,
          checkinSubmittedOnServer: true,
        ),
      );
    }
  }
}
