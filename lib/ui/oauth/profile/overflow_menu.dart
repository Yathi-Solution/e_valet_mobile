import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:evalet/bloc/scanner/scanner_menu/scanner_menu_bloc.dart';
import 'package:evalet/bloc/scanner/scanner_menu/scanner_menu_event.dart';
import 'package:evalet/services/translations/app_translations_notifier.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/text_constants.dart';
import 'package:evalet/ui/driver/driver_cards/my_cards_screen.dart';
import 'package:evalet/ui/guidelines/guidelines_screen.dart';
import 'package:evalet/ui/help_support/help_screen.dart';
import 'package:evalet/ui/oauth/profile/profile_screen.dart';
import 'package:pull_down_button/pull_down_button.dart';

/// App bar overflow menu. When [scannerMode] is true, shows only Profile and
/// Logout (uses [ScannerMenuBloc]). Otherwise shows Profile, Help, Guidelines,
/// Logout (uses [DriverMenuBloc]).
class OverflowMenu extends StatelessWidget {
  const OverflowMenu({super.key, this.scannerMode = false});

  final bool scannerMode;

  @override
  Widget build(BuildContext context) {
    final t = context.watch<AppTranslationsNotifier>();
    return PullDownButton(
      itemBuilder: (context) {
        if (scannerMode) {
          return [
            PullDownMenuItem(
              title: t.get(TextConstants.profileMenuTitle),
              icon: Icons.person_outline,
              onTap: () {
                context
                    .read<ScannerMenuBloc>()
                    .add(const ScannerProfilePressed());
              },
            ),
            const PullDownMenuDivider(),
            PullDownMenuItem(
              title: t.get(TextConstants.logoutMenuTitle),
              icon: Icons.logout,
              onTap: () {
                context
                    .read<ScannerMenuBloc>()
                    .add(const ScannerLogoutPressed());
              },
            ),
          ];
        }
        return [
          PullDownMenuItem(
            title: t.get(TextConstants.profileMenuTitle),
            icon: Icons.person_outline,
            onTap: () {
              // Navigate from the current screen so back returns here.
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
          PullDownMenuItem(
            title: t.get(TextConstants.helpMenuTitle),
            icon: Icons.support_agent,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpScreen()),
              );
            },
          ),
          PullDownMenuItem(
            title: t.get(TextConstants.guidelinesMenuTitle),
            icon: Icons.menu_book_outlined,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const GuidelinesScreen()),
              );
            },
          ),
          PullDownMenuItem(
            title: t.get(TextConstants.cards),
            icon: Icons.credit_card,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyCardsScreen()),
              );
            },
          ),
          const PullDownMenuDivider(),
          PullDownMenuItem(
            title: t.get(TextConstants.logoutMenuTitle),
            icon: Icons.logout,
            onTap: () {
              // Logout stays bloc-driven because it handles pre-check + clock-out + token clear.
              context.read<DriverMenuBloc>().add(const DriverLogoutPressed());
            },
          ),
        ];
      },
      buttonBuilder: (context, showMenu) {
        return IconButton(
          icon: const Icon(
            Icons.more_vert,
            color: AppColors.white,
          ),
          onPressed: showMenu,
        );
      },
    );
  }
}
