import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/rental_request_service.dart';
import 'package:e_rents_desktop/services/rental_management_service.dart';
import 'package:e_rents_desktop/repositories/rental_request_repository.dart';
import 'package:e_rents_desktop/repositories/booking_repository.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

/// Helper class to register all rental-related services with the service locator
class RentalServiceRegistrations {
  /// Register all rental-related services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    // Register RentalRequestService as lazy singleton
    locator.registerLazySingleton<RentalRequestService>(
      () => RentalRequestService(baseUrl, locator.get<SecureStorageService>()),
    );

    // Register RentalRequestRepository as lazy singleton
    locator.registerLazySingleton<RentalRequestRepository>(
      () => RentalRequestRepository(
        service: locator.get<RentalRequestService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );

    // Register RentalManagementService as lazy singleton
    // This is the central orchestrator that unifies both rental types
    locator.registerLazySingleton<RentalManagementService>(
      () => RentalManagementService(
        locator.get<BookingRepository>(),
        locator.get<RentalRequestRepository>(),
      ),
    );
  }

  /// Check if all rental services are registered
  static bool areServicesRegistered(ServiceLocator locator) {
    return locator.isRegistered<RentalRequestService>() &&
        locator.isRegistered<RentalRequestRepository>() &&
        locator.isRegistered<RentalManagementService>();
  }

  /// Get debug information about rental service registration
  static Map<String, bool> getRegistrationStatus(ServiceLocator locator) {
    return {
      'RentalRequestService': locator.isRegistered<RentalRequestService>(),
      'RentalRequestRepository':
          locator.isRegistered<RentalRequestRepository>(),
      'RentalManagementService':
          locator.isRegistered<RentalManagementService>(),
    };
  }
}
