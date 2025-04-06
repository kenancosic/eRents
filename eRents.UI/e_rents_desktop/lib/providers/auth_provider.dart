import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class AuthProvider extends BaseProvider<User> {
  AuthProvider(ApiService apiService) : super(apiService);

  @override
  String get endpoint => '/auth';

  @override
  User fromJson(Map<String, dynamic> json) => User.fromJson(json);

  @override
  Map<String, dynamic> toJson(User item) => item.toJson();

  @override
  List<User> getMockItems() => MockDataService.getMockUsers();

  // Additional auth-specific methods
  Future<bool> login(String email, String password) async {
    bool result = false;
    await execute(() async {
      // TODO: Implement actual login logic
      result = true;
    });
    return result;
  }

  Future<bool> register(User user) async {
    bool result = false;
    await execute(() async {
      // TODO: Implement actual registration logic
      result = true;
    });
    return result;
  }

  Future<void> logout() async {
    await execute(() async {
      // TODO: Implement actual logout logic
    });
  }

  // Alias for items to maintain backward compatibility
  List<User> get users => items;
}
