import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:e_rents_mobile/core/base/navigation_provider.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/features/features_registry.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/features/chat/backend_chat_provider.dart';
import 'package:e_rents_mobile/core/managers/chat_lifecycle_manager.dart';
import 'package:e_rents_mobile/features/notifications/providers/notification_provider.dart';
import 'package:e_rents_mobile/core/managers/notification_lifecycle_manager.dart';
import 'package:e_rents_mobile/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:provider/provider.dart';
import 'core/base/error_provider.dart';
import 'core/widgets/global_error_dialog.dart';
import 'config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load environment variables BEFORE app starts
  try {
    await dotenv.load(fileName: "lib/.env");
    debugPrint('dotenv loaded successfully');
  } catch (e) {
    debugPrint('Failed to load .env file: $e');
  }
  
  // Run app after dotenv is loaded
  runApp(const MyApp());
}

/// Initialize services after app is running to prevent blocking the UI
Future<void> _initializeServices() async {
  // Initialize Stripe (dotenv is already loaded in main())
  final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];
  if (stripeKey != null && stripeKey.isNotEmpty && stripeKey.startsWith('pk_')) {
    try {
      Stripe.publishableKey = stripeKey;
      debugPrint('Stripe initialized with key: ${stripeKey.substring(0, 20)}...');
    } catch (e) {
      debugPrint('Failed to initialize Stripe: $e');
    }
  } else {
    debugPrint('Warning: Invalid or missing STRIPE_PUBLISHABLE_KEY, Stripe features disabled');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create shared service instances
    final secureStorageService = SecureStorageService();
    // Use API_BASE_URL from .env if available, otherwise fallback to Config constants
    final apiBase = dotenv.env['API_BASE_URL'] ?? (
      ((!kIsWeb || defaultTargetPlatform == TargetPlatform.windows) && defaultTargetPlatform == TargetPlatform.android)
        ? Config.baseUrl
        : Config.baseLocalhostUrl);
    final apiService = ApiService(apiBase, secureStorageService);
    
    // Initialize dependencies
    final dependencies = ProviderDependencies(
      apiService: apiService,
      secureStorage: secureStorageService,
    );
    
    // Create the AuthProvider instance for the router
    final authProvider = AuthProvider(apiService, secureStorageService);
    
    // Create the AppRouter instance outside of the Builder to prevent
    // duplicate GlobalKey issues
    final appRouter = AppRouter(authProvider);
    
    return MultiProvider(
      providers: [
        // Provide shared services
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<ApiService>.value(value: apiService),
        // Provide the shared AuthProvider instance used by the router
        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        
        // Core system providers (not feature-specific)
        ChangeNotifierProvider<NavigationProvider>(
          create: (context) => NavigationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ErrorProvider()),

        // Register all feature providers via centralized registry
        ...FeaturesRegistry.createFeatureProviders(dependencies),
      ],
      child: _ChatLifecycleWrapper(
        authProvider: authProvider,
        child: Stack(
          textDirection: TextDirection.ltr,
          children: [
            MaterialApp.router(
              title: 'eRents',
              theme: appTheme,
              routerConfig: appRouter.router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) => Stack(
                children: [
                  child!,
                  const GlobalErrorDialog(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wrapper widget that wires up chat lifecycle to auth events
class _ChatLifecycleWrapper extends StatefulWidget {
  final AuthProvider authProvider;
  final Widget child;

  const _ChatLifecycleWrapper({
    required this.authProvider,
    required this.child,
  });

  @override
  State<_ChatLifecycleWrapper> createState() => _ChatLifecycleWrapperState();
}

class _ChatLifecycleWrapperState extends State<_ChatLifecycleWrapper> {
  ChatLifecycleManager? _chatLifecycleManager;
  NotificationLifecycleManager? _notificationLifecycleManager;

  @override
  void initState() {
    super.initState();
    // Initialize services in background after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _setupChatLifecycle();
    });
  }

  void _setupChatLifecycle() {
    final chatProvider = context.read<BackendChatProvider>();
    _chatLifecycleManager = ChatLifecycleManager(chatProvider);
    _chatLifecycleManager!.initialize();

    // Wire auth callbacks to chat lifecycle
    widget.authProvider.onLoginSuccess = () {
      debugPrint('ChatLifecycle: Login detected, connecting SignalR...');
      _chatLifecycleManager?.onAuthenticated();
      _notificationLifecycleManager?.onAuthenticated();
    };

    widget.authProvider.onLogoutComplete = () {
      debugPrint('ChatLifecycle: Logout detected, disconnecting SignalR...');
      _chatLifecycleManager?.onLoggedOut();
      _notificationLifecycleManager?.onLoggedOut();
    };

    // If already authenticated (token exists), connect immediately
    if (widget.authProvider.isAuthenticated) {
      debugPrint('ChatLifecycle: Already authenticated, connecting SignalR...');
      _chatLifecycleManager?.onAuthenticated();
    }

    // Setup notification lifecycle
    _setupNotificationLifecycle();
  }

  void _setupNotificationLifecycle() {
    final notificationProvider = context.read<NotificationProvider>();
    _notificationLifecycleManager = NotificationLifecycleManager(notificationProvider);
    _notificationLifecycleManager!.initialize();

    if (widget.authProvider.isAuthenticated) {
      debugPrint('NotificationLifecycle: Already authenticated, connecting SignalR...');
      _notificationLifecycleManager?.onAuthenticated();
    }
  }

  @override
  void dispose() {
    _chatLifecycleManager?.dispose();
    _notificationLifecycleManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
