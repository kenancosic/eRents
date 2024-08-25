import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CacheService {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> cacheData(String key, dynamic data) async {
    final jsonData = jsonEncode(data);
    await _storage.write(key: key, value: jsonData);
  }

  Future<dynamic> getCachedData(String key) async {
    final jsonData = await _storage.read(key: key);
    if (jsonData != null) {
      return jsonDecode(jsonData);
    }
    return null;
  }

  Future<void> clearCache(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> clearAllCache() async {
    await _storage.deleteAll();
  }
}
