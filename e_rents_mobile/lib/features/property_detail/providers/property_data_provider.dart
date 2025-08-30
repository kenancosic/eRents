import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

/// Provider for managing property data
/// Handles loading property details and related data
class PropertyDataProvider extends BaseProvider {
  PropertyDataProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  Property? _property;

  // ─── Getters ────────────────────────────────────────────────────────────
  Property? get property => _property;
  bool get isAvailable => _property?.status == PropertyStatus.available;
  String get title => _property?.name ?? 'Unknown Property';
  double get price => _property?.price ?? 0.0;
  String get fullAddress => _property?.address?.getFullAddress() ?? 'No address';

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Fetch property details
  Future<void> fetchPropertyDetails(String propertyId, {String? bookingId, bool forceRefresh = false}) async {
    final property = await executeWithState(() async {
      return await api.getAndDecode('/properties/$propertyId', Property.fromJson, authenticated: true);
    });

    if (property != null) {
      _property = property;
    }
  }
}
