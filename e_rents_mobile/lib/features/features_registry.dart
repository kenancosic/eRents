import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core services
import '../core/services/api_service.dart';
import '../core/services/secure_storage_service.dart';

// Import all feature providers
import 'auth/auth_provider.dart';
import 'chat/backend_chat_provider.dart';
import 'home/providers/home_provider.dart';
import 'checkout/providers/checkout_provider.dart';
import 'saved/saved_provider.dart';
import 'profile/providers/user_profile_provider.dart';
import 'profile/providers/user_bookings_provider.dart';
import 'profile/providers/invoices_provider.dart';
import 'explore/providers/property_search_provider.dart';
import 'explore/providers/featured_properties_provider.dart';
import 'package:e_rents_mobile/features/property_detail/providers/property_rental_provider.dart';
import 'users/providers/public_user_provider.dart';

// Core providers
import '../core/base/navigation_provider.dart';
import '../core/base/error_provider.dart';

/// Helper class to manage provider dependencies
class ProviderDependencies {
  final ApiService apiService;
  final SecureStorageService secureStorage;
  final BuildContext? context; // For providers that need BuildContext

  ProviderDependencies({
    required this.apiService,
    required this.secureStorage,
    this.context,
  });
}

/// Comprehensive feature registration system
/// Centralizes all provider registration in a clean, maintainable way
class FeaturesRegistry {
  /// Creates and configures all feature providers with their dependencies
  /// This method handles all provider registration, including core services
  static List<InheritedProvider> createFeatureProviders(ProviderDependencies deps) {
    return [
      // Core providers are expected to be provided in main.dart to avoid duplicates.
      // Feature Providers (alphabetical order for maintainability)
      // Feature Providers (alphabetical order for maintainability)
      ChangeNotifierProvider<BackendChatProvider>(
        create: (_) => BackendChatProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<CheckoutProvider>(
        create: (_) => CheckoutProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<HomeProvider>(
        create: (_) => HomeProvider(deps.apiService),
      ),
      
      // Profile Feature Providers
      ChangeNotifierProvider<UserProfileProvider>(
        create: (_) => UserProfileProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<UserBookingsProvider>(
        create: (_) => UserBookingsProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<InvoicesProvider>(
        create: (_) => InvoicesProvider(deps.apiService),
      ),
      
      // Explore Feature Providers
      ChangeNotifierProvider<PropertySearchProvider>(
        create: (_) => PropertySearchProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<FeaturedPropertiesProvider>(
        create: (_) => FeaturedPropertiesProvider(deps.apiService),
      ),
      
      // Property Detail Feature Providers
      ChangeNotifierProvider<PropertyRentalProvider>(
        create: (_) => PropertyRentalProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<SavedProvider>(
        create: (_) => SavedProvider(deps.apiService),
      ),
      
      // Public user profile feature
      ChangeNotifierProvider<PublicUserProvider>(
        create: (_) => PublicUserProvider(deps.apiService),
      ),
    ];
  }

  /// Creates providers that need BuildContext after the widget tree is built
  /// This handles special cases where providers need access to context
  static List<InheritedProvider> createContextualProviders(
      ProviderDependencies deps, BuildContext context) {
    // For now, no providers need context in mobile, but this method is here
    // for future extensibility and consistency with desktop
    return [];
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

  /// Helper method to create provider dependencies from existing services
  /// This simplifies the creation process when services are already available
  static ProviderDependencies createDependencies({
    required String baseUrl,
    required SecureStorageService secureStorage,
    BuildContext? context,
  }) {
    final apiService = ApiService(baseUrl, secureStorage);
    
    return ProviderDependencies(
      apiService: apiService,
      secureStorage: secureStorage,
      context: context,
    );
  }
}

/// Convenience widget for providing all features
/// Simplifies usage in main.dart and other top-level widgets
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

/// Extension methods for easier access to commonly used providers
extension ProviderAccessExtensions on BuildContext {
  /// Quick access to ApiService
  ApiService get apiService => read<ApiService>();
  
  /// Quick access to SecureStorageService
  SecureStorageService get secureStorage => read<SecureStorageService>();
  
  /// Quick access to AuthProvider
  AuthProvider get authProvider => read<AuthProvider>();
  
  /// Quick access to NavigationProvider
  NavigationProvider get navigationProvider => read<NavigationProvider>();
  
  /// Quick access to ErrorProvider
  ErrorProvider get errorProvider => read<ErrorProvider>();
}