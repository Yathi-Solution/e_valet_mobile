import 'dart:async';
import 'dart:developer';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:evalet/api/driver/config_api_service.dart';
import 'package:evalet/api/driver/driver_status_api_service.dart';
import 'package:evalet/api/driver/my_cards_api_service.dart';
import 'package:evalet/api/driver/my_parked_sessions_api_service.dart';
import 'package:evalet/api/oauth/login_api_service.dart';
import 'package:evalet/api/outlet/outlet_api_service.dart';
import 'package:evalet/bloc/websocket/websocket_bloc.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/status/clock_in_request.dart';
import 'package:evalet/models/oauth/login_result.dart';
import 'package:evalet/models/oauth/profile.dart';
import 'package:evalet/models/outlet/outlet.dart';
import 'package:evalet/models/outlet/verify_location_request.dart';
import 'package:evalet/models/outlet/verify_location_response.dart';
import 'package:evalet/services/location/location_service.dart';
import 'package:evalet/services/notification/firebase_messaging_service.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/services/connectivity/driver_connectivity_log_service.dart';
import 'package:evalet/services/websocket/websocket_helper.dart';
import 'package:evalet/api/driver/connectivity_settings_api_service.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final FirebaseMessagingService? firebaseMessagingService;
  final WebSocketBloc? webSocketBloc;

  LoginBloc({
    this.firebaseMessagingService,
    this.webSocketBloc,
  }) : super(const LoginInitial()) {
    on<LoginIdChanged>(_onLoginIdChanged);
    on<LoginSubmitted>(_onLoginSubmitted);
    on<RequestLoginCode>(_onRequestLoginCode);
    on<VerifyLoginCode>(_onVerifyLoginCode);
    on<ResendLoginCode>(_onResendLoginCode);
    on<ChangeLoginPhone>(_onChangeLoginPhone);
    on<ClientSelected>(_onClientSelected);
    on<OutletSelected>(_onOutletSelected);
    on<LoginReset>(_onLoginReset);
  }

  String _loginId = '';

  // Preserved across the outlet selection step
  Profile? _pendingProfile;
  bool _pendingIsDriver = false;
  bool _pendingIsOperator = false;
  bool _pendingIsScanner = false;

  void _onLoginIdChanged(
    LoginIdChanged event,
    Emitter<LoginState> emit,
  ) {
    _loginId = event.loginId.trim();
  }

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    add(const RequestLoginCode());
  }

  Future<void> _onRequestLoginCode(
    RequestLoginCode event,
    Emitter<LoginState> emit,
  ) async {
    await _requestCode(emit, channel: null);
  }

  Future<void> _onResendLoginCode(
    ResendLoginCode event,
    Emitter<LoginState> emit,
  ) async {
    await _requestCode(emit, channel: event.channel, resend: true);
  }

  Future<void> _requestCode(
    Emitter<LoginState> emit, {
    required String? channel,
    bool resend = false,
  }) async {
    if (_loginId.isEmpty) {
      emit(LoginFailure(TextConstants.validationPhoneRequired));
      return;
    }

    emit(const LoginLoading());
    try {
      await LoginApiService.requestLoginCode(_loginId, channel: channel);
      emit(LoginCodeSent(_loginId));
    } on ApiException catch (e) {
      emit(_failureForCodeRequest(e, resend: resend));
    } catch (_) {
      emit(LoginFailure(
        'Something went wrong. Please try again.',
        phone: resend ? _loginId : null,
      ));
    }
  }

  LoginFailure _failureForCodeRequest(ApiException e, {required bool resend}) {
    final onCode = resend ? _loginId : null;
    if (e.statusCode == 429 || e.code == 'TOO_MANY_REQUESTS') {
      return LoginFailure(
        'Too many attempts. Wait a few minutes and try again.',
        phone: onCode,
        rateLimited: true,
      );
    }
    if (e.code == 'INVALID_PHONE') {
      return const LoginFailure('Enter a valid phone number.');
    }
    if (e.statusCode == 400 && e.code == 'http_error') {
      return LoginFailure(
        'Something went wrong. Please try again.',
        phone: onCode,
      );
    }
    return LoginFailure(e.displayMessage, phone: onCode);
  }

  Future<void> _onVerifyLoginCode(
    VerifyLoginCode event,
    Emitter<LoginState> emit,
  ) async {
    final code = event.code.trim();
    if (_loginId.isEmpty) {
      emit(LoginFailure(TextConstants.validationPhoneRequired));
      return;
    }
    if (code.length != 6) {
      emit(LoginFailure(
        'Enter the 6-digit code.',
        phone: _loginId,
      ));
      return;
    }

    emit(LoginCodeVerifying(_loginId));
    try {
      final LoginResult result = await LoginApiService.verifyLoginCode(
        phone: _loginId,
        code: code,
      );
      await _afterLoginResult(result, emit);
    } on ApiException catch (e) {
      emit(_failureForVerify(e));
    } catch (_) {
      emit(LoginFailure(
        'Something went wrong. Please try again.',
        phone: _loginId,
      ));
    }
  }

  LoginFailure _failureForVerify(ApiException e) {
    if (e.code == 'INVALID_LOGIN_CODE' || e.statusCode == 401) {
      return LoginFailure(
        'Wrong or expired code.',
        phone: _loginId,
        clearCode: true,
      );
    }
    if (e.statusCode == 429 || e.code == 'TOO_MANY_REQUESTS') {
      return LoginFailure(
        'Too many attempts. Wait a few minutes and try again.',
        phone: _loginId,
        rateLimited: true,
      );
    }
    if (e.code == 'INVALID_PHONE') {
      return const LoginFailure('Enter a valid phone number.');
    }
    if (e.code == 'NO_ACTIVE_CLIENT') {
      return LoginFailure(e.displayMessage);
    }
    if (e.statusCode == 400 && e.code == 'http_error') {
      return LoginFailure(
        'Something went wrong. Please try again.',
        phone: _loginId,
        clearCode: true,
      );
    }
    return LoginFailure(e.displayMessage, phone: _loginId);
  }

  void _onChangeLoginPhone(
    ChangeLoginPhone event,
    Emitter<LoginState> emit,
  ) {
    emit(const LoginInitial());
  }

  Future<void> _afterLoginResult(
    LoginResult result,
    Emitter<LoginState> emit,
  ) async {
    if (result.needsClientSelection) {
      if (result.clients.isEmpty) {
        emit(const LoginFailure(
          'No active client is available for your account. Please contact your administrator.',
        ));
        return;
      }
      emit(LoginNeedsClientSelection(result.clients));
      return;
    }

    await _continueAfterProfile(result.profile!, emit);
  }

  Future<void> _onClientSelected(
    ClientSelected event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());
    try {
      final profile = await LoginApiService.selectClient(event.clientId);
      await _continueAfterProfile(profile, emit);
    } on ApiException catch (e) {
      emit(_failureForClientSelect(e));
    } catch (_) {
      emit(
        const LoginFailure('Something went wrong. Please try again.'),
      );
    }
  }

  LoginFailure _failureForClientSelect(ApiException e) {
    const stay = {
      'CLIENT_NOT_AVAILABLE',
      'CLIENT_SUSPENDED',
      'CLIENT_PROVISIONING',
    };
    if (stay.contains(e.code)) {
      return LoginFailure(e.displayMessage, keepDialog: true);
    }
    return LoginFailure(e.displayMessage);
  }

  /// Shared by direct Client login and the Client-select step.
  Future<void> _continueAfterProfile(
    Profile profile,
    Emitter<LoginState> emit,
  ) async {
    if (profile.roles.isEmpty) {
      emit(
        const LoginFailure(
          'No roles are assigned to your account. Please contact your administrator to request access.',
        ),
      );
      return;
    }

    // Register FCM token after successful login
    try {
      await firebaseMessagingService?.registerFcmTokenAfterLogin();
      log('FCM token registration initiated after login');
    } catch (e) {
      log('Failed to register FCM token after login: $e');
    }

    final roles = profile.roles.map((r) => r.toLowerCase()).toList();
    _pendingProfile = profile;
    _pendingIsDriver = roles.any((r) => r.contains('driver'));
    // CLIENT_ADMIN can use every Operator API, so it gets the operator desk.
    _pendingIsOperator =
        roles.any((r) => r.contains('operator') || r.contains('admin'));
    _pendingIsScanner = roles.any((r) => r.contains('scanner'));

    if (_pendingIsDriver) {
      await TokenStorage.clearDriverAssignedCardNumbersIfPresent();
      await TokenStorage.markDriverAssignedCardsLoading();
      await MyParkedSessionsApiService.clearCache();
    }

    // Fetch outlets so the user can pick one before clock-in / verify-location
    final outlets = await OutletApiService.getOutlets();

    // Only one outlet available: skip the picker and continue with it directly.
    // The state stays [LoginLoading] so the login button keeps its spinner.
    if (outlets.length == 1) {
      await _completeOutletSelection(outlets.first, emit);
      return;
    }

    emit(LoginSuccessNeedsOutletSelection(
      profile: profile,
      outlets: outlets,
      isDriver: _pendingIsDriver,
      isOperator: _pendingIsOperator,
      isScanner: _pendingIsScanner,
    ));
  }

  Future<void> _onOutletSelected(
    OutletSelected event,
    Emitter<LoginState> emit,
  ) async {
    if (_pendingProfile == null) return;

    emit(const LoginOutletSelectionLoading());

    await _completeOutletSelection(event.outlet, emit);
  }

  /// Clock-in / verify-location for the chosen [outlet]. Used both when the
  /// user picks from the dialog and when there is only one outlet.
  Future<void> _completeOutletSelection(
    Outlet outlet,
    Emitter<LoginState> emit,
  ) async {
    final profile = _pendingProfile;
    if (profile == null) return;

    try {
      // Get the user's current location (shared by both driver and operator/scanner paths)
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
        log('Failed to get location after outlet selection: $e');
        latitude = 0.0;
        longitude = 0.0;
        accuracy = 0.0;
      }

      final userId = profile.user.id;

      if (_pendingIsDriver) {
        // Driver: require successful clock-in (HTTP 2xx) before persisting outlet,
        // connecting WebSocket, or completing login. Avoids "logged in" when API errors.
        final clockInError = await _clockInAfterLogin(
          outletId: outlet.id,
          latitude: latitude,
          longitude: longitude,
          accuracy: accuracy,
        );
        if (clockInError != null) {
          if (_isLocationTooFarMessage(clockInError)) {
            await TokenStorage.clearCurrentLocation();
            emit(LoginSuccessClockInTooFar(
              profile: profile,
              message: clockInError,
              outlet: outlet,
            ));
          } else {
            emit(LoginFailure(clockInError));
          }
          return;
        }

        await TokenStorage.saveSelectedOutlet(
          outletId: outlet.id,
          outletName: outlet.name,
        );
        dotenv.env['OUTLET_ID'] = outlet.id.toString();

        try {
          if (webSocketBloc != null) {
            await WebSocketHelper.connectAfterLogin(
              webSocketBloc: webSocketBloc!,
              outletId: null,
              operatorId: null,
              driverId: userId,
              initialDelay: const Duration(milliseconds: 500),
            );
            log('WebSocket connection initiated after outlet selection');
          }
        } catch (e) {
          log('Failed to connect WebSocket after outlet selection: $e');
        }

        await _fetchAndStoreConfig();

        // Fetch assigned cards in the background; stored locally for scan validation.
        unawaited(MyCardsApiService.refreshAssignedCardsInBackground());

        try {
          final parkedResponse = await MyParkedSessionsApiService
              .refreshParkedSessionsForDisplay();
          log(
            'Driver parked cars refreshed on (re)login: ${parkedResponse.sessionCount} sessions',
          );
        } catch (e) {
          log('Failed to refresh parked cars on (re)login (non-fatal): $e');
        }

        // IMPORTANT:
        // Fetch driver connectivity settings after every successful login.
        // This calls the correct GET /connectivity/settings/me?outletId=...
        // We clear any previously stored settings first, then store the fresh response.
        await _fetchDriverConnectivitySettings(outletId: outlet.id);

        emit(LoginSuccess(profile));
        return;
      }

      // Operator / Scanner: persist outlet and connect before verify-location
      await TokenStorage.saveSelectedOutlet(
        outletId: outlet.id,
        outletName: outlet.name,
      );
      dotenv.env['OUTLET_ID'] = outlet.id.toString();

      try {
        if (webSocketBloc != null) {
          await WebSocketHelper.connectAfterLogin(
            webSocketBloc: webSocketBloc!,
            outletId: outlet.id.toString(),
            operatorId: _pendingIsOperator ? userId : null,
            driverId: null,
            initialDelay: const Duration(milliseconds: 500),
          );
          log('WebSocket connection initiated after outlet selection');
        }
      } catch (e) {
        log('Failed to connect WebSocket after outlet selection: $e');
      }

      // Operator / Scanner: verify location via dedicated endpoint
      final verifyRequest = VerifyLocationRequest(
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
      late final VerifyLocationResponse verifyResponse;
      try {
        verifyResponse = await OutletApiService.verifyLocation(
          outlet.id,
          verifyRequest,
        );
      } on ApiException catch (e) {
        // Backend may return 4xx with a message instead of 200 + withinBounds: false.
        if (_isLocationTooFarMessage(e.message)) {
          await TokenStorage.clearCurrentLocation();
          emit(LoginSuccessLocationTooFar(
            profile: profile,
            outletId: outlet.id,
            outletName: outlet.name,
            distanceMeters: 0,
            allowedRadiusMeters: 0,
            detailMessage: e.message,
          ));
          return;
        }
        rethrow;
      }

      if (!verifyResponse.withinBounds) {
        await TokenStorage.clearCurrentLocation();
        emit(LoginSuccessLocationTooFar(
          profile: profile,
          outletId: verifyResponse.outletId,
          outletName: verifyResponse.outletName,
          distanceMeters: verifyResponse.distanceMeters,
          allowedRadiusMeters: verifyResponse.allowedRadiusMeters,
        ));
        return;
      }

      await _fetchAndStoreConfig();

      emit(LoginSuccess(profile));
    } on ApiException catch (e) {
      emit(LoginFailure(e.message));
    } catch (_) {
      emit(
        const LoginFailure('Something went wrong. Please try again.'),
      );
    }
  }

  Future<void> _fetchAndStoreConfig() async {
    try {
      final config = await ConfigApiService.getConfig();
      await TokenStorage.saveButtonConfig(
        confirmArrivalDisableSeconds: config.confirmArrivalDisableSeconds,
        customerMissingDisableSeconds: config.customerMissingDisableSeconds,
        confirmHandoverDisableSeconds: config.confirmHandoverDisableSeconds,
        scannerButtonStatus: config.scannerButtonStatus,
        imageCompressionQuality: config.imageCompressionQuality,
        imageCompressionMaxSizeKB: config.imageCompressionMaxSizeKB,
      );
      log(
        'Config updated: confirmArrival=${config.confirmArrivalDisableSeconds}s, '
        'customerMissing=${config.customerMissingDisableSeconds}s, '
        'confirmHandover=${config.confirmHandoverDisableSeconds}s, '
        'scannerButtonStatus=${config.scannerButtonStatus}, '
        'imageQuality=${config.imageCompressionQuality}, '
        'imageMaxKB=${config.imageCompressionMaxSizeKB}',
      );
    } catch (e) {
      // Non-blocking by design: login should continue with env defaults.
      log('Failed to fetch config after login: $e');
    }
  }

  /// Fetches driver connectivity settings after every successful driver login.
  ///
  /// Uses the correct endpoint: GET /connectivity/settings/me?outletId=...
  ///
  /// Behavior:
  /// - First clears any previously stored connectivity settings from local storage.
  /// - Then calls the API.
  /// - If successful, stores the fresh outletId + isEnabled locally.
  /// - This is non-fatal: login continues even if the call fails or returns null.
  Future<void> _fetchDriverConnectivitySettings({
    required int outletId,
  }) async {
    try {
      // Clear previous data on every new login (silent)
      await TokenStorage.clearDriverConnectivitySettings();

      final settings =
          await ConnectivitySettingsApiService.getDriverConnectivitySettings(
        outletId: outletId,
      );

      if (settings != null) {
        // Persist the fresh data from this login (silent on success)
        await TokenStorage.saveDriverConnectivitySettings(
          outletId: settings.outletId,
          isEnabled: settings.isEnabled,
        );
        await DriverConnectivityLogService.instance.onDriverLoginSessionStarted(
          isEnabled: settings.isEnabled,
        );
      }
      // On null or any non-error path: completely silent
    } catch (e, st) {
      // Only log on real unexpected failure
      log('[Login] Failed to fetch driver connectivity settings (non-fatal): $e');
      log(st.toString());
    }
  }

  void _onLoginReset(
    LoginReset event,
    Emitter<LoginState> emit,
  ) {
    _pendingProfile = null;
    _pendingIsDriver = false;
    _pendingIsOperator = false;
    _pendingIsScanner = false;
    emit(const LoginInitial());
  }

  /// Returns error message if clock-in failed, null if succeeded.
  Future<String?> _clockInAfterLogin({
    required int outletId,
    required double latitude,
    required double longitude,
    required double accuracy,
  }) async {
    try {
      log('Starting automatic clock-in after outlet selection...');
      final clockInRequest = ClockInRequest(
        outletId: outletId,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
      final clockInResponse =
          await DriverStatusApiService.clockIn(clockInRequest);
      await DriverConnectivityLogService.instance.onShiftActiveAfterClockIn(
        shiftId: clockInResponse.shiftId,
        outletId: clockInResponse.outletId,
      );
      log('Automatic clock-in successful after outlet selection');
      return null;
    } on ApiException catch (e) {
      log('Failed to clock in after outlet selection: ${e.message}');
      return e.message;
    } catch (e) {
      log('Failed to clock in after outlet selection: $e');
      return 'Clock-in failed. Please try again.';
    }
  }

  bool _isLocationTooFarMessage(String message) {
    final lower = message.toLowerCase();
    return lower.contains('too far') ||
        (lower.contains('distance') && lower.contains('allowed'));
  }
}
