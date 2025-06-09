import 'package:get_it/get_it.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:e_rents_mobile/core/services/cache_manager.dart';
import 'package:e_rents_mobile/core/services/notification_service.dart';
import 'package:e_rents_mobile/config.dart';
// Repository imports
import 'package:e_rents_mobile/core/repositories/property_repository.dart';
import 'package:e_rents_mobile/core/repositories/user_repository.dart';
import 'package:e_rents_mobile/core/repositories/booking_repository.dart';
import 'package:e_rents_mobile/core/repositories/review_repository.dart';
import 'package:e_rents_mobile/core/repositories/maintenance_repository.dart';
import 'package:e_rents_mobile/core/services/property_service.dart';
import 'package:e_rents_mobile/core/services/user_service.dart';
// Provider imports
import 'package:e_rents_mobile/feature/property_detail/providers/property_collection_provider.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_provider.dart';
import 'package:e_rents_mobile/feature/profile/providers/user_detail_provider.dart';
import 'package:e_rents_mobile/feature/profile/providers/booking_collection_provider.dart';
import 'package:e_rents_mobile/feature/property_detail/providers/review_collection_provider.dart';
import 'package:e_rents_mobile/feature/property_detail/providers/maintenance_collection_provider.dart';
import 'package:e_rents_mobile/feature/home/providers/home_dashboard_provider.dart';
// Additional core services
import 'package:e_rents_mobile/core/services/home_service.dart';
import 'package:e_rents_mobile/core/services/booking_service.dart';
import 'package:e_rents_mobile/core/services/maintenance_service.dart';
import 'package:e_rents_mobile/core/services/lease_service.dart';
import 'package:e_rents_mobile/core/services/review_service.dart';
import 'package:e_rents_mobile/core/services/pricing_service.dart';
import 'package:e_rents_mobile/feature/saved/saved_service.dart';
import 'package:e_rents_mobile/core/repositories/saved_repository.dart';
import 'package:e_rents_mobile/feature/saved/saved_collection_provider.dart';

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

    // Business services
    _locator.registerLazySingleton<PropertyService>(
      () => PropertyService(_locator<ApiService>()),
    );

    _locator.registerLazySingleton<UserService>(
      () => UserService(_locator<ApiService>()),
    );

    _locator.registerLazySingleton<HomeService>(
      () => HomeService(_locator<ApiService>()),
    );

    _locator.registerLazySingleton<BookingService>(
      () => BookingService(_locator<ApiService>()),
    );

    _locator.registerLazySingleton<MaintenanceService>(
      () => MaintenanceService(_locator<ApiService>()),
    );

    _locator.registerLazySingleton<LeaseService>(
      () => LeaseService(_locator<ApiService>()),
    );

    _locator.registerLazySingleton<ReviewService>(
      () => ReviewService(_locator<ApiService>()),
    );

    _locator.registerLazySingleton<SavedService>(
      () => SavedService(
        _locator<ApiService>(),
        _locator<SecureStorageService>(),
      ),
    );

    _locator.registerLazySingleton<PricingService>(
      () => PricingService(_locator<ApiService>()),
    );

    // Repositories
    _locator.registerLazySingleton<PropertyRepository>(
      () => PropertyRepository(
        service: _locator<PropertyService>(),
        cacheManager: _locator<CacheManager>(),
      ),
    );

    _locator.registerLazySingleton<UserRepository>(
      () => UserRepository(
        service: _locator<UserService>(),
        cacheManager: _locator<CacheManager>(),
      ),
    );

    _locator.registerLazySingleton<BookingRepository>(
      () => BookingRepository(
        service: _locator<BookingService>(),
        cacheManager: _locator<CacheManager>(),
      ),
    );

    _locator.registerLazySingleton<ReviewRepository>(
      () => ReviewRepository(
        service: _locator<ReviewService>(),
        cacheManager: _locator<CacheManager>(),
      ),
    );

    _locator.registerLazySingleton<MaintenanceRepository>(
      () => MaintenanceRepository(
        service: _locator<MaintenanceService>(),
        cacheManager: _locator<CacheManager>(),
      ),
    );

    _locator.registerLazySingleton<SavedRepository>(
      () => SavedRepository(
        service: _locator<SavedService>(),
        cacheManager: _locator<CacheManager>(),
      ),
    );

    // Collection Providers (Singletons for app-wide state)
    _locator.registerLazySingleton<PropertyCollectionProvider>(
      () => PropertyCollectionProvider(_locator<PropertyRepository>()),
    );

    _locator.registerLazySingleton<UserDetailProvider>(
      () => UserDetailProvider(_locator<UserRepository>()),
    );

    _locator.registerLazySingleton<BookingCollectionProvider>(
      () => BookingCollectionProvider(_locator<BookingRepository>()),
    );

    _locator.registerLazySingleton<ReviewCollectionProvider>(
      () => ReviewCollectionProvider(_locator<ReviewRepository>()),
    );

    _locator.registerLazySingleton<MaintenanceCollectionProvider>(
      () => MaintenanceCollectionProvider(_locator<MaintenanceRepository>()),
    );

    _locator.registerLazySingleton<SavedCollectionProvider>(
      () => SavedCollectionProvider(_locator<SavedRepository>()),
    );

    // Dashboard provider
    _locator.registerLazySingleton<HomeDashboardProvider>(
      () => HomeDashboardProvider(
        _locator<PropertyRepository>(),
        _locator<BookingRepository>(),
        _locator<UserRepository>(),
      ),
    );

    // Detail Providers (Factories - each screen gets its own instance)
    _locator.registerFactory<PropertyDetailProvider>(
      () => PropertyDetailProvider(_locator<PropertyRepository>()),
    );

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
