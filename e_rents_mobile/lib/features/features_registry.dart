import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core services
import '../core/services/api_service.dart';
import '../core/services/secure_storage_service.dart';

// Import all feature providers
import '../feature/auth/auth_provider.dart';
import '../feature/chat/chat_provider.dart';
import '../feature/home/providers/home_provider.dart';
import '../feature/checkout/providers/checkout_provider.dart';
import '../feature/saved/saved_provider.dart';
import '../feature/profile/providers/user_profile_provider.dart';
import '../feature/profile/providers/user_bookings_provider.dart';
import '../feature/profile/providers/tenant_preferences_provider.dart';
import '../feature/profile/providers/payment_methods_provider.dart';
import '../feature/explore/providers/property_search_provider.dart';
import '../feature/explore/providers/featured_properties_provider.dart';
import '../feature/explore/providers/property_availability_provider.dart';
import '../feature/property_detail/providers/property_data_provider.dart';
import '../feature/property_detail/providers/property_collections_provider.dart';
import '../feature/property_detail/providers/property_reviews_provider.dart';
import '../feature/property_detail/providers/maintenance_issues_provider.dart';
import '../feature/property_detail/providers/property_booking_provider.dart';
import '../feature/property_detail/providers/lease_extension_provider.dart';
import '../feature/property_detail/providers/property_pricing_provider.dart';

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
      // Core Services - provided as values since they're already instantiated
      Provider<ApiService>.value(value: deps.apiService),
      Provider<SecureStorageService>.value(value: deps.secureStorage),
      
      // Core System Providers
      ChangeNotifierProvider<NavigationProvider>(
        create: (_) => NavigationProvider(),
      ),
      
      ChangeNotifierProvider<ErrorProvider>(
        create: (_) => ErrorProvider(),
      ),
      
      // Core Authentication Provider (must be first for dependency chain)
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(deps.apiService, deps.secureStorage),
      ),
      
      // Feature Providers (alphabetical order for maintainability)
      ChangeNotifierProvider<ChatProvider>(
        create: (_) => ChatProvider(deps.apiService),
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
      
      ChangeNotifierProvider<TenantPreferencesProvider>(
        create: (_) => TenantPreferencesProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<PaymentMethodsProvider>(
        create: (_) => PaymentMethodsProvider(deps.apiService),
      ),
      
      // Explore Feature Providers
      ChangeNotifierProvider<PropertySearchProvider>(
        create: (_) => PropertySearchProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<FeaturedPropertiesProvider>(
        create: (_) => FeaturedPropertiesProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<PropertyAvailabilityProvider>(
        create: (_) => PropertyAvailabilityProvider(deps.apiService),
      ),
      
      // Property Detail Feature Providers
      ChangeNotifierProvider<PropertyDataProvider>(
        create: (_) => PropertyDataProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<PropertyCollectionsProvider>(
        create: (_) => PropertyCollectionsProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<PropertyReviewsProvider>(
        create: (_) => PropertyReviewsProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<MaintenanceIssuesProvider>(
        create: (_) => MaintenanceIssuesProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<PropertyBookingProvider>(
        create: (_) => PropertyBookingProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<LeaseExtensionProvider>(
        create: (_) => LeaseExtensionProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<PropertyPricingProvider>(
        create: (_) => PropertyPricingProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<PropertyAvailabilityProvider>(
        create: (_) => PropertyAvailabilityProvider(deps.apiService),
      ),
      
      ChangeNotifierProvider<SavedProvider>(
        create: (_) => SavedProvider(deps.apiService, deps.secureStorage),
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