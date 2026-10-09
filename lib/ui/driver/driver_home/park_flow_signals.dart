/// Tracks driver park flows so retrieval and connectivity UI can defer correctly.
class ParkFlowSignals {
  ParkFlowSignals._();

  static int _carPhotoDepth = 0;
  static int _vehicleDetailsDepth = 0;

  /// Whether the driver is currently viewing the main home cards (Park/Retrieve)
  /// on the driver home screen. The home tolerates being offline; suppress
  /// no-internet banners, toasts, and full blockers while here.
  static bool _isOnDriverHomeCards = false;

  static bool get isCarPhotoParkFlowActive => _carPhotoDepth > 0;

  static bool get isVehicleDetailsFlowActive => _vehicleDetailsDepth > 0;

  static bool get isOnDriverHomeCards => _isOnDriverHomeCards;

  /// Card entry, parking flows, and the main driver home cards work offline
  /// or tolerate offline gracefully. Hide the global no-internet blocker
  /// and any bottom "no internet" messages while these are active.
  static bool get shouldSuppressNoInternetOverlay =>
      isCarPhotoParkFlowActive || isVehicleDetailsFlowActive || isOnDriverHomeCards;

  static void beginCarPhotoParkFlow() {
    _carPhotoDepth++;
  }

  static void endCarPhotoParkFlow() {
    if (_carPhotoDepth > 0) _carPhotoDepth--;
  }

  static void beginVehicleDetailsFlow() {
    _vehicleDetailsDepth++;
  }

  static void endVehicleDetailsFlow() {
    if (_vehicleDetailsDepth > 0) _vehicleDetailsDepth--;
  }

  /// Call when the visible surface on driver home becomes (or stops being) the main two-cards home.
  static void setDriverHomeCardsVisible(bool visible) {
    _isOnDriverHomeCards = visible;
  }
}
