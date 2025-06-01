import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
// import 'package:e_rents_desktop/services/temp_mock_service.dart'; // Removed
// import 'package:e_rents_desktop/services/mock_data_service.dart'; // Removed
// import 'package:e_rents_desktop/services/api_service.dart'; // Keep if BaseProvider needs it, or TenantService needs it directly
import 'package:e_rents_desktop/services/tenant_service.dart';
// import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart'; // If needed for auth user ID

class TenantProvider extends BaseProvider<User> {
  final TenantService _tenantService;
  // final AuthProvider? _authProvider; // Uncomment if needed

  List<User> _currentTenants = [];
  List<TenantPreference> _searchingTenants = [];
  final Map<int, List<Review>> _tenantFeedbacks = {};
  // final Map<String, List<Message>> _tenantMessages = {}; // To be removed
  final Map<int, List<String>> _tenantPropertyOffers = {};
  final Map<int, Map<String, dynamic>> _tenantPropertyAssignments =
      {}; // Add property assignments

  // Add loading state tracking for different operations
  bool _isLoadingCurrentTenants = false;
  bool _isLoadingSearchingTenants = false;
  bool _isLoadingPropertyAssignments = false;
  bool _hasInitialLoad = false;

  // Constructor updated
  TenantProvider(this._tenantService /*, this._authProvider */) : super() {
    // isMockDataEnabled is false by default in BaseProvider unless explicitly set.
    // We will rely on TenantService to throw exceptions if backend is not ready.
  }

  // Getters
  List<User> get currentTenants =>
      _currentTenants; // Could also use items directly from BaseProvider
  List<TenantPreference> get searchingTenants => _searchingTenants;
  bool get isLoadingCurrentTenants => _isLoadingCurrentTenants;
  bool get isLoadingSearchingTenants => _isLoadingSearchingTenants;
  bool get isLoadingPropertyAssignments => _isLoadingPropertyAssignments;
  bool get hasInitialLoad => _hasInitialLoad;

  // Check if we're in the middle of initial data loading
  bool get isInitialLoading => !_hasInitialLoad && state == ViewState.Busy;

  // Check if any critical data is still loading
  bool get isAnyDataLoading =>
      _isLoadingCurrentTenants || _isLoadingSearchingTenants;

  List<Review> getTenantFeedbacks(int tenantId) {
    return _tenantFeedbacks[tenantId] ?? [];
  }

  List<String> getTenantPropertyOffers(int tenantId) {
    return _tenantPropertyOffers[tenantId] ?? [];
  }

  Map<int, Map<String, dynamic>> get tenantPropertyAssignments =>
      _tenantPropertyAssignments;

