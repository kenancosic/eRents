import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:e_rents_mobile/core/base/navigation_provider.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/features/features_registry.dart';
import 'package:e_rents_mobile/features/auth/auth_provider.dart';
import 'package:e_rents_mobile/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/base/error_provider.dart';
import 'core/widgets/global_error_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/.env");

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Create shared service instances
    final secureStorageService = SecureStorageService();
    final apiService = ApiService(
      dotenv.env['API_BASE_URL'] ?? 'http://localhost:8080',
      secureStorageService,
    );
    
    // Initialize dependencies
    final dependencies = ProviderDependencies(
      apiService: apiService,
      secureStorage: secureStorageService,
    );
    
    return MultiProvider(
      providers: [
        // Provide shared services
        Provider<SecureStorageService>.value(value: secureStorageService),
        Provider<ApiService>.value(value: apiService),
        
        // Core system providers (not feature-specific)
        ChangeNotifierProvider<NavigationProvider>(
          create: (context) => NavigationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ErrorProvider()),

        // Register all feature providers via centralized registry
        ...FeaturesRegistry.createFeatureProviders(dependencies),
      ],
      child: Builder(
        builder: (context) {
          final authProvider = context.watch<AuthProvider>();
          final appRouter = AppRouter(authProvider);
          return Stack(
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
          );
        },
      ),
    );
  }
}
