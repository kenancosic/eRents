import 'package:flutter/foundation.dart';
import 'app_error.dart';

/// Service locator for dependency injection with lazy initialization
class ServiceLocator {
  /// Singleton instance
  static final ServiceLocator _instance = ServiceLocator._internal();

  /// Factory constructor returns the singleton instance
  factory ServiceLocator() => _instance;

  /// Private constructor
  ServiceLocator._internal();

  /// Map of registered singletons
  final Map<Type, dynamic> _singletons = {};

  /// Map of registered factories
  final Map<Type, dynamic Function()> _factories = {};

  /// Map of registered lazy singletons (not yet created)
  final Map<Type, dynamic Function()> _lazySingletons = {};

  /// Map of registered instances with custom keys
  final Map<String, dynamic> _namedInstances = {};

  /// Set of types currently being resolved (to detect circular dependencies)
  final Set<Type> _resolving = {};

  /// Whether the service locator has been initialized
  bool _initialized = false;

  /// Check if the service locator has been initialized
  bool get initialized => _initialized;

  /// Get the number of registered services
  int get serviceCount =>
      _singletons.length +
      _factories.length +
      _lazySingletons.length +
      _namedInstances.length;

  /// Initialize the service locator (call this in main())
  void initialize() {
    if (_initialized) {
      debugPrint('ServiceLocator: Already initialized');
      return;
    }

    _initialized = true;
    debugPrint('ServiceLocator: Initialized with $serviceCount services');
  }

