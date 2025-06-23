import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/maintenance_service.dart';
import 'package:e_rents_desktop/repositories/maintenance_repository.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';

/// Helper class to register all maintenance-related services with the service locator
class MaintenanceServiceRegistrations {
  /// Register all maintenance-related services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    locator.registerLazySingleton<MaintenanceService>(
      () => MaintenanceService(baseUrl, locator.get<SecureStorageService>()),
    );

    locator.registerLazySingleton<MaintenanceRepository>(
      () => MaintenanceRepository(
        service: locator.get<MaintenanceService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );
  }
}
