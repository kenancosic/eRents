import 'package:e_rents_desktop/base/base_provider.dart';
import 'dart:convert';
import 'package:e_rents_desktop/models/maintenance_issue.dart';

class HomeProvider extends BaseProvider {
  HomeProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  int _activeBookingsToday = 0;
  int get activeBookingsToday => _activeBookingsToday;

  int _upcomingCheckins7d = 0;
  int get upcomingCheckins7d => _upcomingCheckins7d;

  double _monthlyRevenue = 0.0;
  double get monthlyRevenue => _monthlyRevenue;

  int _emergencyMaintenanceIssues = 0;
  int get emergencyMaintenanceIssues => _emergencyMaintenanceIssues;

  List<MaintenanceIssue> _emergencyIssues = const [];
  List<MaintenanceIssue> get emergencyIssues => _emergencyIssues;


  // ─── Public API ─────────────────────────────────────────────────────────

  Future<void> fetchDashboardStatistics({bool forceRefresh = false}) async {
    await executeWithState(() async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final sevenDays = today.add(const Duration(days: 7));
      final monthStart = DateTime(now.year, now.month, 1);
      final monthEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));

      String fmt(DateTime d) => d.toIso8601String().split('T').first;

      // 1) Active bookings today: StartDate <= today AND EndDate >= today
      try {
        final res = await api.get(
          'api/Bookings?Page=1&PageSize=1&StartDateTo=${fmt(today)}&EndDateFrom=${fmt(today)}',
          authenticated: true,
        );
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _activeBookingsToday = (data['totalCount'] as int?) ?? 0;
      } catch (_) {
        _activeBookingsToday = 0;
      }

      // 2) Upcoming check-ins next 7 days: StartDate in [today, today+7], Status=Upcoming
      try {
        final res = await api.get(
          'api/Bookings?Page=1&PageSize=1&StartDateFrom=${fmt(today)}&StartDateTo=${fmt(sevenDays)}&Status=Upcoming',
          authenticated: true,
        );
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        _upcomingCheckins7d = (data['totalCount'] as int?) ?? 0;
      } catch (_) {
        _upcomingCheckins7d = 0;
      }

      // 3) Monthly revenue: sum payment amounts for current month (Completed)
      try {
        final res = await api.get(
          'api/Payments?Page=1&PageSize=1000&CreatedFrom=${fmt(monthStart)}&CreatedTo=${fmt(monthEnd)}&PaymentStatus=Completed',
          authenticated: true,
        );
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>? ?? const []);
        double sum = 0.0;
        for (final it in items) {
          final m = it as Map<String, dynamic>;
          final amt = (m['amount'] as num?)?.toDouble() ??
              (m['Amount'] as num?)?.toDouble() ?? 0.0;
          sum += amt;
        }
        _monthlyRevenue = sum;
      } catch (_) {
        _monthlyRevenue = 0.0;
      }

      // 4) Emergency maintenance issues count and list (Priority == Emergency)
      try {
        final res = await api.get(
          'api/MaintenanceIssues?Page=1&PageSize=20&PriorityMin=Emergency&PriorityMax=Emergency&SortBy=CreatedAt&SortDescending=true',
          authenticated: true,
        );
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final items = (data['items'] as List<dynamic>? ?? const []);
        _emergencyIssues = items
            .map((e) => MaintenanceIssue.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
        _emergencyMaintenanceIssues = (data['totalCount'] as int?) ?? _emergencyIssues.length;
      } catch (_) {
        _emergencyIssues = const [];
        _emergencyMaintenanceIssues = 0;
      }

      notifyListeners();
    });
  }
}
