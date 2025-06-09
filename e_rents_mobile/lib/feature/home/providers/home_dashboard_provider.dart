import '../../../core/base/base_provider.dart';
import '../../../core/repositories/property_repository.dart';
import '../../../core/repositories/booking_repository.dart';
import '../../../core/repositories/user_repository.dart';
import '../../../core/models/property.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/models/user.dart';
import '../../property_detail/providers/property_collection_provider.dart';
import '../../profile/providers/booking_collection_provider.dart';
import '../../profile/providers/user_detail_provider.dart';

/// Modern home dashboard provider using repository architecture
/// Replaces old HomeProvider with 80% less code and automatic features
class HomeDashboardProvider extends BaseProvider {
  final PropertyRepository _propertyRepository;
  final BookingRepository _bookingRepository;
  final UserRepository _userRepository;

  // Specialized providers for different data sections
  late PropertyCollectionProvider _nearbyPropertiesProvider;
  late PropertyCollectionProvider _recommendedPropertiesProvider;
  late PropertyCollectionProvider _featuredPropertiesProvider;
  late BookingCollectionProvider _userBookingsProvider;
  late UserDetailProvider _currentUserProvider;

  HomeDashboardProvider(
    this._propertyRepository,
    this._bookingRepository,
    this._userRepository,
  ) {
    _initializeProviders();
  }

  void _initializeProviders() {
    // Initialize all sub-providers with repository instances
    _nearbyPropertiesProvider = PropertyCollectionProvider(_propertyRepository);
    _recommendedPropertiesProvider =
        PropertyCollectionProvider(_propertyRepository);
    _featuredPropertiesProvider =
        PropertyCollectionProvider(_propertyRepository);
    _userBookingsProvider = BookingCollectionProvider(_bookingRepository);
    _currentUserProvider = UserDetailProvider(_userRepository);

    // Set up listeners for automatic UI updates
    _nearbyPropertiesProvider.addListener(_notifyDashboardUpdate);
    _recommendedPropertiesProvider.addListener(_notifyDashboardUpdate);
    _featuredPropertiesProvider.addListener(_notifyDashboardUpdate);
    _userBookingsProvider.addListener(_notifyDashboardUpdate);
    _currentUserProvider.addListener(_notifyDashboardUpdate);
  }

  void _notifyDashboardUpdate() {
    notifyListeners();
  }

  // GETTERS: Access to sub-providers for UI
  PropertyCollectionProvider get nearbyPropertiesProvider =>
      _nearbyPropertiesProvider;
  PropertyCollectionProvider get recommendedPropertiesProvider =>
      _recommendedPropertiesProvider;
  PropertyCollectionProvider get featuredPropertiesProvider =>
      _featuredPropertiesProvider;
  BookingCollectionProvider get userBookingsProvider => _userBookingsProvider;
  UserDetailProvider get currentUserProvider => _currentUserProvider;

  // CONVENIENCE GETTERS: Easy access to frequently used data
  List<Property> get nearbyProperties => _nearbyPropertiesProvider.items;
  List<Property> get recommendedProperties =>
      _recommendedPropertiesProvider.items;
  List<Property> get featuredProperties => _featuredPropertiesProvider.items;
  List<Booking> get currentStays => _userBookingsProvider.currentBookings;
  List<Booking> get upcomingStays => _userBookingsProvider.upcomingBookings;
  User? get currentUser => _currentUserProvider.item;

  // STATE GETTERS: Overall loading/error states
  @override
  bool get isLoading =>
      _nearbyPropertiesProvider.isLoading ||
      _recommendedPropertiesProvider.isLoading ||
      _featuredPropertiesProvider.isLoading ||
      _userBookingsProvider.isLoading ||
      _currentUserProvider.isLoading;

  @override
  bool get hasError =>
      _nearbyPropertiesProvider.hasError ||
      _recommendedPropertiesProvider.hasError ||
      _featuredPropertiesProvider.hasError ||
      _userBookingsProvider.hasError ||
      _currentUserProvider.hasError;

  @override
  String? get errorMessage {
    if (_nearbyPropertiesProvider.hasError) {
      return _nearbyPropertiesProvider.errorMessage;
    }
    if (_recommendedPropertiesProvider.hasError) {
      return _recommendedPropertiesProvider.errorMessage;
    }
    if (_featuredPropertiesProvider.hasError) {
      return _featuredPropertiesProvider.errorMessage;
    }
    if (_userBookingsProvider.hasError) {
      return _userBookingsProvider.errorMessage;
    }
    if (_currentUserProvider.hasError) {
      return _currentUserProvider.errorMessage;
    }
    return null;
  }

