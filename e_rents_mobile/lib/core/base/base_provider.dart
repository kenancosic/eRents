import 'package:flutter/material.dart';

enum ViewState { Idle, Busy, Error }

abstract class BaseProvider with ChangeNotifier {
  ViewState _state = ViewState.Idle;
  String? _errorMessage;

  ViewState get state => _state;
  String? get errorMessage => _errorMessage;

  void setState(ViewState viewState) {
    _state = viewState;
    notifyListeners();
  }

  void setError(String? message) {
    _errorMessage = message;
    setState(ViewState.Error);
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> execute(Function action) async {
    try {
      setState(ViewState.Busy);
      clearError();
      await action();
      setState(ViewState.Idle);
    } catch (e) {
      setError(e.toString());
    }
  }
}
