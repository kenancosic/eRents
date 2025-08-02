import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';

class HomeProvider extends BaseProvider {
  HomeProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  int _totalProperties = 0;
  int get totalProperties => _totalProperties;
  
  double _occupancyRate = 0.0;
  double get occupancyRate => _occupancyRate;

  double _monthlyRevenue = 0.0;
  double get monthlyRevenue => _monthlyRevenue;

  // For simplified dashboard, we might hardcode or fetch simple counts directly
  // from very basic API endpoints or just simulate data.
  // Example for simplified backend:
  int _totalPropertiesCount = 15; // Example dummy data
  int _occupiedPropertiesCount = 10; // Example dummy data
  double _averageRating = 4.2; // Example dummy data

  // Provide direct getters for these to avoid recreating complex objects
  int get occupiedProperties => _occupiedPropertiesCount;
  double get averageRating => _averageRating;


  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> fetchDashboardStatistics({bool forceRefresh = false}) async {
    // For academic submission simplification, we are not fetching complex dashboard stats.
    // Instead, we populate with dummy data or direct simple API calls.
    // In a real app, this would involve calling a simplified backend endpoint.
    await executeWithState(() async {
      // Simulate API call for total properties (e.g., from /api/Properties/count)
      _totalProperties = 15; 
      _occupancyRate = 0.75; // 75%
      _monthlyRevenue = 15000.00; // Example revenue

      // For portfolio overview card
      _totalPropertiesCount = 15;
      _occupiedPropertiesCount = 10;
      _averageRating = 4.2;

      // Old invalidateAllCaches() call removed as it's not part of BaseProvider
      // Cache invalidation can be done for specific keys if needed.
      notifyListeners();
    });
  }
}
