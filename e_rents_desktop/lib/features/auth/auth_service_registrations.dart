import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/auth_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

/// Helper class to register all auth-related services with the service locator
class AuthServiceRegistrations {
  /// Register all auth-related services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    locator.registerLazySingleton<AuthService>(
      () => AuthService(baseUrl, locator.get<SecureStorageService>()),
    );
  }
}
