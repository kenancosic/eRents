import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';

/// Provider for managing featured properties
/// Handles loading and display of featured properties
class FeaturedPropertiesProvider extends BaseProvider {
  FeaturedPropertiesProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<PropertyCardModel> _featuredProperties = [];

  // ─── Getters ────────────────────────────────────────────────────────────
  List<PropertyCardModel> get featuredProperties => _featuredProperties;
  int get featuredPropertiesCount => _featuredProperties.length;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Load featured properties
  Future<void> loadFeaturedProperties() async {
    final properties = await executeWithState(() async {
      return await api.getListAndDecode('properties/featured', PropertyCardModel.fromJson, authenticated: false);
    });
    
    if (properties != null) {
      _featuredProperties = properties;
      debugPrint('FeaturedPropertiesProvider: Loaded ${_featuredProperties.length} featured properties');
    }
  }

  /// Refresh featured properties
  Future<void> refreshFeaturedProperties() async {
    await loadFeaturedProperties();
  }

  /// Clear featured properties
  void clearFeaturedProperties() {
    _featuredProperties.clear();
    notifyListeners();
    debugPrint('FeaturedPropertiesProvider: Cleared featured properties');
  }
}
