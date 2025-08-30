import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/availability.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

/// Provider for managing property availability
/// Handles availability data for properties in property detail feature
class PropertyDetailAvailabilityProvider extends BaseProvider {
  PropertyDetailAvailabilityProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<Availability> _availabilityData = [];
  bool _isCheckingAvailability = false;
  bool _isDateRangeAvailable = true;
  String? _availabilityError;

  // ─── Getters ────────────────────────────────────────────────────────────
  List<Availability> get availabilityData => _availabilityData;
  bool get isCheckingAvailability => _isCheckingAvailability;
  bool get isDateRangeAvailable => _isDateRangeAvailable;
  String? get availabilityError => _availabilityError;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Fetch availability data for a property
  Future<void> fetchAvailabilityData(int propertyId, DateTime startDate, DateTime endDate) async {
    final availability = await executeWithState(() async {
      final queryString = api.buildQueryString({
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      return await api.getListAndDecode('/properties/$propertyId/availability$queryString', Availability.fromJson,
        authenticated: true);
    });

    if (availability != null) {
      _availabilityData = availability;
    }
  }

  /// Check if a date range is available for booking
  Future<bool> checkDateRangeAvailability(int propertyId, DateTime startDate, DateTime endDate) async {
    if (_isCheckingAvailability) return _isDateRangeAvailable;
    _isCheckingAvailability = true;
    notifyListeners();

    final success = await executeWithStateForSuccess(() async {
      final queryString = api.buildQueryString({
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      final response = await api.get('/properties/$propertyId/check-availability$queryString', authenticated: true);
      
      final isAvailable = response.toString().toLowerCase() == 'true';
      _isDateRangeAvailable = isAvailable;
      if (!isAvailable) {
        _availabilityError = 'Selected dates are not available for booking';
      } else {
        _availabilityError = null;
      }
    }, errorMessage: 'Failed to check availability');

    _isCheckingAvailability = false;
    notifyListeners();
    return success && _isDateRangeAvailable;
  }
}
