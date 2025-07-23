import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// New imports from Phase 1
import 'base/app_state_providers.dart';
import 'widgets/global_error_dialog.dart';

// Service imports
import 'services/api_service.dart';
import 'services/secure_storage_service.dart';
import 'services/user_preferences_service.dart';
import 'services/lookup_service.dart';

// Provider imports (only essential ones loaded at startup)
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'providers/lookup_provider.dart';
import 'package:e_rents_desktop/features/maintenance/providers/maintenance_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/properties_provider.dart';
import 'package:e_rents_desktop/features/profile/providers/profile_provider.dart';
import 'package:e_rents_desktop/features/reports/providers/reports_provider.dart';
import 'package:e_rents_desktop/features/statistics/providers/statistics_provider.dart';
import 'package:e_rents_desktop/features/tenants/providers/tenants_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment
  try {
    await dotenv.load(fileName: "lib/.env");
  } catch (e) {
    dotenv.env.clear();
  }

  final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';

  // Manually instantiate services
  final secureStorage = SecureStorageService();
  final apiService = ApiService(baseUrl, secureStorage);
  final userPrefsService = UserPreferencesService();
  final lookupService = LookupService(baseUrl, secureStorage);

  runApp(ERentsApp(
    apiService: apiService,
    secureStorage: secureStorage,
    userPrefsService: userPrefsService,
    lookupService: lookupService,
  ));
}

class ERentsApp extends StatelessWidget {
  final ApiService apiService;
  final SecureStorageService secureStorage;
  final UserPreferencesService userPrefsService;
  final LookupService lookupService;

  const ERentsApp({
    super.key,
    required this.apiService,
    required this.secureStorage,
    required this.userPrefsService,
    required this.lookupService,
  });

  @override
  Widget build(BuildContext context) {
    // First, create the AuthProvider instance since AppRouter depends on it.
    final authProvider = AuthProvider(
      apiService: apiService,
      storage: secureStorage,
    );

    // Now, create the AppRouter and pass the AuthProvider to it.
    final appRouter = AppRouter(authProvider);

    return MultiProvider(
      providers: [
        // Provide the existing AuthProvider instance to the widget tree.
        ChangeNotifierProvider.value(value: authProvider),

        // Other providers
        ChangeNotifierProvider(create: (_) => AppErrorProvider()),
        ChangeNotifierProvider(create: (_) => NavigationStateProvider()),
        ChangeNotifierProvider(
          create: (_) => PreferencesStateProvider(userPrefsService),
        ),

        // Feature Providers - Order matters for dependencies
        ChangeNotifierProvider(create: (context) => ProfileProvider(apiService)),
        ChangeNotifierProvider(create: (context) => TenantsProvider(apiService)),
        ChangeNotifierProvider(create: (context) => MaintenanceProvider(apiService)),
        ChangeNotifierProvider(create: (context) => StatisticsProvider(apiService)),
        ChangeNotifierProvider(create: (context) => ReportsProvider(apiService)),

        // Dependent Feature Providers
        ChangeNotifierProxyProvider<MaintenanceProvider, PropertiesProvider>(
          create: (context) => PropertiesProvider(apiService, context.read<MaintenanceProvider>()),
          update: (context, maintenanceProvider, previous) =>
              PropertiesProvider(apiService, maintenanceProvider),
        ),
        ChangeNotifierProvider(
          create: (_) {
            final lookupProvider = LookupProvider(lookupService);
            // Defer the initialization until after the first frame is built.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              lookupProvider.initializeLookupData();
            });
            return lookupProvider;
          },
        ),
      ],
      child: MaterialApp.router(
        title: 'eRents Desktop',
        debugShowCheckedModeBanner: false,
        // Use the router from the AppRouter instance.
        routerConfig: appRouter.router,
        theme: appTheme,
        builder: (context, child) =>
            Stack(children: [child!, const GlobalErrorDialog()]),
      ),
    );
  }
}
