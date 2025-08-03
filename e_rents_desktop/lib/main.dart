import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// Core services
import 'services/api_service.dart';
import 'services/secure_storage_service.dart';
import 'services/user_preferences_service.dart';

// Router and theme
import 'router.dart';
import 'theme/theme.dart';

// Widgets
import 'widgets/global_error_dialog.dart';

// Provider imports
import 'providers/providers_config.dart';
import 'features/rents/providers/rents_provider.dart';
import 'providers/lookup_provider.dart';
import 'features/auth/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Loading .env file...');
    await dotenv.load(fileName: ".env");
    print('Successfully loaded .env file');
    print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
  } catch (e) {
    print('Error loading .env file: $e');
    // Initialize with default values if .env loading fails
    dotenv.env['API_BASE_URL'] = 'http://localhost:5000';
    print('Using default API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
  }

  runApp(const ERentsApp());
}

class ERentsApp extends StatelessWidget {
  const ERentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';
    
    // Initialize services
    final secureStorage = SecureStorageService();
    final userPrefs = UserPreferencesService();
    final apiService = ApiService(baseUrl, secureStorage);
    
    // Create provider dependencies
    final deps = ProviderDependencies(
      apiService: apiService,
      secureStorage: secureStorage,
      userPreferences: userPrefs,
    );

    // Wrap the app with all providers
    return AppProviders(
      dependencies: deps,
      child: Builder(
        builder: (context) {
          // Initialize RentsProvider with BuildContext
          final rentsProvider = RentsProvider(
            deps.apiService,
            context: context,
          );
          
          // Initialize lookup data after first frame
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Provider.of<LookupProvider>(context, listen: false).initializeLookupData();
          });
          
          return MultiProvider(
            providers: [
              // Override the RentsProvider with the one that has BuildContext
              ChangeNotifierProvider<RentsProvider>.value(value: rentsProvider),
            ],
            child: const AppWithRouter(),
          );
        },
      ),
    );
  }
}

class AppWithRouter extends StatefulWidget {
  const AppWithRouter({super.key});

  @override
  State<AppWithRouter> createState() => _AppWithRouterState();
}

class _AppWithRouterState extends State<AppWithRouter> {
  AppRouter? _appRouter;
  bool? _lastAuthState;

  @override
  Widget build(BuildContext context) {
    // Only watch for authentication changes, not all AuthProvider changes
    final authProvider = context.watch<AuthProvider>();
    final currentAuthState = authProvider.isAuthenticated;
    
    // Only recreate router when authentication state actually changes
    if (_appRouter == null || _lastAuthState != currentAuthState) {
      _appRouter = AppRouter(authProvider);
      _lastAuthState = currentAuthState;
    }

    return MaterialApp.router(
      title: 'eRents Desktop',
      debugShowCheckedModeBanner: false,
      routerConfig: _appRouter!.router,
      theme: appTheme,
      builder: (context, child) => Stack(
        children: [child!, const GlobalErrorDialog()],
      ),
    );
  }
}