  /// Register a singleton instance
  void registerSingleton<T>(T instance) {
    _checkInitialized();

    final type = T;
    if (_isRegistered(type)) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Service of type $type is already registered',
      );
    }

    _singletons[type] = instance;
    debugPrint('ServiceLocator: Registered singleton $type');
  }

  /// Register a factory function
  void registerFactory<T>(T Function() factory) {
    _checkInitialized();

    final type = T;
    if (_isRegistered(type)) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Service of type $type is already registered',
      );
    }

    _factories[type] = factory;
    debugPrint('ServiceLocator: Registered factory $type');
  }

  /// Register a lazy singleton (created on first access)
  void registerLazySingleton<T>(T Function() factory) {
    _checkInitialized();

    final type = T;
    if (_isRegistered(type)) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Service of type $type is already registered',
      );
    }

    _lazySingletons[type] = factory;
    debugPrint('ServiceLocator: Registered lazy singleton $type');
  }

  /// Register an instance with a custom name
  void registerNamed<T>(String name, T instance) {
    _checkInitialized();

    if (_namedInstances.containsKey(name)) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Named service "$name" is already registered',
      );
    }

    _namedInstances[name] = instance;
    debugPrint('ServiceLocator: Registered named instance "$name" of type $T');
  }

  /// Get a service by type
  T get<T>() {
    _checkInitialized();

    final type = T;

    // Check for circular dependency
    if (_resolving.contains(type)) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Circular dependency detected for type $type',
      );
    }

    try {
      _resolving.add(type);

      // Check singletons first
      if (_singletons.containsKey(type)) {
        return _singletons[type] as T;
      }

      // Check lazy singletons
      if (_lazySingletons.containsKey(type)) {
        final factory = _lazySingletons[type]!;
        final instance = factory() as T;

        // Move from lazy to singleton
        _lazySingletons.remove(type);
        _singletons[type] = instance;

        debugPrint('ServiceLocator: Created lazy singleton $type');
        return instance;
      }

      // Check factories
      if (_factories.containsKey(type)) {
        final factory = _factories[type]! as T Function();
        final instance = factory();
        debugPrint('ServiceLocator: Created instance from factory $type');
        return instance;
      }

      throw AppError(
        type: ErrorType.notFound,
        message: 'Service of type $type is not registered',
      );
    } finally {
      _resolving.remove(type);
    }
  }

  /// Get a named service
  T getNamed<T>(String name) {
    _checkInitialized();

    if (!_namedInstances.containsKey(name)) {
      throw AppError(
        type: ErrorType.notFound,
        message: 'Named service "$name" is not registered',
      );
    }

    final instance = _namedInstances[name];
    if (instance is! T) {
      throw AppError(
        type: ErrorType.validation,
        message: 'Named service "$name" is not of type $T',
      );
    }

    return instance;
  }

  /// Check if a service is registered
  bool isRegistered<T>() {
    return _isRegistered(T);
  }

  /// Check if a named service is registered
  bool isNamedRegistered(String name) {
    return _namedInstances.containsKey(name);
  }

  /// Unregister a service by type
  void unregister<T>() {
    final type = T;
    _singletons.remove(type);
    _factories.remove(type);
    _lazySingletons.remove(type);
    debugPrint('ServiceLocator: Unregistered $type');
  }

  /// Unregister a named service
  void unregisterNamed(String name) {
    _namedInstances.remove(name);
    debugPrint('ServiceLocator: Unregistered named service "$name"');
  }

  /// Reset the service locator (useful for testing)
  void reset() {
    _singletons.clear();
    _factories.clear();
    _lazySingletons.clear();
    _namedInstances.clear();
    _resolving.clear();
    _initialized = false;
    debugPrint('ServiceLocator: Reset complete');
  }

  /// Get all registered service types
  List<Type> getRegisteredTypes() {
    return [..._singletons.keys, ..._factories.keys, ..._lazySingletons.keys];
  }

  /// Get all named service keys
  List<String> getNamedServiceKeys() {
    return _namedInstances.keys.toList();
  }

  /// Try to get a service, returns null if not found
  T? tryGet<T>() {
    try {
      return get<T>();
    } catch (e) {
      debugPrint('ServiceLocator: Failed to get service $T: $e');
      return null;
    }
  }

  /// Try to get a named service, returns null if not found
  T? tryGetNamed<T>(String name) {
    try {
      return getNamed<T>(name);
    } catch (e) {
      debugPrint('ServiceLocator: Failed to get named service "$name": $e');
      return null;
    }
  }

  /// Replace an existing singleton (useful for testing)
  void replaceSingleton<T>(T instance) {
    final type = T;
    if (!_singletons.containsKey(type)) {
      throw AppError(
        type: ErrorType.notFound,
        message: 'Cannot replace: singleton of type $type is not registered',
      );
    }

    _singletons[type] = instance;
    debugPrint('ServiceLocator: Replaced singleton $type');
  }

  /// Check if a type is registered in any category
  bool _isRegistered(Type type) {
    return _singletons.containsKey(type) ||
        _factories.containsKey(type) ||
        _lazySingletons.containsKey(type);
  }

  /// Check if the service locator has been initialized
  void _checkInitialized() {
    if (!_initialized) {
      throw AppError(
        type: ErrorType.validation,
        message:
            'ServiceLocator must be initialized before use. Call ServiceLocator().initialize() in main().',
      );
    }
  }

  /// Get debug information about the service locator
  Map<String, dynamic> getDebugInfo() {
    return {
      'initialized': _initialized,
      'singletons': _singletons.keys.map((k) => k.toString()).toList(),
      'factories': _factories.keys.map((k) => k.toString()).toList(),
      'lazySingletons': _lazySingletons.keys.map((k) => k.toString()).toList(),
      'namedInstances': _namedInstances.keys.toList(),
      'totalServices': serviceCount,
      'currentlyResolving': _resolving.map((k) => k.toString()).toList(),
    };
  }
}

/// Extension methods for easier registration
extension ServiceLocatorExtensions on ServiceLocator {
  /// Register multiple singletons at once
  void registerSingletons(Map<Type, dynamic> singletons) {
    for (final entry in singletons.entries) {
      _singletons[entry.key] = entry.value;
    }
  }

  /// Register multiple factories at once
  void registerFactories(Map<Type, dynamic Function()> factories) {
    for (final entry in factories.entries) {
      _factories[entry.key] = entry.value;
    }
  }

  /// Register multiple lazy singletons at once
  void registerLazySingletons(Map<Type, dynamic Function()> lazySingletons) {
    for (final entry in lazySingletons.entries) {
      _lazySingletons[entry.key] = entry.value;
    }
  }
}

/// Convenience function to get the service locator instance
ServiceLocator locator() => ServiceLocator();

/// Convenience function to get a service
T getService<T>() => ServiceLocator().get<T>();

/// Convenience function to try to get a service
T? tryGetService<T>() => ServiceLocator().tryGet<T>();
