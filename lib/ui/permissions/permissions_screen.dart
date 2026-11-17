import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/common/widgets/text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:evalet/services/permissions/permissions_service.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/version/version_check_args.dart';
import 'package:evalet/ui/oauth/login/login.dart';
import 'package:evalet/ui/driver/driver_home/driver_home.dart';
import 'package:evalet/ui/operator/operator_dashboard/operator_dashboard.dart';
import 'package:evalet/ui/scanner/scanner_home.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';

/// Full-screen blocking permissions screen (NPCI-style).
/// [args] required when [returnToPrevious] is false (initial flow after version check).
/// When [returnToPrevious] is true (pushed on app resume), on Continue we pop.
class PermissionsScreen extends StatefulWidget {
  final VersionCheckArgs? args;
  final bool returnToPrevious;

  const PermissionsScreen({
    super.key,
    this.args,
    this.returnToPrevious = false,
  }) : assert(
          returnToPrevious || args != null,
          'args is required when returnToPrevious is false (initial flow).',
        );

  @override
  State<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends State<PermissionsScreen>
    with WidgetsBindingObserver {
  Map<Permission, PermissionStatusType> _statuses = {};
  bool _loading = true;
  bool _autoRequestDone = false;

  bool get _isIOS => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshStatuses();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshStatuses();
    }
  }

  Future<void> _refreshStatuses() async {
    setState(() => _loading = true);
    final map = await PermissionsService.checkAllPermissions();
    if (mounted) {
      setState(() {
        _statuses = map;
        _loading = false;
      });
      // After first load, auto-request any permission that is not granted (once per visit).
      // On iOS, avoid auto-requesting camera: we show an explainer first and only request
      // after the user taps "Continue" (Apple HIG / App Review guidance).
      if (!_autoRequestDone &&
          map.values.any((s) => s != PermissionStatusType.granted)) {
        WidgetsBinding.instance
            .addPostFrameCallback((_) => _requestAllNotGranted());
      }
    }
  }

  /// Request each required permission that is not yet granted; update UI after each.
  Future<void> _requestAllNotGranted() async {
    if (!mounted) return;
    setState(() => _autoRequestDone = true);

    for (final permission in PermissionsService.permissionScreenPermissions) {
      if (!mounted) return;
      if (_isIOS && permission == Permission.camera) continue;
      final current = _statuses[permission];
      if (current == PermissionStatusType.granted) continue;

      final status = await PermissionsService.request(permission);
      if (!mounted) return;
      setState(() => _statuses[permission] = status);
      // Do not show bottom sheet during auto-request; only when user taps the row (see _onPermissionTap).
    }
  }

  bool get _allGranted {
    if (_loading || _statuses.isEmpty) return false;
    return PermissionsService.requiredPermissions
        .every((p) => _statuses[p] == PermissionStatusType.granted);
  }

  /// First required permission that is not granted (in order: Location, Camera, Notifications).
  Permission? get _firstMissingPermission {
    if (_loading || _statuses.isEmpty) return null;
    for (final p in PermissionsService.requiredPermissions) {
      if (_statuses[p] != PermissionStatusType.granted) return p;
    }
    return null;
  }

  static String _permissionButtonLabel(Permission permission) {
    // Keep iOS pre-permission CTA neutral per App Review guidance.
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    if (isIOS) return 'Continue';

    // Keep Android wording same as before.
    if (permission == Permission.location) return 'Allow Location';
    if (permission == Permission.camera) return 'Camera';
    if (permission == Permission.notification) return 'Allow Notifications';
    return 'Allow permission';
  }

  Future<void> _showIOSCameraExplainerThenRequest() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      isScrollControlled: false,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                TextComponent(
                  labelText:
                      'Camera access is required to continue. Tap Continue to show the iOS permission prompt.',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                SizedBox(height: 16),
                _IOSContinueButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _onPermissionTap(Permission permission) async {
    if (_isIOS && permission == Permission.camera) {
      await _showIOSCameraExplainerThenRequest();
      if (!mounted) return;
      final status = await PermissionsService.request(permission);
      if (!mounted) return;
      setState(() => _statuses[permission] = status);
      if (status == PermissionStatusType.permanentlyDenied) {
        _showOpenSettingsDialog();
      }
      return;
    }
    final status = await PermissionsService.request(permission);
    if (!mounted) return;
    setState(() => _statuses[permission] = status);
    if (status == PermissionStatusType.permanentlyDenied) {
      _showOpenSettingsDialog();
    }
  }

  void _showOpenSettingsDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.transparent,
      builder: (ctx) {
        final t = ctx.watch<AppTranslationsNotifier>();
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextComponent(
                  labelText:
                      'You denied this permission multiple times. To enable it, open your device settings and turn the permission on for this app.',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.mutedText,
                          side:
                              const BorderSide(color: AppColors.surfaceBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: TextComponent(
                          labelText: t.get(TextConstants.exitButton),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          openAppSettings();
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.qrSuccessColor,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: TextComponent(
                          labelText: t.get(TextConstants.openSettings),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onContinue() {
    if (!_allGranted) return;
    if (widget.returnToPrevious) {
      Navigator.of(context).pop();
      return;
    }
    PermissionsService.setPermissionsCompletedOnce();
    final args = widget.args!;
    if (args.isAuthenticated) {
      final isScanner = args.roles.any((r) => r.contains('scanner'));
      final isOperatorOrAdmin =
          args.roles.any((r) => r.contains('operator') || r.contains('admin'));
      final isDriver = args.roles.any((r) => r.contains('driver'));
      if (isScanner) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ScannerHomeScreen()),
        );
      } else if (isOperatorOrAdmin) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const OperatorDashboardScreen(),
          ),
        );
      } else if (isDriver) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
        );
      } else {
        final t = context.read<AppTranslationsNotifier>();
        SnackBars.showErrorSnackBar(
          context,
          t.get(TextConstants.accountNoPermissionsMessage),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextComponent(
                  labelText: t.get(TextConstants.permissionsRequiredToContinue),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextComponent(
                  labelText: t.get(TextConstants.permissionsDescription),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mutedText,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        children: [
                          _PermissionRow(
                            icon: Icons.location_on_outlined,
                            title: t.get(TextConstants.permissionLocationTitle),
                            description: t.get(
                                TextConstants.permissionLocationDescription),
                            status: _statuses[Permission.location] ??
                                PermissionStatusType.denied,
                            onTap: () => _onPermissionTap(Permission.location),
                          ),
                          const SizedBox(height: 16),
                          _PermissionRow(
                            icon: Icons.camera_alt_outlined,
                            title: t.get(TextConstants.permissionCameraTitle),
                            description: t
                                .get(TextConstants.permissionCameraDescription),
                            status: _statuses[Permission.camera] ??
                                PermissionStatusType.denied,
                            onTap: () => _onPermissionTap(Permission.camera),
                          ),
                          const SizedBox(height: 16),
                          _PermissionRow(
                            icon: Icons.notifications_outlined,
                            title: t.get(
                                TextConstants.permissionNotificationsTitle),
                            description: t.get(TextConstants
                                .permissionNotificationsDescription),
                            status: _statuses[Permission.notification] ??
                                PermissionStatusType.denied,
                            onTap: () =>
                                _onPermissionTap(Permission.notification),
                          ),
                        ],
                      ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _loading
                        ? null
                        : (_allGranted
                            ? _onContinue
                            : () {
                                final missing = _firstMissingPermission;
                                if (missing != null) {
                                  _onPermissionTap(missing);
                                }
                              }),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.qrSuccessColor,
                      disabledBackgroundColor: AppColors.greyLight,
                      foregroundColor: AppColors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: TextComponent(
                      labelText: _allGranted
                          ? t.getByKey(
                              'continueLabel', TextConstants.continueLabel)
                          : (_firstMissingPermission != null
                              ? _permissionButtonLabel(_firstMissingPermission!)
                              : t.getByKey('continueLabel',
                                  TextConstants.continueLabel)),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final PermissionStatusType status;
  final VoidCallback onTap;

  const _PermissionRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.status,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPermanentlyDenied =
        status == PermissionStatusType.permanentlyDenied;
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 26, color: AppColors.primaryDark),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        TextComponent(
                          labelText: title,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.black,
                        ),
                        const SizedBox(width: 8),
                        _StatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    TextComponent(
                      labelText: description,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.mutedText,
                    ),
                    if (isPermanentlyDenied) ...[
                      const SizedBox(height: 6),
                      TextComponent(
                        labelText: context
                            .watch<AppTranslationsNotifier>()
                            .get(TextConstants.permissionDeniedTapSettings),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.mutedText,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IOSContinueButton extends StatelessWidget {
  const _IOSContinueButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        onPressed: () => Navigator.of(context).pop(),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.qrSuccessColor,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const TextComponent(
          labelText: 'Continue',
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final PermissionStatusType status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final allowed = status == PermissionStatusType.granted;
    final permanentlyDenied = status == PermissionStatusType.permanentlyDenied;
    String label;
    Color bgColor;
    Color textColor;
    if (allowed) {
      label = 'Allowed';
      bgColor = AppColors.qrSuccessBg;
      textColor = AppColors.qrSuccessColor;
    } else if (permanentlyDenied) {
      label = 'Open Settings';
      bgColor = AppColors.primarySoft;
      textColor = AppColors.primaryDark;
    } else {
      label = 'Required';
      bgColor = AppColors.primarySoft;
      textColor = AppColors.primaryDark;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextComponent(
        labelText: label,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }
}
