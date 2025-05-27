import 'package:e_rents_mobile/core/base/navigation_provider.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';
import 'package:e_rents_mobile/feature/auth/auth_service.dart';
import 'package:e_rents_mobile/feature/home/home_service.dart' as feature_home;
import 'package:e_rents_mobile/core/services/home_service.dart'
    as core_services;
import 'package:e_rents_mobile/feature/profile/user_service.dart';
import 'package:e_rents_mobile/feature/profile/user_provider.dart';
import 'package:e_rents_mobile/feature/profile/user_bookings_provider.dart';
import 'package:e_rents_mobile/core/services/booking_service.dart';
import 'package:e_rents_mobile/core/services/maintenance_service.dart';
import 'package:e_rents_mobile/core/services/lease_service.dart';
import 'package:e_rents_mobile/feature/saved/saved_provider.dart';
import 'package:e_rents_mobile/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/feature/home/home_provider.dart';
import 'core/base/error_provider.dart';
import 'core/widgets/global_error_dialog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/.env");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // Initialize the AppRouter
  final AppRouter _appRouter = AppRouter();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<SecureStorageService>(create: (_) => SecureStorageService()),
        ProxyProvider<SecureStorageService, ApiService>(
          update: (_, secureStorageService, __) => ApiService(
            const String.fromEnvironment('baseUrl',
                defaultValue:
                    'http://10.0.2.2:5000'), // Updated to match backend port
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
        ProxyProvider<ApiService, feature_home.HomeService>(
          update: (_, apiService, __) => feature_home.HomeService(apiService),
        ),
        ChangeNotifierProvider<HomeProvider>(
          create: (context) => HomeProvider(
            context.read<core_services.HomeService>(),
            context.read<feature_home.HomeService>(),
          ),
        ),
        ProxyProvider<ApiService, UserService>(
          update: (_, apiService, __) => UserService(apiService),
        ),
        ChangeNotifierProvider<UserProvider>(
          create: (context) => UserProvider(context.read<UserService>()),
        ),
        ProxyProvider<ApiService, BookingService>(
          update: (_, apiService, __) => BookingService(apiService),
        ),
        ProxyProvider<ApiService, MaintenanceService>(
          update: (_, apiService, __) => MaintenanceService(apiService),
        ),
        ProxyProvider<ApiService, LeaseService>(
          update: (_, apiService, __) => LeaseService(apiService),
        ),
        ChangeNotifierProvider<UserBookingsProvider>(
          create: (context) =>
              UserBookingsProvider(context.read<BookingService>()),
        ),
        ChangeNotifierProvider<NavigationProvider>(
          create: (context) => NavigationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => SavedProvider()),
        ChangeNotifierProvider(create: (_) => ErrorProvider()),
      ],
      child: Builder(
        builder: (context) => Stack(
          children: [
            MaterialApp.router(
              title: 'eRents',
              theme: appTheme,
              routerConfig: _appRouter.router,
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