  /// Get property assignment for a specific tenant
  Map<String, dynamic>? getTenantPropertyAssignment(int tenantId) {
    return _tenantPropertyAssignments[tenantId];
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
  String get endpoint => '/users?role=TENANT'; // Example, might not be used directly by all methods.

  @override
  List<User> getMockItems() {
    print(
      'TenantProvider: getMockItems() called. Backend integration is primary. Returning empty list as placeholder.',
    );
    // This method is part of BaseProvider, should ideally not be used if not enabling mock data.
    return [];
  }

  Future<void> loadCurrentTenants({Map<String, String>? queryParams}) async {
    _isLoadingCurrentTenants = true;
    notifyListeners();

    await execute(() async {
      _currentTenants = await _tenantService.getCurrentTenants(
        queryParams: queryParams,
      );
      items_ = _currentTenants;
    });

    _isLoadingCurrentTenants = false;
    notifyListeners();
  }

  Future<void> loadSearchingTenants({Map<String, String>? queryParams}) async {
    _isLoadingSearchingTenants = true;
    notifyListeners();

    await execute(() async {
      _searchingTenants = await _tenantService.getProspectiveTenants(
        queryParams: queryParams,
      );
    });

    _isLoadingSearchingTenants = false;
    notifyListeners();
  }

  Future<void> loadTenantFeedbacks(int tenantId) async {
    await execute(() async {
      _tenantFeedbacks[tenantId] = await _tenantService.getTenantFeedbacks(
        tenantId,
      );
    });
  }

  Future<void> addTenantFeedback(int tenantId, Review feedback) async {
    await execute(() async {
      Review newFeedback = await _tenantService.addTenantFeedback(
        tenantId,
        feedback,
      );
      if (!_tenantFeedbacks.containsKey(tenantId)) {
        _tenantFeedbacks[tenantId] = [];
      }
      _tenantFeedbacks[tenantId]!.add(newFeedback);
    });
  }

  Future<void> loadTenantPropertyAssignments(List<int> tenantIds) async {
    if (tenantIds.isEmpty) return;

    _isLoadingPropertyAssignments = true;
    notifyListeners();

    try {
      final assignments = await _tenantService.getTenantPropertyAssignments(
        tenantIds,
      );

      // Clear existing assignments
      _tenantPropertyAssignments.clear();

      // Handle empty or null response
      if (assignments.isEmpty) {
        print('TenantProvider: No property assignments returned from backend');
        return;
      }

      // Convert string keys to int and store assignments
      for (final entry in assignments.entries) {
        final tenantId = int.tryParse(entry.key);
        if (tenantId != null && entry.value != null) {
          _tenantPropertyAssignments[tenantId] = entry.value;
        }
      }

      print(
        'TenantProvider: Loaded ${_tenantPropertyAssignments.length} tenant property assignments',
      );
    } catch (e) {
      print('TenantProvider: Error loading tenant property assignments: $e');
      // Don't rethrow - allow the rest of the app to continue working
      // Just log the error and continue without property assignments
    } finally {
      _isLoadingPropertyAssignments = false;
      notifyListeners();
    }
  }

  /// Load all tenant data with proper state management
  Future<void> loadAllData() async {
    // Use execute() for proper state management instead of manual setState
    await execute(() async {
      // Load tenants first in parallel
      await Future.wait([loadCurrentTenants(), loadSearchingTenants()]);

      // Then load property assignments for current tenants
      if (_currentTenants.isNotEmpty) {
        final tenantIds = _currentTenants.map((t) => t.id).toList();
        await loadTenantPropertyAssignments(tenantIds);
      }

      // Mark that we've completed initial load
      _hasInitialLoad = true;
    });
  }

  /// Refresh all data (for pull-to-refresh or retry scenarios)
  Future<void> refreshAllData() async {
    // Clear the initial load flag to show loading during refresh
    _hasInitialLoad = false;

    // Clear existing data to ensure clean state
    _currentTenants.clear();
    _searchingTenants.clear();
    _tenantPropertyAssignments.clear();
    items_.clear();

    await loadAllData();
  }

  /// Load current tenants only (for tab-specific loading)
  Future<void> refreshCurrentTenants() async {
    await loadCurrentTenants();

    // Reload property assignments for current tenants
    if (_currentTenants.isNotEmpty) {
      final tenantIds = _currentTenants.map((t) => t.id).toList();
      await loadTenantPropertyAssignments(tenantIds);
    }
  }

  /// Load searching tenants only (for tab-specific loading)
  Future<void> refreshSearchingTenants() async {
    await loadSearchingTenants();
  }

  Future<void> recordPropertyOffer(int tenantId, int propertyId) async {
    await execute(() async {
      await _tenantService.recordPropertyOfferedToTenant(tenantId, propertyId);
      print(
        'TenantProvider: Property offer recorded via service for tenant $tenantId, property $propertyId.',
      );
    });
  }

  // sendMessageToTenant method is removed.

  /// Submit review for tenant - API ready structure
  Future<void> submitReview({
    required int tenantId, // Assuming tenantId is int as per Review model
    required double rating,
    required String description,
  }) async {
    print(
      'TenantProvider: Attempting to submit review for tenant $tenantId...',
    );
    await execute(() async {
      final review = Review(
        id: 0, // Backend will assign/overwrite ID for new reviews
        reviewType: ReviewType.tenantReview,
        revieweeId: tenantId,
        starRating: rating,
        description: description,
        dateCreated: DateTime.now(),
        // reviewerId will be set by backend from authenticated user context
      );
      // Assuming TenantService will have an addReviewForTenant or similar method.
      // For now, this structure is ready for service integration.
      // Example: await _tenantService.addReviewForTenant(review);
      print(
        'TenantProvider: Review submission structure prepared for tenant $tenantId. Backend call via ReviewService or extended TenantService to POST /reviews pending.',
      );
      // TODO: Implement and call appropriate service (e.g., ReviewService or TenantService) to send the review to POST /reviews.
    });
  }

  /// Get maintenance issues for current tenants
  Future<List<MaintenanceIssue>> getMaintenanceIssues() async {
    print(
      'TenantProvider: getMaintenanceIssues called. This feature requires backend integration via MaintenanceService.',
    );
    // TODO: Replace with actual API call via a MaintenanceService.
    throw UnimplementedError(
      'Fetching maintenance issues for tenants via MaintenanceService is not yet implemented.',
    );
  }

  /// Create maintenance issue
  Future<void> createMaintenanceIssue({
    required int propertyId, // Assuming IDs are int
    required String title,
    required String description,
    required String priority, // Consider using an Enum if not already
    required String category,
    required bool isTenantComplaint,
    required bool requiresInspection,
    required int
    reportedBy, // Assuming IDs are int. Backend should verify this user against tenant context.
  }) async {
    print(
      'TenantProvider: createMaintenanceIssue called for property $propertyId. This feature requires backend integration via MaintenanceService.',
    );
    // TODO: Replace with API call to create maintenance issue, likely via MaintenanceService POST /maintenance.
    // Example:
    // final issue = MaintenanceIssue(...);
    // await _maintenanceService.createIssue(issue);
    throw UnimplementedError(
      'Creating maintenance issue via MaintenanceService is not yet implemented.',
    );
  }
}
