import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/tenant_service.dart';
import 'package:e_rents_desktop/repositories/tenant_repository.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';

/// Helper class to register all tenant-related services with the service locator
class TenantsServiceRegistrations {
  /// Register all tenant-related services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    locator.registerLazySingleton<TenantService>(
      () => TenantService(baseUrl, locator.get<SecureStorageService>()),
    );

    locator.registerLazySingleton<TenantRepository>(
      () => TenantRepository(
        service: locator.get<TenantService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );
  }
}
