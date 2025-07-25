import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/base/api_service_extensions.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';

class HomeProvider extends BaseProvider {
  HomeProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  DashboardStatistics? _stats;
  DashboardStatistics? get stats => _stats;

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> fetchDashboardStatistics({bool forceRefresh = false}) async {
    const cacheKey = 'dashboard_stats';
    
    if (forceRefresh) {
      invalidateCache(cacheKey);
    }
    
    final result = await executeWithCache<DashboardStatistics>(
      cacheKey,
      () => api.getAndDecode(
        '/Dashboard/GetDashboardStatistics',
        DashboardStatistics.fromJson,
        authenticated: true,
      ),
    );
    
    if (result != null) {
      _stats = result;
      notifyListeners();
    }
  }
}
