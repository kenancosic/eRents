import 'package:flutter/material.dart';
import 'lifecycle_mixin.dart';

/// Temporary error provider for backward compatibility
/// This will be replaced in Phase 2 with the new error handling system
class ErrorProvider extends ChangeNotifier with LifecycleMixin {
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  void setError(String message) {
    if (disposed) return;

    _errorMessage = message;
    safeNotifyListeners();
  }

  void clearError() {
    if (disposed) return;

    _errorMessage = null;
    safeNotifyListeners();
  }
}
