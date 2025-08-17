import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core services
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../services/user_preferences_service.dart';

// Import all feature providers
import 'auth/providers/auth_provider.dart';
import 'chat/providers/chat_provider.dart';
import 'home/providers/home_provider.dart';
import 'maintenance/providers/maintenance_provider.dart';
import 'profile/providers/profile_provider.dart';
import 'properties/providers/property_provider.dart';
import 'rents/providers/rents_provider.dart';
import 'reports/providers/reports_provider.dart';
import '../providers/lookup_provider.dart';

/// Helper class to manage provider dependencies
class ProviderDependencies {
  final ApiService apiService;
  final SecureStorageService secureStorage;
  final UserPreferencesService userPreferences;
  final BuildContext? context; // For providers that need BuildContext

  ProviderDependencies({
    required this.apiService,
    required this.secureStorage,
    required this.userPreferences,
    this.context,
  });
}

/// Comprehensive feature registration system
/// Centralizes all provider registration in a clean, maintainable way
class FeaturesRegistry {
  /// Creates and configures all feature providers with their dependencies
  /// This method handles all provider registration, including special cases
  static List<ChangeNotifierProvider> createFeatureProviders(ProviderDependencies deps) {
    return [
      // Core Authentication Provider
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(
          apiService: deps.apiService,
          storage: deps.secureStorage,
        ),
      ),
      
      // Feature Providers (alphabetical order for maintainability)
      ChangeNotifierProvider<ChatProvider>(
        create: (_) => ChatProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<HomeProvider>(
        create: (_) => HomeProvider(deps.apiService),
      ),
      
      // Lookup Provider (core system provider)
      ChangeNotifierProvider<LookupProvider>(
        create: (_) => LookupProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<MaintenanceProvider>(
        create: (_) => MaintenanceProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<ProfileProvider>(
        create: (_) => ProfileProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<PropertyProvider>(
        create: (_) => PropertyProvider(deps.apiService),
      ),
      
      // Special case: RentsProvider needs BuildContext
      ChangeNotifierProvider<RentsProvider>(
        create: (context) => deps.context != null 
          ? RentsProvider(deps.apiService, context: deps.context!)
          : throw Exception('RentsProvider requires BuildContext. Use createContextualProviders instead.'),
      ),
      
      ChangeNotifierProvider<ReportsProvider>(
        create: (_) => ReportsProvider(deps.apiService),
      ),
    ];
  }

  /// Creates providers that need BuildContext after the widget tree is built
  /// This handles the special case of RentsProvider and any future providers that need context
  static List<ChangeNotifierProvider> createContextualProviders(
    ProviderDependencies deps, 
    BuildContext context
  ) {
    final contextualDeps = ProviderDependencies(
      apiService: deps.apiService,
      secureStorage: deps.secureStorage,
      userPreferences: deps.userPreferences,
      context: context,
    );

    return [
      ChangeNotifierProvider<RentsProvider>.value(
        value: RentsProvider(contextualDeps.apiService, context: context),
      ),
    ];
  }

  /// Widget that provides all features to the widget tree
  /// This is the main entry point for registering all feature providers
  static Widget provideFeatures({
    required ProviderDependencies dependencies,
    required Widget child,
    BuildContext? context,
  }) {
    return MultiProvider(
      providers: createFeatureProviders(dependencies),
      child: child,
    );
  }
}

/// Convenience widget for providing all features
class FeatureProvidersWrapper extends StatelessWidget {
  final Widget child;
  final ProviderDependencies dependencies;

  const FeatureProvidersWrapper({
    super.key,
    required this.child,
    required this.dependencies,
  });

  @override
  Widget build(BuildContext context) {
    return FeaturesRegistry.provideFeatures(
      dependencies: dependencies,
      context: context,
      child: child,
    );
  }
}