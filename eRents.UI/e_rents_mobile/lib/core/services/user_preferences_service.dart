import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserPreferencesService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> setPreference(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getPreference(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> removePreference(String key) async {
    await _storage.delete(key: key);
  }
}
