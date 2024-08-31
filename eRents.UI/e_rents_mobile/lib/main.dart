import 'package:e_rents_mobile/core/base/navigation_provider.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';
import 'package:e_rents_mobile/feature/auth/data/auth_service.dart';
import 'package:e_rents_mobile/feature/home/data/home_service.dart';
import 'package:e_rents_mobile/feature/home/home_provider.dart';
import 'package:e_rents_mobile/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Initialize the AppRouter
  final AppRouter _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        ProxyProvider<SecureStorageService, ApiService>(
          update: (_, secureStorageService, __) => ApiService(
            const String.fromEnvironment('baseUrl',
                defaultValue: 'http://10.0.2.2:4000'),
            secureStorageService,
          ),
        ),
        Provider<AuthService>(
          create: (context) => AuthService(
            context.read<ApiService>(),
            context.read<SecureStorageService>(),
          ),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
          ),
        ),
        ProxyProvider<ApiService, HomeService>(
          update: (_, apiService, __) => HomeService(apiService),
        ),
        ChangeNotifierProvider<HomeProvider>(
          create: (context) => HomeProvider(context.read<HomeService>()),
        ),
        ChangeNotifierProvider<NavigationProvider>( // Add NavigationProvider
          create: (context) => NavigationProvider(),
        ),
      ],
      child: MaterialApp.router(
        title: 'eRents',
        theme: appTheme,
        routerConfig: _appRouter.router, // Use the GoRouter configuration
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
