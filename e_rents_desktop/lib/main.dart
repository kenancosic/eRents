import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// New imports from Phase 1
import 'base/base.dart'; // Barrel file for all base imports
import 'widgets/global_error_dialog.dart';
import 'repositories/profile_repository.dart';
import 'repositories/home_repository.dart';
import 'repositories/booking_repository.dart';

// Service imports
import 'services/auth_service.dart';
import 'services/secure_storage_service.dart';
import 'services/user_preferences_service.dart';
import 'services/property_service.dart';

import 'services/booking_service.dart';
import 'services/review_service.dart';
import 'services/maintenance_service.dart';
import 'services/tenant_service.dart';
import 'services/statistics_service.dart';
import 'services/chat_service.dart';
import 'services/report_service.dart';
import 'services/profile_service.dart';
import 'services/image_service.dart';
import 'services/lookup_service.dart';

// Provider imports (only essential ones loaded at startup)
import 'features/auth/providers/auth_provider.dart';
import 'providers/lookup_provider.dart';
import 'base/rental_service_registrations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment
  try {
    await dotenv.load(fileName: "lib/.env");
  } catch (e) {
    // Warning: .env file not found - disabled print for production
    dotenv.env.clear();
  }

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
  // Using API Base URL: $baseUrl - disabled print for production

  // Initialize ServiceLocator and register services
  await _setupServices(baseUrl);

  runApp(const ERentsApp());
}

/// Setup all services using ServiceLocator
Future<void> _setupServices(String baseUrl) async {
  final locator = ServiceLocator();
  locator.initialize();

  // Core services
  final secureStorageService = SecureStorageService();
  final prefsService = UserPreferencesService();

  locator.registerSingleton<SecureStorageService>(secureStorageService);
  locator.registerSingleton<UserPreferencesService>(prefsService);

  // API services
  locator.registerSingleton<AuthService>(
    AuthService(baseUrl, secureStorageService),
  );

  // Register LookupService first (PropertyService depends on it)
  locator.registerSingleton<LookupService>(
    LookupService(baseUrl, secureStorageService),
  );

  locator.registerSingleton<PropertyService>(
    PropertyService(
      baseUrl,
      secureStorageService,
      locator.get<LookupService>(),
    ),
  );

  locator.registerSingleton<BookingService>(
    BookingService(baseUrl, secureStorageService),
  );
  locator.registerSingleton<ReviewService>(
    ReviewService(baseUrl, secureStorageService),
  );
  locator.registerSingleton<MaintenanceService>(
    MaintenanceService(baseUrl, secureStorageService),
  );
  locator.registerSingleton<TenantService>(
    TenantService(baseUrl, secureStorageService),
  );
  locator.registerSingleton<StatisticsService>(
    StatisticsService(baseUrl, secureStorageService),
  );
  locator.registerSingleton<ChatService>(
    ChatService(baseUrl, secureStorageService),
  );
  locator.registerSingleton<ReportService>(
    ReportService(baseUrl, secureStorageService),
  );
  locator.registerSingleton<ProfileService>(
    ProfileService(baseUrl, secureStorageService),
  );
  locator.registerSingleton<ImageService>(
    ImageService(baseUrl, secureStorageService),
  );

  // Cache Manager
  locator.registerSingleton<CacheManager>(CacheManager());

  // Repositories (lazy singletons)
  locator.registerLazySingleton<PropertyRepository>(
    () => PropertyRepository(
      service: locator.get<PropertyService>(),
      cacheManager: locator.get<CacheManager>(),
    ),
  );

  locator.registerLazySingleton<MaintenanceRepository>(
    () => MaintenanceRepository(
      service: locator.get<MaintenanceService>(),
      cacheManager: locator.get<CacheManager>(),
    ),
  );

  locator.registerLazySingleton<TenantRepository>(
    () => TenantRepository(
      service: locator.get<TenantService>(),
      cacheManager: locator.get<CacheManager>(),
    ),
  );

  locator.registerLazySingleton<ChatRepository>(
    () => ChatRepository(
      apiService: locator.get<ChatService>(),
      service: locator.get<ChatService>(),
      cacheManager: locator.get<CacheManager>(),
    ),
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

  locator.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(
      service: locator.get<ProfileService>(),
      cacheManager: locator.get<CacheManager>(),
    ),
  );

  locator.registerLazySingleton<HomeRepository>(
    () => HomeRepository(
      service: locator.get<StatisticsService>(),
      cacheManager: locator.get<CacheManager>(),
    ),
  );

  locator.registerLazySingleton<BookingRepository>(
    () => BookingRepository(
      service: locator.get<BookingService>(),
      cacheManager: locator.get<CacheManager>(),
    ),
  );

  // Register unified rental management services
  RentalServiceRegistrations.registerServices(locator, baseUrl);

  // Add other repositories as needed...
}

class ERentsApp extends StatelessWidget {
  const ERentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ✅ Core providers needed at app level
        ChangeNotifierProvider(create: (_) => AppErrorProvider()),
        ChangeNotifierProvider(create: (_) => NavigationStateProvider()),
        ChangeNotifierProvider(
          create:
              (_) => PreferencesStateProvider(
                getService<UserPreferencesService>(),
              ),
        ),
        ChangeNotifierProvider(
          create: (_) => AuthProvider(getService<AuthService>()),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final lookupProvider = LookupProvider(getService<LookupService>());
            // Initialize lookup data immediately (non-blocking)
            WidgetsBinding.instance.addPostFrameCallback((_) {
              lookupProvider.initializeLookupData();
            });
            return lookupProvider;
          },
        ),

        // ✅ Feature providers are created lazily in routes using ProviderRegistry
        // This maintains lazy loading while providing persistence across navigation
      ],
      child: MaterialApp.router(
        title: 'eRents Desktop',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter().router,
        theme: appTheme,
        builder:
            (context, child) =>
                Stack(children: [child!, const GlobalErrorDialog()]),
      ),
    );
  }
}
