import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_state.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/app_logo.dart';
import 'package:niloufer_valet_mobile/ui/oauth/profile/overflow_menu.dart';
import 'package:niloufer_valet_mobile/ui/common/translations/language_dropdown_button.dart';
import 'package:niloufer_valet_mobile/ui/driver/parked_cars/widgets/parked_cars_app_bar_action.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onLogoTap;
  final bool showLanguageIcon;
  final bool showScannerIcon;
  final bool showOverflowMenu;
  final bool showParkedCarsAction;

  /// When true, never show the parked cars (car icon) action in the app bar,
  /// even if a DriverMenuBloc reports a loaded driver session.
  /// Use this on login, forgot-password, and other pre-home auth screens.
  final bool hideParkedCarsAction;

  final VoidCallback? onScannerTap;
  final double? logoSize;
  final double? iconSize;

  /// Default app bar action icon size for a given screen width.
  static double resolveIconSize(double screenWidth) => screenWidth * 0.06;

  const CustomAppBar({
    super.key,
    this.leading,
    this.actions,
    this.onLogoTap,
    this.showLanguageIcon = false,
    this.showScannerIcon = false,
    this.showOverflowMenu = false,
    this.showParkedCarsAction = false,
    this.hideParkedCarsAction = false,
    this.onScannerTap,
    this.logoSize,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final defaultLogoSize = logoSize ?? 48;
    final logoHeight =
        defaultLogoSize.clamp(0.0, kToolbarHeight - 8).toDouble();
    final defaultIconSize = iconSize ?? screenWidth * 0.06;

    // Build actions:
    // - If [actions] is provided, use it as-is (caller fully controls the right side).
    // - Otherwise, optionally show language selector and/or the overflow menu.
    List<Widget>? appBarActions;
    if (actions != null) {
      appBarActions = actions;
    } else {
      final built = <Widget>[];
      if (showScannerIcon) {
        built.add(
          IconButton(
            tooltip: 'Scanner',
            icon: Icon(
              Icons.qr_code_scanner,
              color: AppColors.white,
              size: defaultIconSize,
            ),
            onPressed: onScannerTap,
          ),
        );
        built.add(SizedBox(width: screenWidth * 0.01));
      }
      if (showLanguageIcon) {
        built.add(LanguageDropdownButton(iconSize: defaultIconSize));
        built.add(SizedBox(width: screenWidth * 0.04));
      }

      DriverMenuBloc? driverMenuBloc;
      try {
        driverMenuBloc =
            BlocProvider.of<DriverMenuBloc>(context, listen: false);
      } catch (_) {
        driverMenuBloc = null;
      }

      final isDriverSession = driverMenuBloc?.state is DriverHomeLoaded;

      // Only show the parked cars (car icon + count) button if:
      // - not explicitly hidden (for login / auth screens), AND
      // - either forced via showParkedCarsAction or we are in an active driver session.
      final showParkedCars =
          !hideParkedCarsAction && (showParkedCarsAction || isDriverSession);

      if (showParkedCars && driverMenuBloc != null) {
        built.add(ParkedCarsAppBarAction(iconSize: defaultIconSize));
        built.add(SizedBox(width: screenWidth * 0.01));
      }

      if (showOverflowMenu && driverMenuBloc != null) {
        built.add(const OverflowMenu());
        built.add(SizedBox(width: screenWidth * 0.04));
      }
      appBarActions = built.isEmpty ? null : built;
    }

    return AppBar(
      backgroundColor: AppColors.nearBlack,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: leading,
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onLogoTap,
        child: AppLogo(height: logoHeight, onDarkBackground: true),
      ),
      actions: appBarActions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
