import 'package:evalet/services/storage/auth_box.dart';

/// The logged-in user's name and phone number.
///
/// Stored in the shared [AuthBox].
class UserStorage {
  static const String _firstNameKey = 'user_first_name';
  static const String _lastNameKey = 'user_last_name';
  static const String _phoneNumberKey = 'user_phone_number';

  // User name
  static Future<void> saveUserName({
    required String firstName,
    required String lastName,
  }) async {
    try {
      await AuthBox.box.put(_firstNameKey, firstName);
      await AuthBox.box.put(_lastNameKey, lastName);
    } catch (e) {
      print('[UserStorage] Error saving user name: $e');
      rethrow;
    }
  }

  static Future<String?> getFirstName() async {
    try {
      return AuthBox.box.get(_firstNameKey) as String?;
    } catch (e) {
      print('[UserStorage] Error retrieving first name: $e');
      return null;
    }
  }

  static Future<String?> getLastName() async {
    try {
      return AuthBox.box.get(_lastNameKey) as String?;
    } catch (e) {
      print('[UserStorage] Error retrieving last name: $e');
      return null;
    }
  }

  static Future<void> clearUserName() async {
    try {
      await AuthBox.box.delete(_firstNameKey);
      await AuthBox.box.delete(_lastNameKey);
    } catch (e) {
      print('[UserStorage] Error clearing user name: $e');
    }
  }

  // Phone number (identifier)
  static Future<void> savePhoneNumber(String phoneNumber) async {
    try {
      await AuthBox.box.put(_phoneNumberKey, phoneNumber);
    } catch (e) {
      print('[UserStorage] Error saving phone number: $e');
      rethrow;
    }
  }

  static Future<String?> getPhoneNumber() async {
    try {
      return AuthBox.box.get(_phoneNumberKey) as String?;
    } catch (e) {
      print('[UserStorage] Error retrieving phone number: $e');
      return null;
    }
  }

  static Future<void> clearPhoneNumber() async {
    try {
      await AuthBox.box.delete(_phoneNumberKey);
    } catch (e) {
      print('[UserStorage] Error clearing phone number: $e');
    }
  }
}
