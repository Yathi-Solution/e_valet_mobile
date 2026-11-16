import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/services/storage/auth_box.dart';

/// Card numbers allocated to the logged-in driver.
///
/// Stored in the shared [AuthBox].
class DriverCardsStorage {
  /// Card numbers allocated to this driver (from GET /drivers/my-cards).
  /// Used to restrict tag/QR entry at park time to only the driver's own cards.
  static const String _driverAssignedCardNumbersKey =
      'driver_assigned_card_numbers_v1';
  static const String _driverAssignedCardsLoadedKey =
      'driver_assigned_cards_loaded_v1';

  // Driver assigned cards (for park-time ownership check against local allocation)
  static Future<void> saveDriverAssignedCardNumbers(
      List<int> cardNumbers) async {
    try {
      await AuthBox.box.put(_driverAssignedCardNumbersKey, cardNumbers);
      await AuthBox.box.put(_driverAssignedCardsLoadedKey, true);
    } catch (e) {
      print('[DriverCardsStorage] Error saving driver assigned cards: $e');
    }
  }

  static Future<List<int>> getDriverAssignedCardNumbers() async {
    try {
      final raw = AuthBox.box.get(_driverAssignedCardNumbersKey);
      if (raw is List) {
        return raw.whereType<int>().toList(growable: false);
      }
      return const <int>[];
    } catch (e) {
      print('[DriverCardsStorage] Error reading driver assigned cards: $e');
      return const <int>[];
    }
  }

  /// Sync getter for use in submit guards and other non-async contexts.
  static List<int> getDriverAssignedCardNumbersSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return const <int>[];
      final raw = Hive.box(AuthBox.name).get(_driverAssignedCardNumbersKey);
      if (raw is List) {
        return raw.whereType<int>().toList(growable: false);
      }
      return const <int>[];
    } catch (_) {
      return const <int>[];
    }
  }

  /// Returns true only if the card number is in the driver's locally stored allocation list.
  /// An empty list blocks all cards until cards are fetched and saved (login, splash, or My Cards sync).
  static bool isDriverCardNumberAllowedSync(int cardNumber) {
    final cards = getDriverAssignedCardNumbersSync();
    if (cards.isEmpty) return false;
    return cards.contains(cardNumber);
  }

  /// False while GET /drivers/my-cards is still running after login.
  static bool isDriverAssignedCardsLoadedSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return false;
      return (Hive.box(AuthBox.name).get(_driverAssignedCardsLoadedKey)
              as bool?) ??
          false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> markDriverAssignedCardsLoading() async {
    try {
      await AuthBox.box.put(_driverAssignedCardsLoadedKey, false);
    } catch (e) {
      print('[DriverCardsStorage] Error marking driver cards loading: $e');
    }
  }

  static Future<bool> hasDriverAssignedCardNumbers() async {
    final cards = await getDriverAssignedCardNumbers();
    return cards.isNotEmpty;
  }

  /// Clears locally stored card allocation only when data from a prior session exists.
  static Future<bool> clearDriverAssignedCardNumbersIfPresent() async {
    if (!await hasDriverAssignedCardNumbers()) return false;
    await clearDriverAssignedCardNumbers();
    return true;
  }

  static Future<void> clearDriverAssignedCardNumbers() async {
    try {
      await AuthBox.box.delete(_driverAssignedCardNumbersKey);
      await AuthBox.box.delete(_driverAssignedCardsLoadedKey);
    } catch (e) {
      print('[DriverCardsStorage] Error clearing driver assigned cards: $e');
    }
  }

  static void clearDriverAssignedCardNumbersSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return;
      final box = Hive.box(AuthBox.name);
      box.delete(_driverAssignedCardNumbersKey);
      box.delete(_driverAssignedCardsLoadedKey);
    } catch (_) {}
  }
}
