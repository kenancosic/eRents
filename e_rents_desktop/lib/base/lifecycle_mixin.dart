import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Mixin that provides lifecycle-aware async operation management
///
/// This mixin helps prevent setState() calls after dispose() by:
/// - Tracking disposal state
/// - Cancelling pending operations on dispose
/// - Providing safe setState and notifyListeners methods
/// - Automatically deferring notifications during build phase
mixin LifecycleMixin on ChangeNotifier {
  /// Whether this provider has been disposed
  bool _disposed = false;

  /// List of pending async operations
  final List<Completer<void>> _pendingOperations = [];

  /// Check if this provider has been disposed
  bool get disposed => _disposed;

  /// Execute an async operation with proper lifecycle management
  Future<T> executeAsync<T>(Future<T> Function() operation) async {
    if (_disposed) {
      throw StateError('Cannot execute operation: provider has been disposed');
    }

    final completer = Completer<void>();
    _pendingOperations.add(completer);

    try {
      final result = await operation();
      return result;
    } finally {
      _pendingOperations.remove(completer);
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  /// Safe setState that checks if the provider is still active
  void safeSetState(VoidCallback fn) {
    if (!_disposed) {
      fn();
    }
  }

  /// Safe notifyListeners that checks if the provider is still active
  /// and automatically defers notifications if called during build
  void safeNotifyListeners() {
    if (_disposed) return;

    // Check if we're currently in a build phase
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      // Defer the notification to avoid build-time setState
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) {
          notifyListeners();
        }
      });
    } else {
      // Safe to notify immediately
      notifyListeners();
    }
  }

  /// Cancel all pending operations
  void cancelPendingOperations() {
    for (final completer in _pendingOperations) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
    _pendingOperations.clear();
  }

  /// Mark as disposed and cancel operations
  void markDisposed() {
    _disposed = true;
    cancelPendingOperations();
  }

  @override
  void dispose() {
    markDisposed();
    super.dispose();
  }
}
