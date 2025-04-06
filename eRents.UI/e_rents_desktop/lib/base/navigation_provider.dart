import 'base_provider.dart';

class NavigationProvider extends BaseProvider<void> {
  int _currentIndex = 0;

  NavigationProvider() : super(null);

  int get currentIndex => _currentIndex;

  void updateIndex(int newIndex) {
    _currentIndex = newIndex;
    notifyListeners(); // Notify listeners about the index change
  }

  @override
  String get endpoint => '';

  @override
  void fromJson(Map<String, dynamic> json) {}

  @override
  Map<String, dynamic> toJson(void item) => {};

  @override
  List<void> getMockItems() => [];
}
