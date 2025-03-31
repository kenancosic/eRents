import 'package:e_rents_desktop/router.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/services/auth_service.dart';
import 'package:e_rents_desktop/services/secure_storage_service.dart';
import 'package:e_rents_desktop/theme/theme.dart';
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
              (_, secureStorageService, __) => ApiService(
                const String.fromEnvironment(
                  'baseUrl',
                  defaultValue: 'http://10.0.2.2:4000',
                ),
                secureStorageService,
              ),
        ),
        ProxyProvider<ApiService, AuthService>(
          update:
              (context, apiService, authService) =>
                  AuthService(apiService, context.read<SecureStorageService>()),
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
