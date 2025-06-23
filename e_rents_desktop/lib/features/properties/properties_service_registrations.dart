import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/property_service.dart';
import 'package:e_rents_desktop/repositories/property_repository.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/services/lookup_service.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';

/// Helper class to register all property-related services with the service locator
class PropertiesServiceRegistrations {
  /// Register all property-related services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    locator.registerLazySingleton<PropertyService>(
      () => PropertyService(
        baseUrl,
        locator.get<SecureStorageService>(),
        locator.get<LookupService>(),
      ),
    );

    locator.registerLazySingleton<PropertyRepository>(
      () => PropertyRepository(
        service: locator.get<PropertyService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );
  }
}
