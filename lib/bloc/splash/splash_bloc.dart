import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:niloufer_valet_mobile/api/driver/driver_status_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/my_cards_api_service.dart';
import 'package:niloufer_valet_mobile/api/driver/my_parked_sessions_api_service.dart';
import 'package:niloufer_valet_mobile/api/oauth/profile_api_service.dart';
import 'package:niloufer_valet_mobile/api/outlet/outlet_api_service.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_bloc.dart';
import 'package:niloufer_valet_mobile/models/core/api_exceptions.dart';
import 'package:niloufer_valet_mobile/models/outlet/verify_location_request.dart';
import 'package:niloufer_valet_mobile/services/location/location_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/services/translations/translations_cache.dart';
import 'package:niloufer_valet_mobile/services/websocket/websocket_helper.dart';
import 'splash_event.dart';
import 'splash_state.dart';

class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final WebSocketBloc? webSocketBloc;
  final AppTranslationsNotifier appTranslationsNotifier;

  SplashBloc({this.webSocketBloc, required this.appTranslationsNotifier})
      : super(const SplashInitial()) {
    on<SplashStarted>(_onSplashStarted);
    on<SplashAnimationCompleted>(_onSplashAnimationCompleted);
  }

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashLoading());

    // Ensure translations are loaded/refreshed for current language (on open or install)
    try {
      await TranslationsCache().ensureTranslationsLoaded();
      // Reload in-memory translations so login screen and other UI show translated strings
      await appTranslationsNotifier.load();
    } catch (e, st) {
      // Log translation loading failures instead of silently swallowing them
      print('SplashBloc: Failed to ensure translations are loaded: $e');
      print(st);
    }

    // Simulate loading time or any initialization
    await Future.delayed(const Duration(milliseconds: 500));

    emit(const SplashLoaded());
  }

  Future<void> _onSplashAnimationCompleted(
    SplashAnimationCompleted event,
    Emitter<SplashState> emit,
  ) async {
    // Enforce 3:00 AM daily reset before any auto-login path.
    await SessionManager.enforceDailyResetIfNeeded();

    // Check if user is already logged in
    final isAuthenticated = await SessionManager.isUserLoggedIn();

    if (!isAuthenticated) {
      emit(const SplashCompleted(isAuthenticated: false, roles: []));
      return;
    }

    final profileLoad = await _loadProfileOrOfflineSnapshot();
    if (profileLoad == null) {
      emit(const SplashCompleted(isAuthenticated: false, roles: []));
      return;
    }

    final roles = profileLoad.roles;
    final userId = profileLoad.userId;

    String? outletId;

    // Get outletId if user is operator or scanner (both need outlet room for real-time updates)
    final isOperator = roles.any((r) => r.contains('operator'));
    final isScanner = roles.any((r) => r.contains('scanner'));
    final isAdmin = roles.any((r) => r.contains('admin'));
    final isDriver = roles.any((r) => r.contains('driver'));
    if (isOperator || isScanner) {
      outletId = dotenv.env['OUTLET_ID'] ?? '1';
    }

    // If user is a driver, check status before WebSocket: OFFLINE means session ended → log out and go to login.
    // Only connect WebSocket when driver is ONLINE (or operator).
    if (isDriver) {
      try {
        final driverStatus = await DriverStatusApiService.getDriverStatus();
        if (driverStatus.isOffline) {
          await TokenStorage.clearAll();
          await SessionManager.clearSessionFlags();
          emit(const SplashCompleted(isAuthenticated: false, roles: []));
          return;
        }
      } catch (e) {
        // If status fetch fails (e.g. network), still allow navigation to driver home
        print('Splash: Driver status fetch failed: $e');
      }
    }

    // On splash restore for a driver (app reopen while session still valid for the business day),
    // treat it like a re-login for cards purposes: clear previous allocation data, then fetch
    // the latest cards from GET /drivers/my-cards and store them locally. This keeps the
    // tag/QR submit ownership validation up-to-date without requiring a full logout+login.
    if (isDriver) {
      try {
        final cardsResponse =
            await MyCardsApiService.refreshAssignedCardsLocally();
        print(
          'Driver cards refreshed on splash restore: ${cardsResponse.cards.length} cards',
        );
      } catch (e) {
        print('Splash: Failed to refresh driver cards on restore (non-fatal): $e');
      }

      try {
        final parkedResponse =
            await MyParkedSessionsApiService.refreshParkedSessionsForDisplay();
        print(
          'Driver parked cars refreshed on splash restore: ${parkedResponse.sessionCount} sessions',
        );
      } catch (e) {
        print('Splash: Failed to refresh parked cars on restore (non-fatal): $e');
      }
    }

    // Operator / scanner / admin (same outlet verify as after login): if too far, clear session — mirrors driver OFFLINE gate so refresh cannot open the dashboard.
    final needsOutletLocationVerify =
        !isDriver && (isOperator || isScanner || isAdmin);
    if (needsOutletLocationVerify) {
      final tooFar = await _isTooFarForStoredOutlet();
      if (tooFar) {
        await TokenStorage.clearAll();
        await SessionManager.clearSessionFlags();
        emit(const SplashCompleted(isAuthenticated: false, roles: []));
        return;
      }
    }

    // Initialize WebSocket only when user is allowed to continue (operator, or driver with ONLINE status)
    if (webSocketBloc != null) {
      await WebSocketHelper.connectAfterLogin(
        webSocketBloc: webSocketBloc!,
        outletId: outletId,
        operatorId: isOperator ? userId : null,
        driverId: isDriver ? userId : null,
        initialDelay:
            const Duration(milliseconds: 1500), // Longer delay for splash
      );
    }

    emit(SplashCompleted(isAuthenticated: isAuthenticated, roles: roles));
  }

  /// Loads profile from the network, or last cached roles/user id when the failure
  /// is transient (e.g. no connectivity). Returns null only when login is required.
  Future<({List<String> roles, String userId})?> _loadProfileOrOfflineSnapshot() async {
    try {
      final profile = await ProfileApiService.getProfile();
      final roles = profile.normalizedRoles;
      final userId = profile.user.id;
      await TokenStorage.saveCachedAuthContext(
        normalizedRoles: roles,
        userId: userId,
      );
      return (roles: roles, userId: userId);
    } on ApiException catch (e) {
      print('Splash: Profile fetch failed: $e');
      if (_profileFailureRequiresLogout(e)) {
        return null;
      }
      return _readCachedAuthSnapshot();
    } catch (e) {
      print('Splash: Profile fetch failed: $e');
      return _readCachedAuthSnapshot();
    }
  }

  Future<({List<String> roles, String userId})?> _readCachedAuthSnapshot() async {
    final roles = await TokenStorage.getCachedNormalizedRoles();
    final userId = await TokenStorage.getCachedUserId();
    if (roles == null || roles.isEmpty || userId == null || userId.isEmpty) {
      return null;
    }
    return (roles: roles, userId: userId);
  }

  bool _profileFailureRequiresLogout(ApiException e) {
    if (e.code == 'no_token') return true;
    if (e.code == 'session_expired') return true;
    if (e.code == 'no_refresh') return true;
    if (e.statusCode == 401) return true;
    return false;
  }

  /// Same location check as [LoginBloc] after outlet selection. Returns true if user must not enter the app.
  Future<bool> _isTooFarForStoredOutlet() async {
    var outletId = await TokenStorage.getSelectedOutletId();
    outletId ??= int.tryParse(dotenv.env['OUTLET_ID'] ?? '');
    if (outletId == null) {
      return false;
    }

    double latitude;
    double longitude;
    double accuracy;

    try {
      final coordinates = await LocationService.getCurrentCoordinates();
      latitude = coordinates['latitude']!;
      longitude = coordinates['longitude']!;
      accuracy = coordinates['accuracy']!;

      final location =
          '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
      await TokenStorage.saveCurrentLocation(
        latitude: latitude,
        longitude: longitude,
        location: location,
      );
    } catch (e) {
      print('Splash: Failed to get location for verify-location: $e');
      latitude = 0.0;
      longitude = 0.0;
      accuracy = 0.0;
    }

    try {
      final response = await OutletApiService.verifyLocation(
        outletId,
        VerifyLocationRequest(
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
        ),
      );
      return !response.withinBounds;
    } on ApiException catch (e) {
      if (_isLocationTooFarMessage(e.message)) return true;
      print('Splash: verify-location ApiException: ${e.message}');
      return false;
    } catch (e) {
      print('Splash: verify-location failed: $e');
      return false;
    }
  }

  bool _isLocationTooFarMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('too far') ||
        (lower.contains('distance') && lower.contains('allowed'));
  }
}
