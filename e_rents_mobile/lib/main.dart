import 'package:e_rents_mobile/core/services/service_locator.dart';
import 'package:e_rents_mobile/core/base/navigation_provider.dart';
import 'package:e_rents_mobile/core/utils/theme.dart';
import 'package:e_rents_mobile/feature/auth/auth_provider.dart';

import 'package:e_rents_mobile/feature/chat/chat_provider.dart';
import 'package:e_rents_mobile/feature/explore/explore_provider.dart';
import 'package:e_rents_mobile/feature/profile/providers/profile_provider.dart';
import 'package:e_rents_mobile/feature/home/providers/home_provider.dart';
import 'package:e_rents_mobile/feature/saved/saved_provider.dart';
import 'package:e_rents_mobile/routes/router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'core/base/error_provider.dart';
import 'core/widgets/global_error_dialog.dart';

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

        // Essential providers that still need manual setup
        ChangeNotifierProvider<AuthProvider>(
          create: (context) => AuthProvider(
            ServiceLocator.get(), // ApiService
            ServiceLocator.get(), // SecureStorageService
          ),
        ),
        ChangeNotifierProvider<NavigationProvider>(
          create: (context) => NavigationProvider(),
        ),
        ChangeNotifierProvider(create: (_) => ErrorProvider()),

        // 🎯 REPOSITORY-BASED PROVIDERS - Modern architecture with automatic features
        ChangeNotifierProvider<ExploreProvider>(
          create: (_) => ExploreProvider(ServiceLocator.get()),
        ),
        ChangeNotifierProvider<ProfileProvider>(
          create: (_) => ProfileProvider(ServiceLocator.get()),
        ),
        ChangeNotifierProvider<HomeProvider>(
          create: (_) => HomeProvider(ServiceLocator.get()),
        ),
        ChangeNotifierProvider<SavedProvider>(
          create: (context) => SavedProvider(
            ServiceLocator.get(), // ApiService
            ServiceLocator.get(), // SecureStorageService
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => ChatProvider(ServiceLocator.get()),
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
