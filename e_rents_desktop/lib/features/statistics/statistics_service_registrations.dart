import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/statistics_service.dart';
import 'package:e_rents_desktop/services/report_service.dart';
import 'package:e_rents_desktop/repositories/statistics_repository.dart';
import 'package:e_rents_desktop/repositories/reports_repository.dart';
import 'package:e_rents_desktop/repositories/home_repository.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/base/cache_manager.dart';

/// Helper class to register all statistics and reporting services
class StatisticsServiceRegistrations {
  /// Register all services
  static void registerServices(ServiceLocator locator, String baseUrl) {
    locator.registerLazySingleton<StatisticsService>(
      () => StatisticsService(baseUrl, locator.get<SecureStorageService>()),
    );

    locator.registerLazySingleton<ReportService>(
      () => ReportService(baseUrl, locator.get<SecureStorageService>()),
    );

    locator.registerLazySingleton<StatisticsRepository>(
      () => StatisticsRepository(
        service: locator.get<StatisticsService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );

    locator.registerLazySingleton<ReportsRepository>(
      () => ReportsRepository(
        service: locator.get<ReportService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );

    locator.registerLazySingleton<HomeRepository>(
      () => HomeRepository(
        service: locator.get<StatisticsService>(),
        cacheManager: locator.get<CacheManager>(),
      ),
    );
  }
}
