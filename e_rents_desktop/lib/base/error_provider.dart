import 'package:flutter/material.dart';

/// Temporary error provider for backward compatibility
/// This will be replaced in Phase 2 with the new error handling system
class ErrorProvider extends ChangeNotifier {
  String? _errorMessage;

  String? get errorMessage => _errorMessage;

  void setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
