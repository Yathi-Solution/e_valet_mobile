import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:niloufer_valet_mobile/services/translations/app_translations_notifier.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/button_metrics.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/countdown_cta_button.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/custom_app_bar.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/footer.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/vehicle_photo_placeholder.dart';
import 'package:niloufer_valet_mobile/ui/common/text_constants.dart';
import 'package:niloufer_valet_mobile/ui/driver/driver_home/driver_home.dart';
import 'package:niloufer_valet_mobile/services/oauth/token_interceptor.dart';

class CarSuccessScreen extends StatefulWidget {
  final String? imagePath;
  final bool isLocationBasedParking;

  const CarSuccessScreen({
    super.key,
    this.imagePath,
    this.isLocationBasedParking = false,
  });

  @override
  State<CarSuccessScreen> createState() => _CarSuccessScreenState();
}

class _CarSuccessScreenState extends State<CarSuccessScreen> {
  bool _isReturningHome = false;
  Timer? _autoReturnTimer;

  static const Duration _autoReturnDuration = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    // After a successful park, the previous "pending session" id must be cleared.
    // Otherwise, the pending-session watchdog in `DriverOnlineContent` will detect
    // it as "cancelled" on the next Park attempt and pop the user back to Home.
    TokenStorage.clearSessionId();
    TokenStorage.clearSessionIdFromGetApi();
    // Deferred retrieval ids stay in Hive until Confirm Arrival / handover completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        context
            .read<DriverMenuBloc>()
            .add(const DriverPendingSessionsRefresh());
      } catch (_) {}
    });
    _autoReturnTimer = Timer(_autoReturnDuration, _navigateToHome);
  }

  void _navigateToHome() {
    _autoReturnTimer?.cancel();
    _autoReturnTimer = null;
    if (!mounted) return;
    setState(() => _isReturningHome = true);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const DriverHomeScreen(),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _autoReturnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    final screenWidth = MediaQuery.of(context).size.width;
    final hasImage =
        widget.imagePath != null && widget.imagePath!.trim().isNotEmpty;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.primarySurface,
        appBar: const CustomAppBar(showOverflowMenu: true),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: TextComponent(
                  labelText: t.get(TextConstants.successfullyParked),
                  color: AppColors.headerDark,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
                  child: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(widget.imagePath!),
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return VehiclePhotoPlaceholder(
                                caption: t.get(
                                    TextConstants.tapToCaptureVehiclePhoto),
                                minHeight: 200,
                              );
                            },
                          ),
                        )
                      : widget.isLocationBasedParking
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/images/car.png',
                                width: double.infinity,
                                fit: BoxFit.contain,
                              ),
                            )
                          : VehiclePhotoPlaceholder(
                              caption: t.get(
                                  TextConstants.tapToCaptureVehiclePhoto),
                              minHeight: 200,
                            ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: CountdownCtaButton(
                  label: t.get(TextConstants.returnToHome),
                  isLoading: _isReturningHome,
                  useBigFont: true,
                  height: ButtonMetrics.returnHomeHeight(context),
                  onPressed: () {
                    _autoReturnTimer?.cancel();
                    _autoReturnTimer = null;
                    _navigateToHome();
                  },
                ),
              ),
              const Footer(),
            ],
          ),
        ),
      ),
    );
  }
}
