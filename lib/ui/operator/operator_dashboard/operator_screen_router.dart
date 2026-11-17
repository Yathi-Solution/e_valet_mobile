import 'package:flutter/material.dart';
import 'package:evalet/ui/operator/operator_drivers/operator_drivers_screen.dart';
import 'package:evalet/ui/operator/operator_car_logs/operator_car_logs_screen.dart';
import 'package:evalet/ui/operator/operator_cards/operator_cards_screen.dart';
import 'package:evalet/ui/operator/operator_parked_car/operator_parked_car_screen.dart';

class OperatorScreenRouter {
  static Widget getScreen(
    int selectedIndex,
    Widget dashboardContent,
    int refreshKey, {
    Function(VoidCallback)? onSlotsRefreshReady,
    Function(VoidCallback)? onDriversRefreshReady,
    Function(VoidCallback)? onCardsRefreshReady,
    Function(int)? onNavigateToTab,
    bool isAutoMode = false,
  }) {
    switch (selectedIndex) {
      case 0:
        return dashboardContent;
      case 1:
        return OperatorParkedCarScreen(
          key: ValueKey(refreshKey),
          onRefreshReady: onSlotsRefreshReady,
          onNavigateToTab: onNavigateToTab,
          isAutoMode: isAutoMode,
        );
      case 2:
        return OperatorDriversScreen(
          key: ValueKey(refreshKey),
          onRefreshReady: onDriversRefreshReady,
          onNavigateToTab: onNavigateToTab,
        );
      case 3:
        return OperatorCarLogsScreen(
          key: ValueKey(refreshKey),
          onNavigateToTab: onNavigateToTab,
        );
      case 10:
        return OperatorCardsScreen(
          key: ValueKey(refreshKey),
          onRefreshReady: onCardsRefreshReady,
          onNavigateToTab: onNavigateToTab,
        );
      default:
        return dashboardContent;
    }
  }
}
