import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:evalet/bloc/driver/driver_home/driver_menu_state.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_event.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_state.dart';
import 'package:evalet/ui/driver/driver_home/driver_home_content.dart';

class DriverHomeView extends StatelessWidget {
  const DriverHomeView({super.key, this.homeResetNotifier});

  /// When this notifier's value changes, driver home content resets to show home (two cards).
  final ValueNotifier<int>? homeResetNotifier;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverMenuBloc, DriverMenuState>(
      builder: (context, menuState) {
        if (menuState is! DriverHomeLoaded) {
          // Trigger loading if not already loaded
          if (menuState is DriverMenuInitial) {
            context.read<DriverMenuBloc>().add(const DriverHomeStarted());
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final driverName = menuState.driverName;
        final retrievePendingCount =
            menuState.pendingSessions?.retrievalTasksCount ?? 0;

        // Get online status and break status from DriverStatusBloc, fallback to menu state
        return BlocBuilder<DriverStatusBloc, DriverStatusState>(
          builder: (context, statusState) {
            final isOnline = statusState is DriverStatusLoaded
                ? statusState.status.isOnline
                : menuState.isOnline;
            final isOnBreak = statusState is DriverStatusLoaded
                ? statusState.status.isOnBreak
                : menuState.isOnBreak;

            return DriverHomeContent(
              driverName: driverName,
              isOnBreak: isOnBreak,
              isOnline: isOnline,
              retrievePendingCount: retrievePendingCount,
              onBreakEnd: () {
                context
                    .read<DriverStatusBloc>()
                    .add(const DriverBreakToggled(false));
              },
              homeResetNotifier: homeResetNotifier,
            );
          },
        );
      },
    );
  }
}
