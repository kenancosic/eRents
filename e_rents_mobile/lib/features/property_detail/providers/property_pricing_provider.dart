import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/pricing_estimate.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

/// Provider for managing property pricing
/// Handles pricing information and estimates for properties
class PropertyPricingProvider extends BaseProvider {
  PropertyPricingProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  PricingEstimate? _pricingEstimate;
  bool _isCalculatingPrice = false;

  // ─── Getters ────────────────────────────────────────────────────────────
  PricingEstimate? get pricingEstimate => _pricingEstimate;
  bool get isCalculatingPrice => _isCalculatingPrice;
  double get totalPrice => _pricingEstimate?.totalPrice ?? 0.0;
  double get basePrice => _pricingEstimate?.basePrice ?? 0.0;
  double get cleaningFee => _pricingEstimate?.cleaningFee ?? 0.0;
  double get serviceFee => _pricingEstimate?.serviceFee ?? 0.0;
  double get taxes => _pricingEstimate?.taxes ?? 0.0;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Calculate pricing estimate for a property and date range
  Future<bool> calculatePricingEstimate(int propertyId, DateTime startDate, DateTime endDate, int guests) async {
    if (_isCalculatingPrice) return false;
    _isCalculatingPrice = true;
    notifyListeners();

    final success = await executeWithStateForSuccess(() async {
      final estimate = await api.postAndDecode('/properties/$propertyId/price-estimate', {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        'guests': guests,
      }, PricingEstimate.fromJson, authenticated: true);
      
      _pricingEstimate = estimate;
    }, errorMessage: 'Failed to calculate pricing estimate');

    _isCalculatingPrice = false;
    notifyListeners();
    return success;
  }

  /// Clear pricing estimate
  void clearPricingEstimate() {
    _pricingEstimate = null;
    notifyListeners();
  }
}
