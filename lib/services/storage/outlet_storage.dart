import 'package:hive_flutter/hive_flutter.dart';
import 'package:evalet/services/storage/auth_box.dart';

/// The outlet selected at login and the Outlet Codes the server has confirmed.
///
/// Stored in the shared [AuthBox].
class OutletStorage {
  static const String _selectedOutletIdKey = 'selected_outlet_id';
  static const String _selectedOutletNameKey = 'selected_outlet_name';
  static const String _confirmedOutletCodesKey = 'confirmed_outlet_codes';

  // Selected Outlet management
  static Future<void> saveSelectedOutlet({
    required int outletId,
    required String outletName,
  }) async {
    try {
      await AuthBox.box.put(_selectedOutletIdKey, outletId);
      await AuthBox.box.put(_selectedOutletNameKey, outletName);
    } catch (e) {
      print('[OutletStorage] ❌ Error saving selected outlet: $e');
      rethrow;
    }
  }

  static Future<int?> getSelectedOutletId() async {
    try {
      return AuthBox.box.get(_selectedOutletIdKey) as int?;
    } catch (e) {
      print('[OutletStorage] ❌ Error retrieving selected outlet id: $e');
      return null;
    }
  }

  static int? getSelectedOutletIdSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return null;
      return Hive.box(AuthBox.name).get(_selectedOutletIdKey) as int?;
    } catch (_) {
      return null;
    }
  }

  /// Identifies the selected outlet in [_confirmedOutletCodesKey]. The name is
  /// part of it because outlet ids repeat across clients.
  static String? _selectedOutletCodeEntryKey(Box box) {
    final id = box.get(_selectedOutletIdKey) as int?;
    if (id == null) return null;
    final name = (box.get(_selectedOutletNameKey) as String?) ?? '';
    return '$id|$name';
  }

  /// Remembers [outletCode] as the selected outlet's Outlet Code. Call only
  /// after the server accepted a check-in carrying it, which proves the code
  /// belongs to this outlet. Kept across logout so the next shift can refuse
  /// another outlet's card while offline from its first scan.
  static Future<void> saveConfirmedOutletCode({
    required int outletId,
    required String outletCode,
  }) async {
    try {
      final code = outletCode.trim();
      if (code.isEmpty) return;
      if (AuthBox.box.get(_selectedOutletIdKey) != outletId) return;
      final entryKey = _selectedOutletCodeEntryKey(AuthBox.box);
      if (entryKey == null) return;
      final raw = AuthBox.box.get(_confirmedOutletCodesKey);
      final codes = <String, String>{
        if (raw is Map)
          for (final e in raw.entries) e.key.toString(): e.value.toString(),
      };
      if (codes[entryKey] == code) return;
      codes[entryKey] = code;
      await AuthBox.box.put(_confirmedOutletCodesKey, codes);
    } catch (e) {
      print('[OutletStorage] Error saving confirmed outlet code: $e');
    }
  }

  /// The selected outlet's Outlet Code as the server last confirmed it, or
  /// null when no check-in has confirmed one on this device yet.
  static String? getConfirmedOutletCodeSync() {
    try {
      if (!Hive.isBoxOpen(AuthBox.name)) return null;
      final box = Hive.box(AuthBox.name);
      final entryKey = _selectedOutletCodeEntryKey(box);
      final raw = box.get(_confirmedOutletCodesKey);
      if (entryKey == null || raw is! Map) return null;
      return raw[entryKey]?.toString();
    } catch (_) {
      return null;
    }
  }

  static Future<String?> getSelectedOutletName() async {
    try {
      return AuthBox.box.get(_selectedOutletNameKey) as String?;
    } catch (e) {
      print('[OutletStorage] ❌ Error retrieving selected outlet name: $e');
      return null;
    }
  }

  static Future<void> clearSelectedOutlet() async {
    try {
      await AuthBox.box.delete(_selectedOutletIdKey);
      await AuthBox.box.delete(_selectedOutletNameKey);
    } catch (e) {
      print('[OutletStorage] ❌ Error clearing selected outlet: $e');
    }
  }
}
