import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/filter_model.dart';
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
  final FilterModel _filter = FilterModel();
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
  FilterModel get filter => _filter;
  bool get isLoading => _isLoading;

  Future<void> getProperties() async {
    await execute(() async {
      _properties = await _homeService.getProperties(_filter);
    });
  }

  // Update filter and get properties
  Future<void> filterProperties(FilterModel filter) async {
    _filter.city = filter.city;
    _filter.maxPrice = filter.maxPrice;
    _filter.minPrice = filter.minPrice;
    _filter.sortBy = filter.sortBy;
    _filter.sortDescending = filter.sortDescending;

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
