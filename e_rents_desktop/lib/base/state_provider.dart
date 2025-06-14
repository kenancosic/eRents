import 'package:flutter/foundation.dart';
import 'lifecycle_mixin.dart';

/// Base provider for simple state management
///
/// This provider is useful for managing simple application state that doesn't
/// require complex operations like API calls or caching. Examples include:
/// - UI state (selected tabs, filters, etc.)
/// - User preferences
/// - Form state
/// - Navigation state
class StateProvider<T> extends ChangeNotifier with LifecycleMixin {
  /// The current state value
  T _state;

  /// Optional validator function for state changes
  final bool Function(T)? _validator;

  /// Optional transformation function for state changes
  final T Function(T)? _transformer;

  /// History of state changes (if enabled)
  final List<T> _history = [];

  /// Maximum number of history entries to keep
  final int _maxHistorySize;

  /// Whether to track state history
  final bool _trackHistory;

  StateProvider(
    this._state, {
    bool Function(T)? validator,
    T Function(T)? transformer,
    bool trackHistory = false,
    int maxHistorySize = 10,
  }) : _validator = validator,
       _transformer = transformer,
       _trackHistory = trackHistory,
       _maxHistorySize = maxHistorySize {
    if (_trackHistory) {
      _addToHistory(_state);
    }
  }

  /// Get the current state
  T get state => _state;

  /// Get the state history (if tracking is enabled)
  List<T> get history => _trackHistory ? List.unmodifiable(_history) : [];

  /// Check if history tracking is enabled
  bool get isTrackingHistory => _trackHistory;

  /// Get the number of history entries
  int get historyLength => _history.length;

  /// Check if we can undo (go back in history)
  bool get canUndo => _history.length > 1;

  /// Update the state
  void updateState(T newState) {
    if (disposed) return;

    // Validate the new state if validator is provided
    if (_validator != null && !_validator(newState)) {
      debugPrint('StateProvider: State validation failed for $newState');
      return;
    }

    // Transform the state if transformer is provided
    final transformedState =
        _transformer != null ? _transformer(newState) : newState;

    // Only update if the state actually changed
    if (_state != transformedState) {
      _state = transformedState;

      if (_trackHistory) {
        _addToHistory(_state);
      }

      safeNotifyListeners();
    }
  }

  /// Reset to initial state (first entry in history if tracking, otherwise requires initial value)
  void reset([T? initialState]) {
    if (disposed) return;

    if (_trackHistory && _history.isNotEmpty) {
      updateState(_history.first);
    } else if (initialState != null) {
      updateState(initialState);
    } else {
      debugPrint('StateProvider: Cannot reset - no initial state available');
    }
  }

  /// Undo the last state change (only works if history tracking is enabled)
  void undo() {
    if (disposed) return;

    if (!_trackHistory) {
      debugPrint('StateProvider: Cannot undo - history tracking is disabled');
      return;
    }

    if (_history.length > 1) {
      // Remove current state
      _history.removeLast();

      // Set state to previous value without adding to history
      _state = _history.last;
      safeNotifyListeners();
    }
  }

  /// Clear the state history
  void clearHistory() {
    if (disposed) return;

    if (_trackHistory) {
      _history.clear();
      _addToHistory(_state);
    }
  }

  /// Transform the current state using a function
  void transform(T Function(T) transformer) {
    if (disposed) return;

    updateState(transformer(_state));
  }

  /// Update state conditionally
  void updateIf(bool Function(T) condition, T newState) {
    if (disposed) return;

    if (condition(_state)) {
      updateState(newState);
    }
  }

  /// Add current state to history
  void _addToHistory(T state) {
    if (disposed) return;

    _history.add(state);

    // Maintain maximum history size
    while (_history.length > _maxHistorySize) {
      _history.removeAt(0);
    }
  }

  @override
  void dispose() {
    _history.clear();
    super.dispose();
  }
}

/// Specialized state provider for boolean values
class BooleanStateProvider extends StateProvider<bool> {
  BooleanStateProvider(
    super.initialState, {
    super.trackHistory = false,
    super.maxHistorySize = 10,
  });

  /// Toggle the boolean state
  void toggle() {
    updateState(!state);
  }

  /// Set to true
  void setTrue() {
    updateState(true);
  }

  /// Set to false
  void setFalse() {
    updateState(false);
  }
}

/// Specialized state provider for nullable values
class NullableStateProvider<T> extends StateProvider<T?> {
  NullableStateProvider(
    super.initialState, {
    super.trackHistory = false,
    super.maxHistorySize = 10,
  });

  /// Check if state has a value
  bool get hasValue => state != null;

  /// Check if state is null
  bool get isNull => state == null;

