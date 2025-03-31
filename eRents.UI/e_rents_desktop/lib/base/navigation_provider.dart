import 'base_provider.dart';

class NavigationProvider extends BaseProvider {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void updateIndex(int newIndex) {
    _currentIndex = newIndex;
    notifyListeners(); // Notify listeners about the index change
  }
}
