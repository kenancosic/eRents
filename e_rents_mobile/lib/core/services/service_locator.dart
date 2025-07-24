import 'package:get_it/get_it.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:e_rents_mobile/core/services/cache_manager.dart';
import 'package:e_rents_mobile/core/services/notification_service.dart';
import 'package:e_rents_mobile/config.dart';
// Repository imports


// Additional core services
// Removed home_service, lease_service, pricing_service - consolidated into providers

/// ServiceLocator for dependency injection with lazy loading
/// Following the desktop app pattern for better performance and organization
class ServiceLocator {
  static final GetIt _locator = GetIt.instance;

  static GetIt get instance => _locator;

  /// Initialize core services
  static Future<void> setupServices() async {
    // Core infrastructure services
    _locator.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(),
    );

    _locator.registerLazySingleton<CacheManager>(
      () => CacheManager(),
    );

    _locator.registerLazySingleton<ApiService>(
      () => ApiService(
        Config.baseUrl,
        _locator<SecureStorageService>(),
      ),
    );

    // Additional core services
    _locator.registerLazySingleton<NotificationService>(
      () => NotificationService(_locator<ApiService>()),
    );

    // Business services - most services now consolidated into providers
    // HomeService, LeaseService, PricingService functionality moved to PropertyDetailProvider

    // Repositories

    // Detail Providers (Factories - each screen gets its own instance)
    

    // TODO: Add detail providers for other entities as needed
  }

  /// Get service instance
  static T get<T extends Object>() {
    return _locator<T>();
  }

  /// Check if service is registered
  static bool isRegistered<T extends Object>() {
    return _locator.isRegistered<T>();
  }

  /// Reset all services (useful for testing)
  static Future<void> reset() async {
    await _locator.reset();
  }
}
