import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/rental_request_service.dart';
import 'package:e_rents_desktop/repositories/rental_request_repository.dart';
import 'package:e_rents_desktop/repositories/booking_repository.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';
import 'package:e_rents_desktop/services/booking_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';

/// Helper class to register all rental-related services with the service locator
class RentalServiceRegistrations {
  /// Register all rental-related services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    _registerBookingServices(locator, baseUrl);
    _registerLeaseServices(locator, baseUrl);
  }

  /// Registers all services related to short-term stays (Bookings)
  static void _registerBookingServices(ServiceLocator locator, String baseUrl) {
    locator.registerLazySingleton<BookingService>(
      () => BookingService(baseUrl, locator.get<SecureStorageService>()),
    );

    locator.registerLazySingleton<BookingRepository>(
      () => BookingRepository(
        service: locator.get<BookingService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );
  }

  /// Registers all services related to long-term leases (Rental Requests)
  static void _registerLeaseServices(ServiceLocator locator, String baseUrl) {
    locator.registerLazySingleton<RentalRequestService>(
      () => RentalRequestService(baseUrl, locator.get<SecureStorageService>()),
    );

    locator.registerLazySingleton<RentalRequestRepository>(
      () => RentalRequestRepository(
        service: locator.get<RentalRequestService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );
  }

  /// Check if all rental services are registered
  static bool areServicesRegistered(ServiceLocator locator) {
    return locator.isRegistered<BookingService>() &&
        locator.isRegistered<BookingRepository>() &&
        locator.isRegistered<RentalRequestService>() &&
        locator.isRegistered<RentalRequestRepository>();
  }

  /// Get debug information about rental service registration
  static Map<String, bool> getRegistrationStatus(ServiceLocator locator) {
    return {
      'BookingService': locator.isRegistered<BookingService>(),
      'BookingRepository': locator.isRegistered<BookingRepository>(),
      'RentalRequestService': locator.isRegistered<RentalRequestService>(),
      'RentalRequestRepository':
          locator.isRegistered<RentalRequestRepository>(),
    };
  }
}
