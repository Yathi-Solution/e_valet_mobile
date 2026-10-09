import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/splash/splash_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/websocket/websocket_event.dart';
import 'package:niloufer_valet_mobile/services/notification/firebase_messaging_service.dart';
import 'package:niloufer_valet_mobile/services/oauth/session_manager.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';
import 'package:niloufer_valet_mobile/services/version/version_service.dart';
import 'package:niloufer_valet_mobile/ui/oauth/splash/splash.dart';
import 'package:niloufer_valet_mobile/services/background/background_sync_service.dart';
import 'package:niloufer_valet_mobile/services/offline_sync/offline_parking_service.dart';
import 'package:niloufer_valet_mobile/models/driver/session/checkin_request_adapter.dart';
import 'package:niloufer_valet_mobile/models/driver/session/offline_checkin_request.dart';
import 'package:niloufer_valet_mobile/models/driver/park/offline_parking_photo.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/bloc/connectivity/connectivity_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/connectivity/connectivity_event.dart';
import 'package:niloufer_valet_mobile/api/oauth/refresh_api_service.dart';
import 'package:niloufer_valet_mobile/services/permissions/permissions_service.dart';
import 'package:niloufer_valet_mobile/ui/oauth/login/login.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/snack_bar.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/driver_home_route_observer.dart';
import 'package:niloufer_valet_mobile/ui/permissions/permissions_screen.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/typography.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Initialize Hive for local storage
  await Hive.initFlutter();
  final checkinRequestAdapter = CheckinRequestAdapter();
  if (!Hive.isAdapterRegistered(checkinRequestAdapter.typeId)) {
    Hive.registerAdapter(checkinRequestAdapter);
  }
  final offlineParkingPhotoAdapter = OfflineParkingPhotoAdapter();
  if (!Hive.isAdapterRegistered(offlineParkingPhotoAdapter.typeId)) {
    Hive.registerAdapter(offlineParkingPhotoAdapter);
  }
  final offlineCheckinRequestAdapter = OfflineCheckinRequestAdapter();
  if (!Hive.isAdapterRegistered(offlineCheckinRequestAdapter.typeId)) {
    Hive.registerAdapter(offlineCheckinRequestAdapter);
  }
  await OfflineParkingService.init();
  await TokenStorage.init();
  await VersionService.init();

  // Restore the outlet ID that the user selected on their last login so
  // ApiConfig.outletId and authorizedHeaders stay consistent across restarts.
  final savedOutletId = await TokenStorage.getSelectedOutletId();
  if (savedOutletId != null) {
    dotenv.env['OUTLET_ID'] = savedOutletId.toString();
  }

  // Initialize Background Sync
  await BackgroundSyncService.init();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize Firebase Messaging Service
  final firebaseMessagingService = FirebaseMessagingService();
  await firebaseMessagingService.initialize();

  // When refresh returns 401 (e.g. logged in on another device), clear is done in RefreshApiService; show message and go to login.
  RefreshApiService.onSessionEnded = (message) {
    final ctx = FirebaseMessagingService.navigatorKey.currentContext;
    if (ctx != null) {
      SnackBars.showErrorSnackBar(ctx, message);
      Navigator.of(ctx).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  };

  runApp(MyApp(firebaseMessagingService: firebaseMessagingService));
}

class MyApp extends StatelessWidget {
  final FirebaseMessagingService firebaseMessagingService;

