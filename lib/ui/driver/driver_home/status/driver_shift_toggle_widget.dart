import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:evalet/api/driver/driver_status_api_service.dart';
import 'package:evalet/api/outlet/outlet_api_service.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_bloc.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_event.dart';
import 'package:evalet/bloc/driver/driver_status/driver_status_state.dart';
import 'package:evalet/models/core/api_exceptions.dart';
import 'package:evalet/models/driver/status/clock_in_request.dart';
import 'package:evalet/models/driver/status/clock_out_request.dart';
import 'package:evalet/models/outlet/outlet.dart';
import 'package:evalet/services/connectivity/driver_connectivity_log_service.dart';
import 'package:evalet/services/location/location_service.dart';
import 'package:evalet/services/oauth/token_interceptor.dart';
import 'package:evalet/ui/common/colors.dart';
import 'package:evalet/ui/common/widgets/snack_bar.dart';
import 'package:evalet/ui/common/widgets/text.dart';

/// Clock-in / clock-out on the driver home. Turning it on clocks in (and asks
/// for a location when there is more than one). Turning it off clocks out and
/// leaves the driver signed in.
class DriverShiftToggleWidget extends StatefulWidget {
  final double screenWidth;
  final bool isTablet;
  final bool isDesktop;
  final bool isOnline;

  const DriverShiftToggleWidget({
    super.key,
    required this.screenWidth,
    required this.isTablet,
    required this.isDesktop,
    required this.isOnline,
  });

  @override
  State<DriverShiftToggleWidget> createState() =>
      _DriverShiftToggleWidgetState();
}

class _DriverShiftToggleWidgetState extends State<DriverShiftToggleWidget> {
  bool _busy = false;

  double get _labelFontSize => widget.isDesktop
      ? widget.screenWidth * 0.012
      : widget.isTablet
          ? widget.screenWidth * 0.02
          : widget.screenWidth * 0.032;

  bool _onlineFrom(DriverStatusState state) {
    if (state is DriverStatusLoaded) return state.status.isOnline;
    return widget.isOnline;
  }

  Future<void> _onChanged(bool turnOn) async {
    if (_busy) return;
    if (turnOn) {
      await _clockIn();
    } else {
      await _clockOut();
    }
  }

  Future<({double latitude, double longitude, double accuracy})?>
      _coordinates() async {
    try {
      final coordinates = await LocationService.getCurrentCoordinates();
      final latitude = coordinates['latitude']!;
      final longitude = coordinates['longitude']!;
      final accuracy = coordinates['accuracy']!;
      await TokenStorage.saveCurrentLocation(
        latitude: latitude,
        longitude: longitude,
        location:
            '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}',
      );
      return (
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
      );
    } catch (e) {
      if (mounted) {
        SnackBars.showErrorSnackBar(
          context,
          'Location is required to clock in or out.',
        );
      }
      return null;
    }
  }

  Future<void> _clockIn() async {
    setState(() => _busy = true);
    try {
      final outlets = await OutletApiService.getOutlets();
      if (!mounted) return;
      if (outlets.isEmpty) {
        SnackBars.showErrorSnackBar(
          context,
          'No location is available for your account.',
        );
        return;
      }

      Outlet outlet;
      if (outlets.length == 1) {
        outlet = outlets.first;
      } else {
        final picked = await showDialog<Outlet>(
          context: context,
          builder: (dialogContext) => _LocationPicker(outlets: outlets),
        );
        if (picked == null || !mounted) return;
        outlet = picked;
      }

      final coords = await _coordinates();
      if (coords == null || !mounted) return;

      final response = await DriverStatusApiService.clockIn(
        ClockInRequest(
          outletId: outlet.id,
          latitude: coords.latitude,
          longitude: coords.longitude,
          accuracy: coords.accuracy,
        ),
      );
      await TokenStorage.saveSelectedOutlet(
        outletId: outlet.id,
        outletName: outlet.name,
      );
      dotenv.env['OUTLET_ID'] = outlet.id.toString();
      await DriverConnectivityLogService.instance.onShiftActiveAfterClockIn(
        shiftId: response.shiftId,
        outletId: response.outletId,
      );
      if (!mounted) return;
      context.read<DriverStatusBloc>().add(const DriverStatusRefreshed());
      SnackBars.showSuccessSnackBar(
        context,
        response.message.trim().isEmpty
            ? 'Clocked in at ${outlet.name}.'
            : response.message,
      );
    } on ApiException catch (e) {
      if (mounted) SnackBars.showErrorSnackBar(context, e.displayMessage);
    } catch (_) {
      if (mounted) {
        SnackBars.showErrorSnackBar(
          context,
          'Failed to clock in. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clockOut() async {
    setState(() => _busy = true);
    try {
      final coords = await _coordinates();
      if (coords == null || !mounted) return;
      await DriverStatusApiService.clockOut(
        ClockOutRequest(
          latitude: coords.latitude,
          longitude: coords.longitude,
          accuracy: coords.accuracy,
        ),
      );
      if (!mounted) return;
      context.read<DriverStatusBloc>().add(const DriverStatusRefreshed());
      SnackBars.showSuccessSnackBar(context, 'Clocked out.');
    } on ApiException catch (e) {
      if (mounted) SnackBars.showErrorSnackBar(context, e.displayMessage);
    } catch (_) {
      if (mounted) {
        SnackBars.showErrorSnackBar(
          context,
          'Failed to clock out. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DriverStatusBloc, DriverStatusState>(
      builder: (context, state) {
        final online = _onlineFrom(state);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextComponent(
              labelText: online ? 'Clocked in' : 'Clocked out',
              fontSize: _labelFontSize,
              fontWeight: FontWeight.w400,
              color: AppColors.white,
            ),
            SizedBox(width: widget.screenWidth * 0.015),
            _busy
                ? const SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      ),
                    ),
                  )
                : Semantics(
                    button: true,
                    label: online
                        ? 'Clocked in, tap to clock out'
                        : 'Clocked out, tap to clock in',
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: Center(
                        child: _ShiftSwitch(
                          value: online,
                          onChanged: _onChanged,
                        ),
                      ),
                    ),
                  ),
          ],
        );
      },
    );
  }
}

class _ShiftSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ShiftSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const trackWidth = 48.0;
    const trackHeight = 28.0;
    const thumbSize = 22.0;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: trackWidth,
        height: trackHeight,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: value ? AppColors.success : AppColors.coral,
          borderRadius: BorderRadius.circular(trackHeight / 2),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: thumbSize,
            height: thumbSize,
            decoration: const BoxDecoration(
              color: AppColors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}

class _LocationPicker extends StatelessWidget {
  final List<Outlet> outlets;

  const _LocationPicker({required this.outlets});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primarySurface,
      title: const TextComponent(
        labelText: 'Select location',
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: outlets.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final outlet = outlets[index];
            return ListTile(
              title: Text(outlet.name),
              onTap: () => Navigator.of(context).pop(outlet),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
