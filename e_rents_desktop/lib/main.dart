import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/auth_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/theme/theme.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_details_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:e_rents_desktop/features/statistics/providers/statistics_provider.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/services/user_preferences_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/amenity_service.dart';
import 'services/booking_service.dart';
import 'services/review_service.dart';
import 'base/navigation_provider.dart';
import 'base/preference_provider.dart';
import 'services/statistics_service.dart';
import 'services/chat_service.dart';
import 'services/maintenance_service.dart';
import 'services/property_service.dart';
import 'services/profile_service.dart';
import 'services/report_service.dart';
import 'features/reports/providers/reports_provider.dart';
import 'services/tenant_service.dart';
import 'package:e_rents_desktop/features/home/providers/home_provider.dart';
import 'base/error_provider.dart';
import 'widgets/global_error_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Try to load .env file, but don't crash if it doesn't exist
  try {
    await dotenv.load(fileName: "lib/.env");
  } catch (e) {
    print('Warning: .env file not found. Some features may be limited: $e');
    // Initialize with empty values if .env doesn't exist
    dotenv.env.clear();
  }

  // Get base URL from environment
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
  print('Using API Base URL: $baseUrl');

  // Initialize services
  final prefsService = UserPreferencesService();
  final secureStorageService = SecureStorageService();
  final authService = AuthService(baseUrl, secureStorageService);
  final amenityService = AmenityService.create();
  final bookingService = BookingService(baseUrl, secureStorageService);
  final reviewService = ReviewService(baseUrl, secureStorageService);
  final chatService = ChatService(baseUrl, secureStorageService);
  final maintenanceService = MaintenanceService(baseUrl, secureStorageService);
  final propertyService = PropertyService(baseUrl, secureStorageService);
  final profileService = ProfileService(baseUrl, secureStorageService);
  final reportService = ReportService(baseUrl, secureStorageService);
  final statisticsService = StatisticsService(baseUrl, secureStorageService);
  final tenantService = TenantService(baseUrl, secureStorageService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ErrorProvider()),

        // Core Services (must be first so other providers can access them)
        Provider.value(value: secureStorageService),
        Provider.value(value: prefsService),
        Provider.value(value: authService),
        Provider.value(value: amenityService),
        Provider.value(value: bookingService),
        Provider.value(value: reviewService),
        Provider.value(value: chatService),
        Provider.value(value: maintenanceService),
        Provider.value(value: propertyService),
        Provider.value(value: profileService),
        Provider.value(value: reportService),
        Provider.value(value: statisticsService),
        Provider.value(value: tenantService),

        // Authentication related providers
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),

        // App State/Navigation providers
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => PreferencesProvider(preferencesService: prefsService),
        ),

        // Feature specific providers (these can now access services via context.read)
        ChangeNotifierProvider(
          create:
              (context) => PropertyProvider(
                context.read<PropertyService>(),
                context.read<AmenityService>(),
              ),
        ),
        ChangeNotifierProvider(
          create:
              (context) => PropertyDetailsProvider(
                context.read<BookingService>(),
                context.read<ReviewService>(),
                context.read<StatisticsService>(),
                context.read<MaintenanceService>(),
              ),
        ),
        ChangeNotifierProvider<MaintenanceProvider>(
          create:
              (context) =>
                  MaintenanceProvider(context.read<MaintenanceService>()),
        ),
        ChangeNotifierProvider<TenantProvider>(
          create: (context) => TenantProvider(context.read<TenantService>()),
        ),
        ChangeNotifierProvider<StatisticsProvider>(
          create:
              (context) =>
                  StatisticsProvider(context.read<StatisticsService>()),
        ),
        ChangeNotifierProvider<ChatProvider>(
          create:
              (context) => ChatProvider(
                context.read<ChatService>(),
                context.read<AuthProvider>(),
              ),
        ),
        ChangeNotifierProvider<ReportsProvider>(
          create:
              (context) =>
                  ReportsProvider(reportService: context.read<ReportService>()),
        ),
        ChangeNotifierProvider<HomeProvider>(
          create: (context) => HomeProvider(context.read<StatisticsService>()),
        ),
        // MockDataService temporarily disabled due to type mismatches
        // Provider<MockDataService>(
        //   create: (context) => MockDataService(),
        // ),
        // ReviewService temporarily disabled due to model mismatch
        // Provider<ReviewService>(
        //   create: (context) => ReviewService(context.read<ApiService>()),
        // ),
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
    ),
  );
}
