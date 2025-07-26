import 'package:flutter/material.dart';

/// Navigation provider for managing bottom navigation state
/// This provider doesn't need API access, so it extends ChangeNotifier directly
class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void updateIndex(int newIndex) {
    _currentIndex = newIndex;
    notifyListeners(); // Notify listeners about the index change
  }
}
