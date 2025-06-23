import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/profile_service.dart';
import 'package:e_rents_desktop/repositories/profile_repository.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';

/// Helper class to register all profile-related services
class ProfileServiceRegistrations {
  /// Register all services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    locator.registerLazySingleton<ProfileService>(
      () => ProfileService(baseUrl, locator.get<SecureStorageService>()),
    );

    locator.registerLazySingleton<ProfileRepository>(
      () => ProfileRepository(
        service: locator.get<ProfileService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );
  }
}
