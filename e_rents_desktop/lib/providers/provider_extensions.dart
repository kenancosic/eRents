import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import the services and providers that will be used
import '../services/api_service.dart';
import '../services/secure_storage_service.dart';
import '../services/lookup_service.dart';
import 'lookup_provider.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/properties/providers/property_provider.dart';

/// Extensions for easier provider access
/// 
/// Usage:
/// ```dart
/// final auth = context.providers.auth;  // Get AuthProvider
/// final props = context.providers.properties;  // Get PropertiesProvider
/// 
/// // Or access any provider directly
/// final anyProvider = context.providers.get<YourProvider>();
/// ```
extension ProviderExtension on BuildContext {
  /// Provides access to all providers with a clean syntax
  _ProviderAccessor get providers => _ProviderAccessor(this);
}

/// Helper class to provide clean access to providers
class _ProviderAccessor {
  final BuildContext _context;
  
  _ProviderAccessor(this._context);
  
  // Core providers
  ApiService get api => _get<ApiService>();
  SecureStorageService get secureStorage => _get<SecureStorageService>();
  LookupService get lookupService => _get<LookupService>();
  
  // Feature providers
  AuthProvider get auth => _get<AuthProvider>();
  PropertyProvider get properties => _get<PropertyProvider>();
  LookupProvider get lookups => _get<LookupProvider>();
  
  // Generic provider accessor
  T get<T>() => _get<T>();
  
  // Private method to get a provider instance
  T _get<T>() => _context.read<T>();
  
  // Watch a provider for changes
  T watch<T>() => _context.watch<T>();
  
  // Read a provider without listening
  T read<T>() => _context.read<T>();
}
