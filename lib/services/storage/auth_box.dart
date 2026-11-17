import 'package:hive_flutter/hive_flutter.dart';

/// The single Hive box that the stores in this folder share.
class AuthBox {
  static const String name = 'authBox';

  /// Must be called once at app start (after Hive.initFlutter()).
  static Future<void> init() async {
    if (!Hive.isBoxOpen(name)) {
      await Hive.openBox(name);
    }
  }

  static Box get box {
    if (!Hive.isBoxOpen(name)) {
      throw StateError(
        'TokenStorage box not opened. Call TokenStorage.init() first.',
      );
    }
    return Hive.box(name);
  }
}
