import 'package:flutter/material.dart';
import '../services/user_preferences_service.dart';

/// Preferences provider for managing user preferences
/// This provider doesn't need API access, so it extends ChangeNotifier directly
class PreferencesProvider extends ChangeNotifier {
  final UserPreferencesService _preferencesService;

  PreferencesProvider({required UserPreferencesService preferencesService})
      : _preferencesService = preferencesService;

  Future<void> setPreference(String key, String value) async {
    await _preferencesService.setPreference(key, value);
    notifyListeners();
  }

  Future<String?> getPreference(String key) async {
    return await _preferencesService.getPreference(key);
  }

  Future<void> removePreference(String key) async {
    await _preferencesService.removePreference(key);
    notifyListeners();
  }
}
