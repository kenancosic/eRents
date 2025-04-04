import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/auth_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/theme/theme.dart';
import 'package:e_rents_desktop/providers/property_provider.dart';
import 'package:e_rents_desktop/providers/auth_provider.dart';
import 'package:e_rents_desktop/providers/maintenance_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(eRentsDesktopApp());
}

class eRentsDesktopApp extends StatelessWidget {
  final AppRouter appRouter = AppRouter();

  eRentsDesktopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        ProxyProvider<SecureStorageService, ApiService>(
          update:
              (_, storage, __) => ApiService(
                const String.fromEnvironment(
                  'baseUrl',
                  defaultValue: 'http://localhost:3000',
                ),
                storage,
              ),
        ),
        ProxyProvider<ApiService, AuthService>(
          update:
              (_, api, __) => AuthService(
                const String.fromEnvironment(
                  'baseUrl',
                  defaultValue: 'http://localhost:3000',
                ),
                api.secureStorageService,
              ),
        ),
        ChangeNotifierProvider<PropertyProvider>(
          create: (context) => PropertyProvider(context.read<ApiService>()),
        ),
        ChangeNotifierProvider<MaintenanceProvider>(
          create: (context) => MaintenanceProvider(context.read<ApiService>()),
        ),
        ProxyProvider<AuthService, AuthProvider>(
          update: (_, auth, __) => AuthProvider(auth),
        ),
      ],
      child: MaterialApp.router(
        title: 'eRents Desktop',
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter.router,
        theme: appTheme,
      ),
    );
  }
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
