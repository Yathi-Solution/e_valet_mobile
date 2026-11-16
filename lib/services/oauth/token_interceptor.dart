import 'package:evalet/services/storage/connectivity_log_storage.dart';
import 'package:evalet/services/storage/retrieval_flow_storage.dart';
import 'package:evalet/services/storage/cooldown_storage.dart';
import 'package:evalet/services/storage/app_config_storage.dart';
import 'package:evalet/services/storage/driver_cards_storage.dart';
import 'package:evalet/services/storage/outlet_storage.dart';
import 'package:evalet/services/storage/location_storage.dart';
import 'package:evalet/services/storage/auth_storage.dart';
import 'package:evalet/services/storage/user_storage.dart';
import 'package:evalet/services/storage/parking_session_storage.dart';
import 'package:evalet/services/storage/auth_box.dart';

/// Facade over the stores in `lib/services/storage/`.
///
/// This class used to hold every locally stored value itself. Each method now
/// forwards to the store that owns the data, so existing callers keep working.
/// New code should call the store directly (for example [OutletStorage]).
class TokenStorage {
  /// Name of the shared Hive box.
  static String get boxName => AuthBox.name;

  /// Must be called once at app start (after Hive.initFlutter()).
  static Future<void> init() => AuthBox.init();

  // ---- ConnectivityLogStorage ----
  static Future<void> clearDriverConnectivityLogData() =>
      ConnectivityLogStorage.clearDriverConnectivityLogData();
  static Future<void> saveDriverConnectivityShiftContext({
    required int shiftId,
    required int outletId,
  }) =>
      ConnectivityLogStorage.saveDriverConnectivityShiftContext(
          shiftId: shiftId, outletId: outletId);
  static Future<int?> getDriverConnectivityShiftId() =>
      ConnectivityLogStorage.getDriverConnectivityShiftId();
  static Future<int?> getDriverConnectivityOutletId() =>
      ConnectivityLogStorage.getDriverConnectivityOutletId();
  static Future<void> saveDriverConnectivityEnabled(bool isEnabled) =>
      ConnectivityLogStorage.saveDriverConnectivityEnabled(isEnabled);
  static Future<bool> getDriverConnectivityEnabled() =>
      ConnectivityLogStorage.getDriverConnectivityEnabled();
  static Future<void> saveDriverConnectivitySettings({
    required int outletId,
    required bool isEnabled,
  }) =>
      ConnectivityLogStorage.saveDriverConnectivitySettings(
          outletId: outletId, isEnabled: isEnabled);
  static Future<void> clearDriverConnectivitySettings() =>
      ConnectivityLogStorage.clearDriverConnectivitySettings();
  static Future<int?> getDriverConnectivitySettingsOutletId() =>
      ConnectivityLogStorage.getDriverConnectivitySettingsOutletId();
  static Future<void> saveConnectivityNextFlushDue(DateTime utc) =>
      ConnectivityLogStorage.saveConnectivityNextFlushDue(utc);
  static Future<DateTime?> getConnectivityNextFlushDue() =>
      ConnectivityLogStorage.getConnectivityNextFlushDue();
  static Future<String?> getConnectivityPendingEventsJson() =>
      ConnectivityLogStorage.getConnectivityPendingEventsJson();
  static Future<void> saveConnectivityPendingEventsJson(String json) =>
      ConnectivityLogStorage.saveConnectivityPendingEventsJson(json);
  static Future<void> clearConnectivityPendingEvents() =>
      ConnectivityLogStorage.clearConnectivityPendingEvents();

  // ---- RetrievalFlowStorage ----
  static void saveCollectKeysInTransitAckSync(String sessionId) =>
      RetrievalFlowStorage.saveCollectKeysInTransitAckSync(sessionId);
  static Future<void> saveCollectKeysInTransitAck(String sessionId) =>
      RetrievalFlowStorage.saveCollectKeysInTransitAck(sessionId);
  static List<String> collectKeysInTransitOrderedIdsSync() =>
      RetrievalFlowStorage.collectKeysInTransitOrderedIdsSync();
  static void removeCollectKeysInTransitAckForSessionSync(String sessionId) =>
      RetrievalFlowStorage.removeCollectKeysInTransitAckForSessionSync(
          sessionId);
  static Future<bool> collectKeysInTransitAckContains(String sessionId) =>
      RetrievalFlowStorage.collectKeysInTransitAckContains(sessionId);
  static bool collectKeysInTransitAckContainsSync(String sessionId) =>
      RetrievalFlowStorage.collectKeysInTransitAckContainsSync(sessionId);
  static void markRetrievalConfirmFlowCompletedCooldownSync(String sessionId) =>
      RetrievalFlowStorage.markRetrievalConfirmFlowCompletedCooldownSync(
          sessionId);
  static bool shouldSuppressAutoConfirmArrivalForSessionSync(
          String sessionId) =>
      RetrievalFlowStorage.shouldSuppressAutoConfirmArrivalForSessionSync(
          sessionId);
  static Future<void> clearCollectKeysInTransitAck() =>
      RetrievalFlowStorage.clearCollectKeysInTransitAck();
  static void clearCollectKeysInTransitAckSync() =>
      RetrievalFlowStorage.clearCollectKeysInTransitAckSync();

