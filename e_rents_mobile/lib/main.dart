import 'package:e_rents_mobile/core/services/service_locator.dart';
import 'package:e_rents_mobile/core/base/navigation_provider.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';
import 'package:e_rents_mobile/feature/auth/auth_service.dart';
import 'package:e_rents_mobile/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/base/error_provider.dart';
import 'core/widgets/global_error_dialog.dart';
import 'package:e_rents_mobile/feature/property_detail/providers/property_collection_provider.dart';
import 'package:e_rents_mobile/feature/profile/providers/user_detail_provider.dart';
import 'package:e_rents_mobile/feature/profile/providers/booking_collection_provider.dart';
import 'package:e_rents_mobile/feature/property_detail/providers/review_collection_provider.dart';
import 'package:e_rents_mobile/feature/property_detail/providers/maintenance_collection_provider.dart';
import 'package:e_rents_mobile/feature/home/providers/home_dashboard_provider.dart';
import 'package:e_rents_mobile/feature/saved/saved_collection_provider.dart';
// PropertyDetailProvider import moved to where it's used

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "lib/.env");

  // Initialize ServiceLocator with lazy loading
  await ServiceLocator.setupServices();

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
        // 🚀 NEW REPOSITORY ARCHITECTURE - All providers use ServiceLocator

        // Essential providers that still need manual setup
        Provider<AuthService>(
          create: (context) => AuthService(
            ServiceLocator.get(), // ApiService
            ServiceLocator.get(), // SecureStorageService
          ),
        ),
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
          ),
        ),
        ChangeNotifierProvider<NavigationProvider>(
          create: (context) => NavigationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ErrorProvider()),

        // 🎯 REPOSITORY-BASED PROVIDERS - Modern architecture with automatic features
        ChangeNotifierProvider<PropertyCollectionProvider>(
          create: (_) => ServiceLocator.get<PropertyCollectionProvider>(),
        ),
        ChangeNotifierProvider<UserDetailProvider>(
          create: (_) => ServiceLocator.get<UserDetailProvider>(),
        ),
        ChangeNotifierProvider<BookingCollectionProvider>(
          create: (_) => ServiceLocator.get<BookingCollectionProvider>(),
        ),
        ChangeNotifierProvider<ReviewCollectionProvider>(
          create: (_) => ServiceLocator.get<ReviewCollectionProvider>(),
        ),
        ChangeNotifierProvider<MaintenanceCollectionProvider>(
          create: (_) => ServiceLocator.get<MaintenanceCollectionProvider>(),
        ),
        ChangeNotifierProvider<HomeDashboardProvider>(
          create: (_) => ServiceLocator.get<HomeDashboardProvider>(),
        ),
        ChangeNotifierProvider<SavedCollectionProvider>(
          create: (_) => ServiceLocator.get<SavedCollectionProvider>(),
        ),

        // 📝 USAGE EXAMPLES:
        //
        // In screens, use these providers like this:
        //
        // Consumer<PropertyCollectionProvider>(
        //   builder: (context, propertyProvider, _) {
        //     if (propertyProvider.isLoading) return CircularProgressIndicator();
        //     if (propertyProvider.hasError) return Text('Error: ${propertyProvider.errorMessage}');
        //
        //     return ListView.builder(
        //       itemCount: propertyProvider.items.length,
        //       itemBuilder: (context, index) => PropertyCard(propertyProvider.items[index]),
        //     );
        //   },
        // )
        //
        // For property details, use:
        // final detailProvider = ServiceLocator.get<PropertyDetailProvider>();
        // detailProvider.loadItem(propertyId.toString());
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
