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

    // Use the comprehensive feature registration system
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
      child: const AppWithRouter(),
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
  bool _chatLifecycleInitialized = false;

  @override
  void initState() {
    super.initState();
    // Wire up chat lifecycle after first frame to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupChatLifecycle();
    });
  }

  void _setupChatLifecycle() {
    if (_chatLifecycleInitialized) return;
    _chatLifecycleInitialized = true;

    final authProvider = context.read<features.AuthProvider>();
    final chatProvider = context.read<features.ChatProvider>();

    // Wire auth callbacks to chat lifecycle
    authProvider.onLoginSuccess = () {
      debugPrint('ChatLifecycle: Login detected, connecting SignalR...');
      chatProvider.connectRealtime();
    };

    authProvider.onLogoutComplete = () {
      debugPrint('ChatLifecycle: Logout detected, disconnecting SignalR...');
      chatProvider.disconnectRealtime();
    };

    // If already authenticated (token exists), connect immediately
    if (authProvider.isAuthenticated) {
      debugPrint('ChatLifecycle: Already authenticated, connecting SignalR...');
      chatProvider.connectRealtime();
    }
  }

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
