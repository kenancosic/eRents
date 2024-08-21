import 'base_provider.dart';
import '../services/api_service.dart';
import '../models/property.dart';

class PropertyProvider extends BaseProvider {
  final ApiService _apiService;
  final List<Property> _properties = [];

  List<Property> get properties => _properties;

  PropertyProvider({required ApiService apiService}) : _apiService = apiService;

  Future<void> fetchProperties({int page = 1}) async {
    setState(ViewState.Busy);
    try {
      _properties.addAll(await _apiService.getProperties(page: page));
      setState(ViewState.Idle);
    } catch (e) {
      setError('Failed to load properties. Please try again.');
    }
  }
}
