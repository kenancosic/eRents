import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/review.dart';
// import 'package:e_rents_desktop/models/message.dart'; // No longer needed for sending messages
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:e_rents_desktop/services/tenant_service.dart';
// import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart'; // If needed for auth user ID

class TenantProvider extends BaseProvider<User> {
  final TenantService _tenantService;
  // final AuthProvider? _authProvider; // Uncomment if needed

  List<User> _currentTenants = [];
  List<TenantPreference> _searchingTenants = [];
  final Map<String, List<Review>> _tenantFeedbacks = {};
  // final Map<String, List<Message>> _tenantMessages = {}; // To be removed
  final Map<String, List<String>> _tenantPropertyOffers =
      {}; // For local mock or could be service driven

  // Constructor updated
  TenantProvider(this._tenantService /*, this._authProvider */)
    : super(_tenantService) {
    // enableMockData(); // Controlled by BaseProvider or specific methods now
  }

  // Getters
  List<User> get currentTenants =>
      _currentTenants; // Could also use items directly from BaseProvider
  List<TenantPreference> get searchingTenants => _searchingTenants;

  List<Review> getTenantFeedbacks(String tenantId) {
    return _tenantFeedbacks[tenantId] ?? [];
  }

  List<String> getTenantPropertyOffers(String tenantId) {
    return _tenantPropertyOffers[tenantId] ?? [];
  }

  @override
  User fromJson(Map<String, dynamic> json) {
    return User.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(User item) {
    return item.toJson();
  }

  @override
  String get endpoint => '/users'; // General endpoint for users, filtering applied in service

  @override
  List<User> getMockItems() {
    // Returns mock users with the role of Tenant
    return MockDataService.getMockUsers()
        .where((user) => user.role == UserType.tenant)
        .toList();
  }

  Future<void> loadCurrentTenants({Map<String, String>? queryParams}) async {
    await execute(() async {
      if (isMockDataEnabled) {
        _currentTenants = getMockItems();
      } else {
        _currentTenants = await _tenantService.getCurrentTenants(
          queryParams: queryParams,
        );
      }
      items_ = _currentTenants; // Update BaseProvider's items list
    });
  }

  Future<void> loadSearchingTenants({Map<String, String>? queryParams}) async {
    await execute(() async {
      if (isMockDataEnabled) {
        _searchingTenants = MockDataService.getMockTenantPreferences();
      } else {
        _searchingTenants = await _tenantService.getProspectiveTenants(
          queryParams: queryParams,
        );
      }
    });
  }

  Future<void> loadTenantFeedbacks(String tenantId) async {
    await execute(() async {
      if (isMockDataEnabled) {
        // For now, return empty list since TenantFeedback is deprecated
        // TODO: Replace with actual Review data when available
        _tenantFeedbacks[tenantId] = [];
      } else {
        _tenantFeedbacks[tenantId] = await _tenantService.getTenantFeedbacks(
          tenantId,
        );
      }
    });
  }

  Future<void> addTenantFeedback(String tenantId, Review feedback) async {
    await execute(() async {
      Review newFeedback;
      if (isMockDataEnabled) {
        // Create a new Review with updated ID
        newFeedback = Review(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          bookingId: feedback.bookingId,
          propertyId: feedback.propertyId,
          starRating: feedback.starRating,
          description: feedback.description,
          dateReported: feedback.dateReported,
          status: feedback.status,
          severity: feedback.severity,
        );
        if (!_tenantFeedbacks.containsKey(tenantId)) {
          _tenantFeedbacks[tenantId] = [];
        }
        _tenantFeedbacks[tenantId]!.add(newFeedback);
      } else {
        newFeedback = await _tenantService.addTenantFeedback(
          tenantId,
          feedback,
        );
        if (!_tenantFeedbacks.containsKey(tenantId)) {
          _tenantFeedbacks[tenantId] = [];
        }
        _tenantFeedbacks[tenantId]!.add(newFeedback);
      }
    });
  }

  Future<void> loadAllData() async {
    // Consolidate initial loading if needed, using BaseProvider state management
    setState(ViewState.Busy);
    try {
      await Future.wait([loadCurrentTenants(), loadSearchingTenants()]);
      setState(ViewState.Idle);
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<void> recordPropertyOffer(String tenantId, String propertyId) async {
    await execute(() async {
      if (isMockDataEnabled) {
        if (!_tenantPropertyOffers.containsKey(tenantId)) {
          _tenantPropertyOffers[tenantId] = [];
        }
        if (!_tenantPropertyOffers[tenantId]!.contains(propertyId)) {
          _tenantPropertyOffers[tenantId]!.add(propertyId);
        }
      } else {
        await _tenantService.recordPropertyOfferedToTenant(
          tenantId,
          propertyId,
        );
        // Optionally, update local cache or re-fetch if needed to reflect the change immediately.
        // For now, assuming the backend handles the state and UI will refresh on next load.
      }
    });
  }

  // sendMessageToTenant method is removed.
}
