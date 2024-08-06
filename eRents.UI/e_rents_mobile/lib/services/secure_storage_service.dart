import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _secureStorage = FlutterSecureStorage();

  static Future<bool> setItem(String key, String value) async {
    try {
      await _secureStorage.write(key: key, value: value);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getItem(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } catch (e) {
      return null;
    }
  }

  static Future<bool> removeItem(String key) async {
    try {
      await _secureStorage.delete(key: key);
      return true;
    } catch (e) {
      return false;
    }
  }
}