  // ---- CooldownStorage ----
  static DateTime? getCustomerMissingDisabledUntilForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) =>
      CooldownStorage.getCustomerMissingDisabledUntilForSessionSync(sessionId,
          cardNumber: cardNumber);
  static bool hasConfirmArrivalTimerStartedForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) =>
      CooldownStorage.hasConfirmArrivalTimerStartedForSessionSync(sessionId,
          cardNumber: cardNumber);
  static void markConfirmArrivalTimerStartedForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) =>
      CooldownStorage.markConfirmArrivalTimerStartedForSessionSync(sessionId,
          cardNumber: cardNumber);
  static void saveCustomerMissingDisabledUntilForSessionSync(
    String sessionId,
    DateTime until, {
    int? cardNumber,
  }) =>
      CooldownStorage.saveCustomerMissingDisabledUntilForSessionSync(
          sessionId, until,
          cardNumber: cardNumber);
  static DateTime? getConfirmArrivalDisabledUntilForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) =>
      CooldownStorage.getConfirmArrivalDisabledUntilForSessionSync(sessionId,
          cardNumber: cardNumber);
  static void saveConfirmArrivalDisabledUntilForSessionSync(
    String sessionId,
    DateTime until, {
    int? cardNumber,
  }) =>
      CooldownStorage.saveConfirmArrivalDisabledUntilForSessionSync(
          sessionId, until,
          cardNumber: cardNumber);
  static DateTime? getConfirmHandoverDisabledUntilForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) =>
      CooldownStorage.getConfirmHandoverDisabledUntilForSessionSync(sessionId,
          cardNumber: cardNumber);
  static void saveConfirmHandoverDisabledUntilForSessionSync(
    String sessionId,
    DateTime until, {
    int? cardNumber,
  }) =>
      CooldownStorage.saveConfirmHandoverDisabledUntilForSessionSync(
          sessionId, until,
          cardNumber: cardNumber);
  static bool hasConfirmHandoverTimerStartedForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) =>
      CooldownStorage.hasConfirmHandoverTimerStartedForSessionSync(sessionId,
          cardNumber: cardNumber);
  static void markConfirmHandoverTimerStartedForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) =>
      CooldownStorage.markConfirmHandoverTimerStartedForSessionSync(sessionId,
          cardNumber: cardNumber);
  static void clearHandoverButtonCooldownForSessionSync(
    String sessionId, {
    int? cardNumber,
  }) =>
      CooldownStorage.clearHandoverButtonCooldownForSessionSync(sessionId,
          cardNumber: cardNumber);

  // ---- AppConfigStorage ----
  static Future<void> saveButtonConfig({
    required int confirmArrivalDisableSeconds,
    required int customerMissingDisableSeconds,
    required int confirmHandoverDisableSeconds,
    required bool scannerButtonStatus,
    required int imageCompressionQuality,
    required int imageCompressionMaxSizeKB,
  }) =>
      AppConfigStorage.saveButtonConfig(
          confirmArrivalDisableSeconds: confirmArrivalDisableSeconds,
          customerMissingDisableSeconds: customerMissingDisableSeconds,
          confirmHandoverDisableSeconds: confirmHandoverDisableSeconds,
          scannerButtonStatus: scannerButtonStatus,
          imageCompressionQuality: imageCompressionQuality,
          imageCompressionMaxSizeKB: imageCompressionMaxSizeKB);
  static Future<int?> getConfirmArrivalDisableSeconds() =>
      AppConfigStorage.getConfirmArrivalDisableSeconds();
  static int? getConfirmArrivalDisableSecondsSync() =>
      AppConfigStorage.getConfirmArrivalDisableSecondsSync();
  static Future<int?> getCustomerMissingDisableSeconds() =>
      AppConfigStorage.getCustomerMissingDisableSeconds();
  static int? getCustomerMissingDisableSecondsSync() =>
      AppConfigStorage.getCustomerMissingDisableSecondsSync();
  static Future<int?> getConfirmHandoverDisableSeconds() =>
      AppConfigStorage.getConfirmHandoverDisableSeconds();
  static int? getConfirmHandoverDisableSecondsSync() =>
      AppConfigStorage.getConfirmHandoverDisableSecondsSync();
  static Future<bool?> getScannerButtonStatus() =>
      AppConfigStorage.getScannerButtonStatus();
  static bool? getScannerButtonStatusSync() =>
      AppConfigStorage.getScannerButtonStatusSync();
  static Future<int?> getImageCompressionQuality() =>
      AppConfigStorage.getImageCompressionQuality();
  static Future<int?> getImageCompressionMaxSizeKB() =>
      AppConfigStorage.getImageCompressionMaxSizeKB();

  // ---- DriverCardsStorage ----
  static Future<void> saveDriverAssignedCardNumbers(List<int> cardNumbers) =>
      DriverCardsStorage.saveDriverAssignedCardNumbers(cardNumbers);
  static Future<List<int>> getDriverAssignedCardNumbers() =>
      DriverCardsStorage.getDriverAssignedCardNumbers();
  static List<int> getDriverAssignedCardNumbersSync() =>
      DriverCardsStorage.getDriverAssignedCardNumbersSync();
  static bool isDriverCardNumberAllowedSync(int cardNumber) =>
      DriverCardsStorage.isDriverCardNumberAllowedSync(cardNumber);
  static bool isDriverAssignedCardsLoadedSync() =>
      DriverCardsStorage.isDriverAssignedCardsLoadedSync();
  static Future<void> markDriverAssignedCardsLoading() =>
      DriverCardsStorage.markDriverAssignedCardsLoading();
  static Future<bool> hasDriverAssignedCardNumbers() =>
      DriverCardsStorage.hasDriverAssignedCardNumbers();
  static Future<bool> clearDriverAssignedCardNumbersIfPresent() =>
      DriverCardsStorage.clearDriverAssignedCardNumbersIfPresent();
  static Future<void> clearDriverAssignedCardNumbers() =>
      DriverCardsStorage.clearDriverAssignedCardNumbers();
  static void clearDriverAssignedCardNumbersSync() =>
      DriverCardsStorage.clearDriverAssignedCardNumbersSync();

  // ---- OutletStorage ----
  static Future<void> saveSelectedOutlet({
    required int outletId,
    required String outletName,
  }) =>
      OutletStorage.saveSelectedOutlet(
          outletId: outletId, outletName: outletName);
  static Future<int?> getSelectedOutletId() =>
      OutletStorage.getSelectedOutletId();
  static int? getSelectedOutletIdSync() =>
      OutletStorage.getSelectedOutletIdSync();
  static Future<void> saveConfirmedOutletCode({
    required int outletId,
    required String outletCode,
  }) =>
      OutletStorage.saveConfirmedOutletCode(
          outletId: outletId, outletCode: outletCode);
  static String? getConfirmedOutletCodeSync() =>
      OutletStorage.getConfirmedOutletCodeSync();
  static Future<String?> getSelectedOutletName() =>
      OutletStorage.getSelectedOutletName();
  static Future<void> clearSelectedOutlet() =>
      OutletStorage.clearSelectedOutlet();

  // ---- LocationStorage ----
  static Future<void> saveParkingLocation(String location) =>
      LocationStorage.saveParkingLocation(location);
  static Future<String?> getParkingLocation() =>
      LocationStorage.getParkingLocation();
  static Future<void> clearParkingLocation() =>
      LocationStorage.clearParkingLocation();
  static Future<void> saveArrivalLocation({
    required double latitude,
    required double longitude,
    required String location,
  }) =>
      LocationStorage.saveArrivalLocation(
          latitude: latitude, longitude: longitude, location: location);
  static Future<Map<String, dynamic>?> getArrivalLocation() =>
      LocationStorage.getArrivalLocation();
  static Future<void> clearArrivalLocation() =>
      LocationStorage.clearArrivalLocation();
  static Future<void> saveCurrentLocation({
    required double latitude,
    required double longitude,
    required String location,
  }) =>
      LocationStorage.saveCurrentLocation(
          latitude: latitude, longitude: longitude, location: location);
  static Future<Map<String, dynamic>?> getCurrentLocation() =>
      LocationStorage.getCurrentLocation();
  static Future<void> clearCurrentLocation() =>
      LocationStorage.clearCurrentLocation();

  // ---- AuthStorage ----
  static Future<void> saveAccessToken(String token) =>
      AuthStorage.saveAccessToken(token);
  static Future<String?> getAccessToken() => AuthStorage.getAccessToken();
  static Future<void> saveAccessTokenExpiry(DateTime expiry) =>
      AuthStorage.saveAccessTokenExpiry(expiry);
  static Future<DateTime?> getAccessTokenExpiry() =>
      AuthStorage.getAccessTokenExpiry();
  static Future<void> clearAccessToken() => AuthStorage.clearAccessToken();
  static Future<bool> isAccessTokenExpiredOrExpiringSoon() =>
      AuthStorage.isAccessTokenExpiredOrExpiringSoon();
  static Future<void> saveRefreshToken(String token) =>
      AuthStorage.saveRefreshToken(token);
  static Future<String?> getRefreshToken() => AuthStorage.getRefreshToken();
  static Future<void> clearRefreshToken() => AuthStorage.clearRefreshToken();
  static Future<void> saveResetToken(String token) =>
      AuthStorage.saveResetToken(token);
  static Future<String?> getResetToken() => AuthStorage.getResetToken();
  static Future<void> clearResetToken() => AuthStorage.clearResetToken();
  static Future<void> saveCachedAuthContext({
    required List<String> normalizedRoles,
    required String userId,
  }) =>
      AuthStorage.saveCachedAuthContext(
          normalizedRoles: normalizedRoles, userId: userId);
  static Future<List<String>?> getCachedNormalizedRoles() =>
      AuthStorage.getCachedNormalizedRoles();
  static Future<String?> getCachedUserId() => AuthStorage.getCachedUserId();
  static String? getCachedUserIdSync() => AuthStorage.getCachedUserIdSync();
  static Future<void> clearCachedAuthContext() =>
      AuthStorage.clearCachedAuthContext();
  static Future<void> clearAllTokens() => AuthStorage.clearAllTokens();
  static Future<bool> hasValidTokens() => AuthStorage.hasValidTokens();

  // ---- UserStorage ----
  static Future<void> saveUserName({
    required String firstName,
    required String lastName,
  }) =>
      UserStorage.saveUserName(firstName: firstName, lastName: lastName);
  static Future<String?> getFirstName() => UserStorage.getFirstName();
  static Future<String?> getLastName() => UserStorage.getLastName();
  static Future<void> clearUserName() => UserStorage.clearUserName();
  static Future<void> savePhoneNumber(String phoneNumber) =>
      UserStorage.savePhoneNumber(phoneNumber);
  static Future<String?> getPhoneNumber() => UserStorage.getPhoneNumber();
  static Future<void> clearPhoneNumber() => UserStorage.clearPhoneNumber();

  // ---- ParkingSessionStorage ----
  static Future<void> saveCachedParkedSessionsJson(String json) =>
      ParkingSessionStorage.saveCachedParkedSessionsJson(json);
  static Future<String?> getCachedParkedSessionsJson() =>
      ParkingSessionStorage.getCachedParkedSessionsJson();
  static Future<void> clearCachedParkedSessions() =>
      ParkingSessionStorage.clearCachedParkedSessions();
  static Future<void> saveSessionId(String sessionId) =>
      ParkingSessionStorage.saveSessionId(sessionId);
  static Future<String?> getSessionId() => ParkingSessionStorage.getSessionId();
  static String? getSessionIdSync() => ParkingSessionStorage.getSessionIdSync();
  static Future<void> clearSessionId() =>
      ParkingSessionStorage.clearSessionId();
  static Future<bool> hasSessionId() => ParkingSessionStorage.hasSessionId();
  static Future<void> savePendingPhotoPath(String photoPath) =>
      ParkingSessionStorage.savePendingPhotoPath(photoPath);
  static Future<String?> getPendingPhotoPath() =>
      ParkingSessionStorage.getPendingPhotoPath();
  static Future<void> clearPendingPhotoPath() =>
      ParkingSessionStorage.clearPendingPhotoPath();
  static Future<void> saveSessionIdFromGetApi(String sessionId) =>
      ParkingSessionStorage.saveSessionIdFromGetApi(sessionId);
  static Future<String?> getSessionIdFromGetApi() =>
      ParkingSessionStorage.getSessionIdFromGetApi();
  static Future<void> clearSessionIdFromGetApi() =>
      ParkingSessionStorage.clearSessionIdFromGetApi();
  static Future<void> saveAssignedSessionData(
          Map<String, dynamic> sessionData) =>
      ParkingSessionStorage.saveAssignedSessionData(sessionData);
  static Future<Map<String, dynamic>?> getAssignedSessionData() =>
      ParkingSessionStorage.getAssignedSessionData();
  static Future<void> clearAssignedSessionData() =>
      ParkingSessionStorage.clearAssignedSessionData();

  // ---- Logout ----

  /// Clears everything that belongs to the logged-in user.
  static Future<void> clearAll() async {
    await AuthStorage.clearAllTokens();
    await AuthStorage.clearCachedAuthContext();
    await UserStorage.clearUserName();
    await UserStorage.clearPhoneNumber();
    await AuthStorage.clearResetToken();
    await ParkingSessionStorage.clearSessionId();
    await OutletStorage.clearSelectedOutlet();
    await LocationStorage.clearCurrentLocation();
    await ConnectivityLogStorage.clearDriverConnectivityLogData();
    await DriverCardsStorage.clearDriverAssignedCardNumbers();
    await ParkingSessionStorage.clearCachedParkedSessions();
    await AppConfigStorage.clear();
    await CooldownStorage.clear();
  }
}
