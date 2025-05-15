import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/filter_model.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/feature/home/data/home_service.dart';

class HomeProvider extends BaseProvider {
  final HomeService _homeService;
  List<Property> _properties = [];
  String? _error;
  final FilterModel _filter = FilterModel();
  final bool _isLoading = false;

  HomeProvider(this._homeService);

  List<Property> get properties => _properties;
  String? get error => _error;
  bool get isLoading => _isLoading;

  void setFilter({String? city, double? minPrice, double? maxPrice}) {
    _filter.city = city;
    _filter.minPrice = minPrice;
    _filter.maxPrice = maxPrice;
    fetchProperties();
  }

  void setSort(String sortBy, bool descending) {
    _filter.sortBy = sortBy;
    _filter.sortDescending = descending;
    fetchProperties();
  }

  Future<void> fetchProperties() async {
    setState(ViewState.busy);
    try {
      final properties = await _homeService.getProperties(_filter);
      _properties = properties;
      _error = null;
    } catch (e) {
      _error = e.toString();
      _properties = [];
    } finally {
      setState(ViewState.idle);
    }
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
