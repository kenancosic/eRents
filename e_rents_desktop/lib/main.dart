import 'package:e_rents_desktop/app_service_registrations.dart';
import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// New imports from Phase 1
import 'base/base.dart'; // Barrel file for all base imports
import 'widgets/global_error_dialog.dart';

// Service imports
import 'services/auth_service.dart';
import 'services/user_preferences_service.dart';
import 'services/lookup_service.dart';

// Provider imports (only essential ones loaded at startup)
import 'features/auth/providers/auth_provider.dart';
import 'providers/lookup_provider.dart';

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

  // Register all services through the central registration hub
  AppServiceRegistrations.registerServices(locator, baseUrl);
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
