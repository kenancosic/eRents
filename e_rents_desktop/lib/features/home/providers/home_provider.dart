import 'dart:convert';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/models/statistics/dashboard_statistics.dart';
import 'package:e_rents_desktop/utils/logger.dart';

class HomeProvider extends ChangeNotifier {
  final ApiService _api;

  HomeProvider(this._api);

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  DashboardStatistics? _stats;
  DashboardStatistics? get stats => _stats;

  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> fetchDashboardStatistics({bool forceRefresh = false}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _api.get('Dashboard/GetDashboardStatistics', authenticated: true);
      final data = jsonDecode(response.body);
      _stats = DashboardStatistics.fromJson(data);
      log.info('Dashboard statistics loaded successfully.');
    } catch (e, stackTrace) {
      _error = 'Failed to load dashboard statistics.';
      log.severe('$_error: $e', e, stackTrace);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
