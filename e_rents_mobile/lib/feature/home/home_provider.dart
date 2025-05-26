import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
// Removed FilterModel import - using direct parameters instead
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/home_service.dart' as new_service;
import 'package:e_rents_mobile/feature/home/home_service.dart';

class HomeProvider extends BaseProvider {
  final new_service.HomeService _newHomeService;
  final HomeService _homeService;

  // Data for the home screen
  List<Booking> currentStays = [];
  List<Booking> upcomingStays = [];
  List<Property> popularProperties = [];

  List<Property> _properties = [];
  String? _error;

  // Filter parameters (replacing FilterModel)
  String? _city;
  double? _maxPrice;
  double? _minPrice;
  String? _sortBy;
  bool _sortDescending = false;

  final bool _isLoading = false;

  HomeProvider(this._newHomeService, this._homeService);

  // Initialize/load all data for the home screen
  Future<void> loadHomeData() async {
    await execute(() async {
      await Future.wait([
        _loadCurrentResidences(),
        _loadUpcomingStays(),
        _loadPopularProperties(),
        getProperties()
      ]);
    });
  }

  // Load current residences separately if needed
  Future<void> _loadCurrentResidences() async {
    try {
      currentStays = await _newHomeService.getCurrentResidences();
    } catch (e) {
      setError("Failed to load current residences: $e");
    }
  }

  // Load upcoming stays separately if needed
  Future<void> _loadUpcomingStays() async {
    try {
      upcomingStays = await _newHomeService.getUpcomingStays();
    } catch (e) {
      setError("Failed to load upcoming stays: $e");
    }
  }

  // Load popular properties separately if needed
  Future<void> _loadPopularProperties() async {
    try {
      popularProperties = await _newHomeService.getMostRentedProperties();
    } catch (e) {
      setError("Failed to load popular properties: $e");
    }
  }

  List<Property> get properties => _properties;
  String? get error => _error;
  bool get isLoading => _isLoading;

  // Getters for filter parameters
  String? get city => _city;
  double? get maxPrice => _maxPrice;
  double? get minPrice => _minPrice;
  String? get sortBy => _sortBy;
  bool get sortDescending => _sortDescending;

  Future<void> getProperties() async {
    await execute(() async {
      // Create filter map for service call
      final filterParams = {
        'city': _city,
        'maxPrice': _maxPrice,
        'minPrice': _minPrice,
        'sortBy': _sortBy,
        'sortDescending': _sortDescending,
      };
      _properties = await _homeService.getPropertiesWithFilter(filterParams);
    });
  }

  // Update filter and get properties
  Future<void> filterProperties({
    String? city,
    double? maxPrice,
    double? minPrice,
    String? sortBy,
    bool? sortDescending,
  }) async {
    _city = city;
    _maxPrice = maxPrice;
    _minPrice = minPrice;
    _sortBy = sortBy;
    _sortDescending = sortDescending ?? false;

    await getProperties();
  }

//   Future<void> fetchNearbyProperties() async {
//   final userLocation = await _getUserLocation();
//   if (userLocation != null) {
//     final response = await _homeService.get('/properties/search', {
//       'latitude': userLocation.latitude,
//       'longitude': userLocation.longitude,
//       'radius': 10,  // Example radius
//       'sortBy': 'distance',
//     });
//     // Process and display the response
//   }
// }

// Future<Position?> _getUserLocation() async {
//   return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
// }
}
