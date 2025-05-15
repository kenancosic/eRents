import 'package:flutter/material.dart';

enum ViewState { idle, busy, error }

abstract class BaseProvider with ChangeNotifier {
  ViewState _state = ViewState.idle;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  void setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    setState(ViewState.error);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> execute(Function action) async {
    try {
      setState(ViewState.busy);
      clearError();
      await action();
      setState(ViewState.idle);
    } catch (e) {
      setError(e.toString());
    }
  }
}