  const MyApp({super.key, required this.firebaseMessagingService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Provide FirebaseMessagingService to the entire app
        Provider<FirebaseMessagingService>.value(
          value: firebaseMessagingService,
        ),
        // In-memory translations; load() runs on create and when user changes language
        ChangeNotifierProvider(
          create: (_) => AppTranslationsNotifier()..load(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<WebSocketBloc>(
            create: (context) => WebSocketBloc(),
            lazy: false,
          ),
          BlocProvider<SplashBloc>(
            create: (context) => SplashBloc(
              webSocketBloc: context.read<WebSocketBloc>(),
              appTranslationsNotifier: context.read<AppTranslationsNotifier>(),
            ),
          ),
          BlocProvider<DriverStatusBloc>(
            create: (context) => DriverStatusBloc(),
          ),
          // Provide globally so the app-bar overflow menu works on any driver route.
          BlocProvider<DriverMenuBloc>(
            create: (context) => DriverMenuBloc(),
          ),
          // Add ConnectivityBloc
          BlocProvider<ConnectivityBloc>(
            create: (context) => ConnectivityBloc(),
            lazy: false, // Start listening immediately
          ),
        ],
        child: MaterialApp(
          title: dotenv.env['APP_NAME'] ?? 'ValetLink',
          navigatorKey: FirebaseMessagingService.navigatorKey,
          navigatorObservers: [DriverHomeRouteObserver()],
          home: const SplashScreen(),
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: AppTypography.primaryFamily,
            fontFamilyFallback: AppTypography.fallbackFamilies,
            scaffoldBackgroundColor: AppColors.primarySurface,
            colorScheme: ColorScheme.fromSeed(
              seedColor: AppColors.headerDark,
              primary: AppColors.headerDark,
              onPrimary: AppColors.textOnDark,
              surface: AppColors.primarySurface,
              onSurface: AppColors.bodyText,
              onSurfaceVariant: AppColors.mutedText,
            ),
            cardTheme: const CardThemeData(
              color: AppColors.primarySurface,
              surfaceTintColor: Colors.transparent,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: AppColors.headerDark,
              foregroundColor: AppColors.textOnDark,
              elevation: 0,
              scrolledUnderElevation: 0,
              shadowColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.headerDark,
                foregroundColor: AppColors.textOnDark,
                elevation: 0,
              ),
            ),
            textTheme: TextTheme(
              displayLarge: AppTypography.heroStyle,
              headlineMedium: AppTypography.sectionStyle,
              titleMedium: AppTypography.subheadingStyle,
              bodyMedium: AppTypography.bodyStyle,
              labelSmall: AppTypography.labelStyle,
            ).apply(
              bodyColor: AppColors.bodyText,
              displayColor: AppColors.bodyText,
            ),
          ),
          builder: (context, child) {
            return _AppLifecycleHandler(
              child: child ?? const SizedBox.shrink(),
            );
          },
        ),
      ),
    );
  }
}

/// Listens to app lifecycle and triggers WebSocket reconnect when app
/// returns from background (e.g. user opens app from push notification).
class _AppLifecycleHandler extends StatefulWidget {
  final Widget child;

  const _AppLifecycleHandler({required this.child});

  @override
  State<_AppLifecycleHandler> createState() => _AppLifecycleHandlerState();
}

class _AppLifecycleHandlerState extends State<_AppLifecycleHandler>
    with WidgetsBindingObserver {
  bool _isShowingPermissionsScreen = false;
  Timer? _dailyResetTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleDailyResetTimer();
  }

  @override
  void dispose() {
    _dailyResetTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      try {
        context.read<WebSocketBloc>().add(const ReconnectWebSocket());
      } catch (_) {}
      try {
        context.read<ConnectivityBloc>().add(CheckConnectivity());
      } catch (_) {}
      _enforceDailyResetIfNeeded();
      _scheduleDailyResetTimer();
      _checkPermissionsOnResume();
    }
  }

  void _scheduleDailyResetTimer() {
    _dailyResetTimer?.cancel();
    final now = DateTime.now();
    final nextResetAt = SessionManager.nextDailyResetAt(now);
    final wait = nextResetAt.difference(now);
    _dailyResetTimer = Timer(wait, () async {
      await _enforceDailyResetIfNeeded();
      _scheduleDailyResetTimer();
    });
  }

  Future<void> _enforceDailyResetIfNeeded() async {
    final didReset = await SessionManager.enforceDailyResetIfNeeded();
    if (!didReset || !mounted) return;
    final ctx = FirebaseMessagingService.navigatorKey.currentContext;
    if (ctx == null) return;
    SnackBars.showErrorSnackBar(
      ctx,
      'Session expired for the new day. Please login again.',
    );
    Navigator.of(ctx).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  Future<void> _checkPermissionsOnResume() async {
    if (!PermissionsService.permissionsCompletedOnce) return;
    if (_isShowingPermissionsScreen) return;
    final allGranted = await PermissionsService.areAllGranted();
    if (allGranted) return;
    if (!mounted) return;
    _isShowingPermissionsScreen = true;
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (_) => const PermissionsScreen(returnToPrevious: true),
      ),
    )
        .then((_) {
      if (mounted) {
        setState(() => _isShowingPermissionsScreen = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
