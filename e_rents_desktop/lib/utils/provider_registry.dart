import 'package:flutter/foundation.dart';
import '../main.dart' show getService;

/// Registry to manage provider instances for persistence across navigation
/// while maintaining lazy loading architecture
class ProviderRegistry {
  static final ProviderRegistry _instance = ProviderRegistry._internal();
  factory ProviderRegistry() => _instance;
  ProviderRegistry._internal();

  final Map<Type, ChangeNotifier> _providers = {};

  /// Get or create a provider instance
  T getOrCreate<T extends ChangeNotifier>(T Function() factory) {
    if (_providers.containsKey(T)) {
      return _providers[T] as T;
    }

    final provider = factory();
    _providers[T] = provider;
    return provider;
  }

  /// Check if a provider exists
  bool exists<T extends ChangeNotifier>() {
    return _providers.containsKey(T);
  }

  /// Get existing provider (returns null if doesn't exist)
  T? get<T extends ChangeNotifier>() {
    return _providers[T] as T?;
  }

  /// Remove a provider from registry (useful for cleanup)
  void remove<T extends ChangeNotifier>() {
    final provider = _providers.remove(T);
    provider?.dispose();
  }

  /// Clear all providers (useful for logout)
  void clear() {
    for (final provider in _providers.values) {
      provider.dispose();
    }
    _providers.clear();
  }

  /// Get debug info about registered providers
  Map<String, bool> getDebugInfo() {
    return _providers.map(
      (type, provider) => MapEntry(
        type.toString(),
        !provider.hasListeners, // true if disposed
      ),
    );
  }
}