  /// Clear the state (set to null)
  void clear() {
    updateState(null);
  }

  /// Set a non-null value
  void setValue(T value) {
    updateState(value);
  }

  /// Update only if current state is null
  void setIfNull(T value) {
    updateIf((current) => current == null, value);
  }

  /// Update only if current state is not null
  void updateIfNotNull(T value) {
    updateIf((current) => current != null, value);
  }
}

/// Specialized state provider for list values
class ListStateProvider<T> extends StateProvider<List<T>> {
  ListStateProvider(
    List<T> initialState, {
    bool trackHistory = false,
    int maxHistorySize = 10,
  }) : super(
         List<T>.from(initialState),
         trackHistory: trackHistory,
         maxHistorySize: maxHistorySize,
       );

  /// Get the length of the list
  int get length => state.length;

  /// Check if the list is empty
  bool get isEmpty => state.isEmpty;

  /// Check if the list is not empty
  bool get isNotEmpty => state.isNotEmpty;

  /// Add an item to the list
  void add(T item) {
    final newList = List<T>.from(state);
    newList.add(item);
    updateState(newList);
  }

  /// Add multiple items to the list
  void addAll(Iterable<T> items) {
    final newList = List<T>.from(state);
    newList.addAll(items);
    updateState(newList);
  }

  /// Remove an item from the list
  void remove(T item) {
    final newList = List<T>.from(state);
    newList.remove(item);
    updateState(newList);
  }

  /// Remove all items matching a condition
  void removeWhere(bool Function(T) test) {
    final newList = List<T>.from(state);
    newList.removeWhere(test);
    updateState(newList);
  }

  /// Clear all items from the list
  void clear() {
    updateState(<T>[]);
  }

  /// Replace the entire list
  void replaceAll(List<T> newItems) {
    updateState(List<T>.from(newItems));
  }

  /// Insert an item at a specific index
  void insert(int index, T item) {
    final newList = List<T>.from(state);
    newList.insert(index, item);
    updateState(newList);
  }

  /// Remove item at a specific index
  void removeAt(int index) {
    final newList = List<T>.from(state);
    newList.removeAt(index);
    updateState(newList);
  }

  /// Update an item at a specific index
  void updateAt(int index, T item) {
    final newList = List<T>.from(state);
    newList[index] = item;
    updateState(newList);
  }

  /// Sort the list
  void sort([int Function(T, T)? compare]) {
    final newList = List<T>.from(state);
    newList.sort(compare);
    updateState(newList);
  }

  /// Filter the list
  void filter(bool Function(T) test) {
    final newList = state.where(test).toList();
    updateState(newList);
  }
}

/// Specialized state provider for map values
class MapStateProvider<K, V> extends StateProvider<Map<K, V>> {
  MapStateProvider(
    Map<K, V> initialState, {
    bool trackHistory = false,
    int maxHistorySize = 10,
  }) : super(
         Map<K, V>.from(initialState),
         trackHistory: trackHistory,
         maxHistorySize: maxHistorySize,
       );

  /// Get the number of entries in the map
  int get length => state.length;

  /// Check if the map is empty
  bool get isEmpty => state.isEmpty;

  /// Check if the map is not empty
  bool get isNotEmpty => state.isNotEmpty;

  /// Get all keys
  Iterable<K> get keys => state.keys;

  /// Get all values
  Iterable<V> get values => state.values;

  /// Set a key-value pair
  void setValue(K key, V value) {
    final newMap = Map<K, V>.from(state);
    newMap[key] = value;
    updateState(newMap);
  }

  /// Remove a key
  void removeKey(K key) {
    final newMap = Map<K, V>.from(state);
    newMap.remove(key);
    updateState(newMap);
  }

  /// Clear all entries
  void clear() {
    updateState(<K, V>{});
  }

  /// Add all entries from another map
  void addAll(Map<K, V> other) {
    final newMap = Map<K, V>.from(state);
    newMap.addAll(other);
    updateState(newMap);
  }

  /// Check if a key exists
  bool containsKey(K key) => state.containsKey(key);

  /// Check if a value exists
  bool containsValue(V value) => state.containsValue(value);

  /// Get a value by key
  V? getValue(K key) => state[key];

  /// Get a value by key with a default
  V getValueOrDefault(K key, V defaultValue) => state[key] ?? defaultValue;

  /// Update a value if the key exists
  void updateIfExists(K key, V value) {
    if (state.containsKey(key)) {
      setValue(key, value);
    }
  }

  /// Set a value only if the key doesn't exist
  void setIfAbsent(K key, V value) {
    if (!state.containsKey(key)) {
      setValue(key, value);
    }
  }
}
