import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/auth_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/theme/theme.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenant_provider.dart';
import 'package:e_rents_desktop/features/statistics/providers/statistics_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/services/user_preferences_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'services/amenity_service.dart';
import 'base/navigation_provider.dart';
import 'base/preference_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Get base URL from environment
  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';

  // Initialize services
  final prefsService = UserPreferencesService();
  final secureStorageService = SecureStorageService();
  final authService = AuthService(baseUrl, secureStorageService);
  final apiService = ApiService(baseUrl, secureStorageService);
  final amenityService = AmenityService.create();

  runApp(
    MultiProvider(
      providers: [
        // Authentication related providers
        ChangeNotifierProvider(create: (_) => AuthProvider(authService)),
        Provider.value(value: authService),

        // App State/Navigation providers
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(
          create: (_) => PreferencesProvider(preferencesService: prefsService),
        ),

        // Feature specific providers (can also be provided closer to features)
        ChangeNotifierProvider(create: (_) => PropertyProvider(apiService)),
        ChangeNotifierProvider<MaintenanceProvider>(
          create: (context) => MaintenanceProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider<StatisticsProvider>(
          create: (context) => StatisticsProvider(),
        ),

        // Core Services (can be accessed anywhere)
        Provider.value(value: apiService),
        Provider.value(value: secureStorageService),
        Provider.value(value: prefsService),
        Provider.value(value: amenityService),
      ],
      child: MaterialApp.router(
        title: 'eRents Desktop',
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter().router,
        theme: appTheme,
      ),
    ),
  );
}
