import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static SharedPreferences? _preferences;

  static Future init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  static Future<bool> setItem(String key, String value) async {
    if (_preferences == null) {
      return false; // Return false if preferences are not initialized
    }

    try {
      await _preferences!.setString(key, value);
      return true; // Return true if setString operation is successful
    } catch (e) {
      return false; // Return false if there's an error during setString operation
    }
  }

  static String? getItem(String key) {
    return _preferences?.getString(key);
  }

  static Future<bool> removeItem(String key) async {
    if (_preferences == null) {
      return false; // Return false if preferences are not initialized
    }

    try {
      await _preferences!.remove(key);
      return true; // Return true if remove operation is successful
    } catch (e) {
      return false; // Return false if there's an error during remove operation
    }
  }
}