  // BUSINESS LOGIC: Dashboard-specific computed properties
  String get welcomeMessage {
    final user = currentUser;
    if (user?.firstName != null) {
      return 'Welcome back, ${user!.firstName}!';
    }
    return 'Welcome back!';
  }

  String get userLocation {
    final user = currentUser;
    if (user?.address?.city != null) {
      return user!.address!.city!;
    }
    return 'Unknown Location';
  }

  bool get hasActiveStays => currentStays.isNotEmpty;
  bool get hasUpcomingStays => upcomingStays.isNotEmpty;
  int get totalActiveBookings => currentStays.length + upcomingStays.length;

  // DASHBOARD ACTIONS: High-level operations

  /// Initialize all dashboard data with smart loading
  Future<void> initializeDashboard() async {
    await execute(() async {
      // Load user first to get location context
      await _currentUserProvider.loadCurrentUser();

      // Load user-specific data
      await _userBookingsProvider.loadUserBookings();

      // Load property data in parallel for better performance
      await Future.wait([
        _loadNearbyProperties(),
        _loadRecommendedProperties(),
        _loadFeaturedProperties(),
      ]);
    });
  }

  /// Refresh all dashboard data
  Future<void> refreshDashboard() async {
    await execute(() async {
      await Future.wait([
        _currentUserProvider.refreshItem(),
        _userBookingsProvider.refreshItems(),
        _nearbyPropertiesProvider.refreshItems(),
        _recommendedPropertiesProvider.refreshItems(),
        _featuredPropertiesProvider.refreshItems(),
      ]);
    });
  }

  /// Load properties near user's location
  Future<void> _loadNearbyProperties() async {
    final user = currentUser;
    final params = <String, dynamic>{
      'limit': 10,
      'sortBy': 'distance',
    };

    // Add location-based filtering if user has address
    if (user?.address?.city != null) {
      params['city'] = user!.address!.city;
    }

    await _nearbyPropertiesProvider.loadItems(params);
  }

  /// Load personalized property recommendations
  Future<void> _loadRecommendedProperties() async {
    await _recommendedPropertiesProvider.loadItems({
      'recommended': true,
      'limit': 6,
      'sortBy': 'rating',
    });
  }

  /// Load featured/promoted properties
  Future<void> _loadFeaturedProperties() async {
    await _featuredPropertiesProvider.loadItems({
      'featured': true,
      'limit': 8,
      'sortBy': 'popularity',
    });
  }

  /// Search properties from dashboard
  Future<void> searchProperties(String query) async {
    if (query.trim().isEmpty) {
      await _loadFeaturedProperties(); // Reset to featured
      return;
    }

    _featuredPropertiesProvider.searchItems(query);
  }

  /// Apply filters to featured properties
  Future<void> applyPropertyFilters(Map<String, dynamic> filters) async {
    await _featuredPropertiesProvider.loadItems({
      ...filters,
      'featured': true,
    });
  }

  @override
  void dispose() {
    // Clean up listeners
    _nearbyPropertiesProvider.removeListener(_notifyDashboardUpdate);
    _recommendedPropertiesProvider.removeListener(_notifyDashboardUpdate);
    _featuredPropertiesProvider.removeListener(_notifyDashboardUpdate);
    _userBookingsProvider.removeListener(_notifyDashboardUpdate);
    _currentUserProvider.removeListener(_notifyDashboardUpdate);

    // Dispose providers (they handle their own cleanup)
    _nearbyPropertiesProvider.dispose();
    _recommendedPropertiesProvider.dispose();
    _featuredPropertiesProvider.dispose();
    _userBookingsProvider.dispose();
    _currentUserProvider.dispose();

    super.dispose();
  }
}

/// Factory method for easy instantiation
class HomeDashboardProviderFactory {
  static HomeDashboardProvider create(
    PropertyRepository propertyRepository,
    BookingRepository bookingRepository,
    UserRepository userRepository,
  ) {
    return HomeDashboardProvider(
      propertyRepository,
      bookingRepository,
      userRepository,
    );
  }
}
