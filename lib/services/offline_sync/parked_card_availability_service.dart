import 'package:niloufer_valet_mobile/api/driver/my_parked_sessions_api_service.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';

/// Offline checks for whether a valet card is already parked / checked-in locally.
class ParkedCardAvailabilityService {
  ParkedCardAvailabilityService._();

  static Future<bool> isCardNumberAlreadyInUse(int cardNumber) async {
    if (cardNumber <= 0) return false;
    final inUse = await getInUseCardNumbers();
    return inUse.contains(cardNumber);
  }

  static Future<Set<int>> getInUseCardNumbers() async {
    final numbers = <int>{};

    final cached = await MyParkedSessionsApiService.getCachedParkedSessions();
    if (cached != null) {
      for (final session in cached.sessions) {
        if (session.cardNumber > 0) {
          numbers.add(session.cardNumber);
        }
      }
    }

    final localParked = await OfflineParkingService.getLocalParkedSessions();
    for (final session in localParked) {
      if (session.cardNumber > 0) {
        numbers.add(session.cardNumber);
      }
    }

    final pendingCheckins = await OfflineParkingService.getPendingCheckins();
    for (final checkin in pendingCheckins) {
      if (checkin.cardNumber > 0) {
        numbers.add(checkin.cardNumber);
      }
    }

    return numbers;
  }
}
