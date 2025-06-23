import 'package:e_rents_desktop/base/core_service_registrations.dart';
import 'package:e_rents_desktop/features/rents/rental_service_registrations.dart';
import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/features/auth/auth_service_registrations.dart';
import 'package:e_rents_desktop/features/chat/chat_service_registrations.dart';
import 'package:e_rents_desktop/features/maintenance/maintenance_service_registrations.dart';
import 'package:e_rents_desktop/features/profile/profile_service_registrations.dart';
import 'package:e_rents_desktop/features/properties/properties_service_registrations.dart';
import 'package:e_rents_desktop/features/statistics/statistics_service_registrations.dart';
import 'package:e_rents_desktop/features/tenants/tenants_service_registrations.dart';

/// Central hub for registering all application services.
/// This class delegates to feature-specific registration modules
/// to keep the main setup clean and organized.
class AppServiceRegistrations {
  static void registerServices(ServiceLocator locator, String baseUrl) {
    // Register core services first as other services may depend on them
    CoreServiceRegistrations.registerServices(locator, baseUrl);

    // Register feature-specific services
    AuthServiceRegistrations.registerServices(locator, baseUrl);
    PropertiesServiceRegistrations.registerServices(locator, baseUrl);
    RentalServiceRegistrations.registerServices(
      locator,
      baseUrl,
    ); // Stays & Leases
    MaintenanceServiceRegistrations.registerServices(locator, baseUrl);
    TenantsServiceRegistrations.registerServices(locator, baseUrl);
    ChatServiceRegistrations.registerServices(locator, baseUrl);
    StatisticsServiceRegistrations.registerServices(
      locator,
      baseUrl,
    ); // Includes Reports & Home
    ProfileServiceRegistrations.registerServices(locator, baseUrl);
  }
}
