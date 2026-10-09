import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_bloc.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_event.dart';
import 'package:niloufer_valet_mobile/bloc/driver/driver_home/driver_menu_state.dart';
import 'package:niloufer_valet_mobile/ui/common/colors.dart';
import 'package:niloufer_valet_mobile/ui/common/widgets/text.dart';
import 'package:niloufer_valet_mobile/ui/driver/parked_cars/my_parked_cars_screen.dart';

/// App bar control: car icon + parked count; opens [MyParkedCarsScreen].
class ParkedCarsAppBarAction extends StatefulWidget {
  const ParkedCarsAppBarAction({super.key, this.iconSize});

  final double? iconSize;

  @override
  State<ParkedCarsAppBarAction> createState() => _ParkedCarsAppBarActionState();
}

class _ParkedCarsAppBarActionState extends State<ParkedCarsAppBarAction> {
  bool _isNavigating = false;

  Future<void> _openParkedCars(BuildContext context) async {
    if (_isNavigating) return;

    // If we are already on the parked cars screen, tapping the icon should be a no-op.
    // (Prevents stacking duplicate screens when the car icon is shown via overflow menu on the target screen.)
    final currentRoute = ModalRoute.of(context);
    if (currentRoute is MaterialPageRoute &&
        currentRoute.settings.name == 'my-parked-cars') {
      return;
    }

    setState(() => _isNavigating = true);
    try {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const MyParkedCarsScreen(),
          settings: const RouteSettings(name: 'my-parked-cars'),
        ),
      );
      if (context.mounted) {
        context.read<DriverMenuBloc>().add(const DriverPendingSessionsRefresh());
      }
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final baseIconSize = widget.iconSize ?? screenWidth * 0.06;
    // Larger than other app bar icons — parked cars entry point only.
    final iconDimension = baseIconSize * 1.5;
    final badgeFontSize = screenWidth * 0.022;

    return BlocBuilder<DriverMenuBloc, DriverMenuState>(
      buildWhen: (previous, current) {
        final prevCount =
            previous is DriverHomeLoaded ? previous.parkedCarsCount : null;
        final currCount =
            current is DriverHomeLoaded ? current.parkedCarsCount : null;
        return prevCount != currCount;
      },
      builder: (context, state) {
        final count =
            state is DriverHomeLoaded ? state.parkedCarsCount : 0;

        return IconButton(
          tooltip: 'Parked cars',
          onPressed: _isNavigating ? null : () => _openParkedCars(context),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(
            minWidth: iconDimension + 12,
            minHeight: iconDimension + 12,
          ),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.directions_car_rounded,
                color: AppColors.textOnDark,
                size: iconDimension,
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: screenWidth * 0.045,
                      minHeight: screenWidth * 0.045,
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.008,
                      vertical: screenWidth * 0.002,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: AppColors.textOnDark, width: 1.5),
                    ),
                    child: Center(
                      child: TextComponent(
                        labelText: count > 99 ? '99+' : count.toString(),
                        fontSize: badgeFontSize,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textOnDark,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
