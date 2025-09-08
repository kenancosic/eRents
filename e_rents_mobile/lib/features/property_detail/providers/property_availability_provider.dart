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
    final result = await executeWithState(() async {
      final queryString = api.buildQueryString({
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      });
      // Backend returns AvailabilityRangeResponse { availability: [] }
      final json = await api.getJson('/properties/$propertyId/availability$queryString', authenticated: true);
      final list = (json['availability'] as List? ?? const [])
          .cast<Map<String, dynamic>>();
      // Map backend entries (Date, IsAvailable, Price, Status) to our Availability model
      return list.map((e) {
        final dateStr = e['date']?.toString();
        final date = dateStr != null ? DateTime.parse(dateStr).toUtc() : startDate.toUtc();
        final isAvailable = (e['isAvailable'] as bool?) ?? false;
        final status = e['status'] as String?;
        return Availability(
          availabilityId: null,
          propertyId: propertyId,
          startDate: date,
          endDate: date,
          isAvailable: isAvailable,
          reason: status,
        );
      }).toList();
    });

    if (result != null) {
      _availabilityData = result;
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
      final body = response.body.trim();
      bool isAvailable;
      // Try JSON bool first, then plain text fallback
      if (body == 'true' || body == 'false') {
        isAvailable = body == 'true';
      } else {
        try {
          final decoded = body.toLowerCase() == '"true"' || body.toLowerCase() == '"false"'
              ? body.substring(1, body.length - 1)
              : body;
          isAvailable = decoded.toLowerCase() == 'true';
        } catch (_) {
          isAvailable = false;
        }
      }
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
