import 'base_provider.dart';
import '../services/user_preferences_service.dart';

class PreferencesProvider extends BaseProvider<void> {
  final UserPreferencesService _preferencesService;

  PreferencesProvider({required UserPreferencesService preferencesService})
    : _preferencesService = preferencesService,
      super(null);

  Future<void> setPreference(String key, String value) async {
    await execute(() async {
      await _preferencesService.setPreference(key, value);
      notifyListeners();
    });
  }

  Future<String?> getPreference(String key) async {
    return await _preferencesService.getPreference(key);
  }

  Future<void> removePreference(String key) async {
    await execute(() async {
      await _preferencesService.removePreference(key);
      notifyListeners();
    });
  }

  @override
  String get endpoint => '';

  @override
  void fromJson(Map<String, dynamic> json) {}

  @override
  Map<String, dynamic> toJson(void item) => {};

  @override
  List<void> getMockItems() => [];
}
