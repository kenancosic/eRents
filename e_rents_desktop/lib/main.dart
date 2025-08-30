import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// Core services
import 'services/api_service.dart';
import 'services/secure_storage_service.dart';
import 'services/user_preferences_service.dart';
import 'services/image_service.dart';

// Router and theme
import 'router.dart';
import 'theme/theme.dart';

// Widgets
import 'widgets/global_error_dialog.dart';

// Base providers
import 'base/app_state_providers.dart';

// Comprehensive feature registration system
import 'features/features.dart' as features;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    print('Loading .env file...');
    await dotenv.load(fileName: "lib/.env");
    print('Successfully loaded .env file');
    print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
  } catch (e) {
    print('Error loading .env file: $e');
    // Initialize with default values if .env loading fails
    dotenv.env['API_BASE_URL'] = 'http://localhost:5000/api';
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
    
    // Create provider dependencies for all features
    final dependencies = features.ProviderDependencies(
      apiService: apiService,
      secureStorage: secureStorage,
      userPreferences: userPrefs,
    );

    // Use the new comprehensive feature registration system
    return MultiProvider(
      providers: [
        // Add the missing AppErrorProvider
        ChangeNotifierProvider<AppErrorProvider>(
          create: (_) => AppErrorProvider(),
        ),
        // Provide ImageService globally so widgets can read it
        Provider<ImageService>.value(
          value: ImageService(apiService),
        ),
        ...features.FeaturesRegistry.createFeatureProviders(dependencies),
      ],
      child: Builder(
        builder: (context) {
          // LookupProvider now fetches lookup data on-demand via generic API.
          // No global initialize is needed here.
          
          // Handle special case for RentsProvider that needs BuildContext
          final contextualDependencies = features.ProviderDependencies(
            apiService: apiService,
            secureStorage: secureStorage,
            userPreferences: userPrefs,
            context: context,
          );
          
          return MultiProvider(
            providers: [
              // Override the RentsProvider with the one that has BuildContext
              ChangeNotifierProvider<features.RentsProvider>.value(
                value: features.RentsProvider(contextualDependencies.apiService, context: context),
              ),
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
    final authProvider = context.watch<features.AuthProvider>();
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
