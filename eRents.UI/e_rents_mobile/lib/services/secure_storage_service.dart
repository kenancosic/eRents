import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  Future<void> writeToken(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readToken(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteToken(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
