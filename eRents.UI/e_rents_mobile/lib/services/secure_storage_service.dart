import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _secureStorage = FlutterSecureStorage();

  // Keys for specific items
  static const _jwtTokenKey = 'jwt_token';

  /// Set a generic key-value pair in secure storage.
  static Future<bool> setItem(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (e) {
      print("Error setting item in secure storage: $e");
      return false;
    }
  }

  /// Retrieve a value from secure storage by its key.
  static Future<String?> getItem(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      print("Error getting item from secure storage: $e");
      return null;
    }
  }

  /// Remove a value from secure storage by its key.
  static Future<bool> removeItem(String key) async {
    try {
      await _secureStorage.delete(key: key);
      return true;
    } catch (e) {
      print("Error removing item from secure storage: $e");
      return false;
    }
  }

  /// Store the JWT token specifically.
  static Future<bool> storeJwtToken(String token) async {
    return await setItem(_jwtTokenKey, token);
  }

  /// Retrieve the JWT token.
  static Future<String?> getJwtToken() async {
    return await getItem(_jwtTokenKey);
  }

  /// Remove the JWT token.
  static Future<bool> removeJwtToken() async {
    return await removeItem(_jwtTokenKey);
  }

  /// Clear all data in secure storage (use with caution).
  static Future<bool> clearAll() async {
    try {
      await _secureStorage.deleteAll();
      return true;
    } catch (e) {
      print("Error clearing secure storage: $e");
      return false;
    }
  }
}
