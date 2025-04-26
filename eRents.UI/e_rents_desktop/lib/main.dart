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

void main() {
  runApp(
    MultiProvider(
      providers: [
        Provider<ApiService>(
          create:
              (_) =>
                  ApiService('http://localhost:5000', SecureStorageService()),
        ),
        ProxyProvider<ApiService, AuthService>(
          update:
              (_, apiService, __) => AuthService(
                apiService.baseUrl,
                apiService.secureStorageService,
              ),
        ),
        ChangeNotifierProxyProvider<AuthService, AuthProvider>(
          create:
              (_) => AuthProvider(
                ApiService('http://localhost:5000', SecureStorageService()),
              ),
          update: (_, authService, authProvider) {
            authProvider?.authService = authService;
            return authProvider ??
                AuthProvider(
                  ApiService('http://localhost:5000', SecureStorageService()),
                );
          },
        ),
        ChangeNotifierProvider<PropertyProvider>(
          create: (context) => PropertyProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider<MaintenanceProvider>(
          create: (context) => MaintenanceProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider<StatisticsProvider>(
          create: (context) => StatisticsProvider(),
        ),
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Row(children: [

        ],
      ));
  }
}
