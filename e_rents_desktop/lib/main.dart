import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'base/app_state_providers.dart';
import 'widgets/global_error_dialog.dart';

// Service imports
import 'services/api_service.dart';
import 'services/secure_storage_service.dart';
import 'services/user_preferences_service.dart';
import 'services/lookup_service.dart';

// Provider imports
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'providers/lookup_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: "lib/.env");
  } catch (e) {
    dotenv.env.clear();
  }

  runApp(const ERentsApp());
}

class ERentsApp extends StatelessWidget {
  const ERentsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://localhost:5000';

    return MultiProvider(
      providers: [
        // Core services that can be accessed by any provider
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        Provider<UserPreferencesService>(create: (_) => UserPreferencesService()),
        Provider<ApiService>(
          create: (context) => ApiService(
            baseUrl,
            context.read<SecureStorageService>(),
          ),
        ),
        Provider<LookupService>(
          create: (context) => LookupService(
            baseUrl,
            context.read<SecureStorageService>(),
          ),
        ),

        // Core state providers
        ChangeNotifierProvider(create: (_) => AppErrorProvider()),
        ChangeNotifierProvider(create: (_) => NavigationStateProvider()),
        ChangeNotifierProvider(
          create: (context) => PreferencesStateProvider(
            context.read<UserPreferencesService>(),
          ),
        ),

        // AuthProvider depends on ApiService and SecureStorageService
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            apiService: context.read<ApiService>(),
            storage: context.read<SecureStorageService>(),
          ),
        ),

        // Other providers can be added here if they are needed globally
        ChangeNotifierProvider<LookupProvider>(
          create: (context) {
            final lookupProvider = LookupProvider(context.read<LookupService>());
            WidgetsBinding.instance.addPostFrameCallback((_) {
              lookupProvider.initializeLookupData();
            });
            return lookupProvider;
          },
        ),
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
