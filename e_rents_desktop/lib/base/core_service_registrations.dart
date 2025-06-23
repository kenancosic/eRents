import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/services/user_preferences_service.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/image_service.dart';
import 'package:e_rents_desktop/services/lookup_service.dart';
import 'package:e_rents_desktop/services/review_service.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';

/// Helper class to register all core, app-wide services
class CoreServiceRegistrations {
  /// Register all core services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    // Foundational services (should be singletons)
    locator.registerSingleton<SecureStorageService>(SecureStorageService());
    locator.registerSingleton<UserPreferencesService>(UserPreferencesService());

    // API services that are widely used or have no specific feature home
    locator.registerSingleton<ApiService>(
      ApiService(baseUrl, locator.get<SecureStorageService>()),
    );
    locator.registerSingleton<ImageService>(
      ImageService(baseUrl, locator.get<SecureStorageService>()),
    );
    locator.registerSingleton<LookupService>(
      LookupService(baseUrl, locator.get<SecureStorageService>()),
    );
    // ReviewService is used in both property and tenant contexts, so it fits here
    locator.registerSingleton<ReviewService>(
      ReviewService(baseUrl, locator.get<SecureStorageService>()),
    );

    // App-wide Cache Manager
    locator.registerSingleton<CacheManager>(CacheManager());
  }
}
