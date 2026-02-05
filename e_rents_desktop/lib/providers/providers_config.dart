import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

// Core services
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../services/user_preferences_service.dart';
import '../services/image_service.dart';

// Import all feature providers
import '../features/auth/providers/auth_provider.dart';
import '../features/chat/providers/chat_provider.dart';
import '../features/home/providers/home_provider.dart';
import '../features/maintenance/providers/maintenance_provider.dart';
import '../features/profile/providers/profile_provider.dart';
import '../features/properties/providers/property_provider.dart';
import '../features/rents/providers/rents_provider.dart';
import '../features/reports/providers/reports_provider.dart';
import 'lookup_provider.dart';

/// Helper class to manage provider dependencies
class ProviderDependencies {
  final ApiService apiService;
  final SecureStorageService secureStorage;
  final UserPreferencesService userPreferences;

  ProviderDependencies({
    required this.apiService,
    required this.secureStorage,
    required this.userPreferences,
  });
}

/// Creates and configures all providers with their dependencies
List<SingleChildWidget> createAppProviders(ProviderDependencies deps) {
  return [
    // Core services exposed via Provider for app-wide access
    Provider<ApiService>.value(
      value: deps.apiService,
    ),
    Provider<ImageService>.value(
      value: ImageService(deps.apiService),
    ),
    ChangeNotifierProvider<AuthProvider>(
      create: (_) => AuthProvider(
        apiService: deps.apiService,
        storage: deps.secureStorage,
      ),
    ),
    
    // Feature providers
    ChangeNotifierProvider<PropertyProvider>(
      create: (_) => PropertyProvider(deps.apiService),
    ),
    ChangeNotifierProvider<LookupProvider>(
      create: (_) => LookupProvider(deps.apiService),
    ),
    ChangeNotifierProvider<ChatProvider>(
      create: (_) => ChatProvider(deps.apiService),
    ),
    ChangeNotifierProvider<HomeProvider>(
      create: (_) => HomeProvider(deps.apiService),
    ),
    ChangeNotifierProvider<MaintenanceProvider>(
      create: (_) => MaintenanceProvider(deps.apiService),
    ),
    ChangeNotifierProvider<ProfileProvider>(
      create: (_) => ProfileProvider(deps.apiService),
    ),
    // RentsProvider is initialized in main.dart where we have access to BuildContext
    // This is a placeholder that will be replaced in main.dart
    ChangeNotifierProvider<RentsProvider>(
      create: (_) => throw UnimplementedError('RentsProvider should be initialized in main.dart'),
    ),
    ChangeNotifierProvider<ReportsProvider>(
      create: (_) => ReportsProvider(deps.apiService),
    ),
    
    
  ];
}

/// Widget that provides all providers to the widget tree
class AppProviders extends StatelessWidget {
  final Widget child;
  final ProviderDependencies dependencies;

  const AppProviders({
    super.key,
    required this.child,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: createAppProviders(dependencies),
      child: child,
    );
  }
}
