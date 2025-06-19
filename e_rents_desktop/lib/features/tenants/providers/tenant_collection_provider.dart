import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/repositories/tenant_repository.dart';

/// Collection provider for tenant management
/// Handles both current tenants and prospective tenants (searching)
///
/// ✅ UNIVERSAL SYSTEM INTEGRATION - Updated for Universal System pagination
class TenantCollectionProvider extends CollectionProvider<User> {
  final TenantRepository _repository;

  // Separate data for prospective tenants
  final List<TenantPreference> _prospectiveTenants = [];
  final Map<int, Map<String, dynamic>> _propertyAssignments = {};

  // Loading states for different operations
  bool _isLoadingProspective = false;
  bool _isLoadingAssignments = false;

  TenantCollectionProvider(this._repository)
    : super(_repository as Repository<User>);

  // Getters for prospective tenants data
  List<TenantPreference> get prospectiveTenants => _prospectiveTenants;
  Map<int, Map<String, dynamic>> get propertyAssignments =>
      _propertyAssignments;
  bool get isLoadingProspective => _isLoadingProspective;
  bool get isLoadingAssignments => _isLoadingAssignments;

  // Current tenants getters (inherited from CollectionProvider)
  List<User> get currentTenants => items;

  // Tenant statistics
  int get totalCurrentTenants => items.length;
  int get totalProspectiveTenants => _prospectiveTenants.length;
  int get recentProspectives =>
      _prospectiveTenants
          .where(
            (p) => p.searchStartDate.isAfter(
              DateTime.now().subtract(const Duration(days: 7)),
            ),
          )
          .length;

  /// Load all tenant data (current + prospective + assignments)
  Future<void> loadAllData() async {
    await fetchItems(); // This calls _execute internally
    await _loadProspectiveTenantsInternal();

    // Load property assignments for current tenants
    if (items.isNotEmpty) {
      await _loadPropertyAssignmentsInternal(items.map((t) => t.id).toList());
    }
  }

  /// Load current tenants only
  Future<void> loadCurrentTenants({Map<String, String>? queryParams}) async {
    await fetchItems(queryParams);
  }

  /// Load prospective tenants only
  Future<void> loadProspectiveTenants({
    Map<String, String>? queryParams,
  }) async {
    _isLoadingProspective = true;
    if (!disposed) notifyListeners();

    try {
      await _loadProspectiveTenantsInternal(queryParams: queryParams);
    } finally {
      _isLoadingProspective = false;
      if (!disposed) notifyListeners();
    }
  }

  /// Load property assignments for given tenant IDs
  Future<void> loadPropertyAssignments(List<int> tenantIds) async {
    _isLoadingAssignments = true;
    if (!disposed) notifyListeners();

    try {
      await _loadPropertyAssignmentsInternal(tenantIds);
    } finally {
      _isLoadingAssignments = false;
      if (!disposed) notifyListeners();
    }
  }

  /// Record property offer to tenant
  Future<void> recordPropertyOffer(int tenantId, int propertyId) async {
    try {
      await _repository.recordPropertyOffer(tenantId, propertyId);

      // Refresh data after offer
      await loadAllData();
    } catch (e) {
      // Handle error appropriately
      rethrow;
    }
  }

  /// Submit review for tenant
  Future<void> submitTenantReview({
    required int tenantId,
    required double rating,
    required String description,
  }) async {
    try {
      await _repository.submitReview(
        tenantId: tenantId,
        rating: rating,
        description: description,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Filtering methods

  /// Filter current tenants by search criteria
  List<User> filterCurrentTenants({
    String? searchQuery,
    String? city,
    String? status,
  }) {
    return _repository.filterCurrentTenants(
      items,
      searchQuery: searchQuery,
      city: city,
      status: status,
    );
  }

  /// Filter prospective tenants by search criteria
  List<TenantPreference> filterProspectiveTenants({
    String? searchQuery,
    String? city,
    double? minBudget,
    double? maxBudget,
    List<String>? amenities,
  }) {
    return _repository.filterProspectiveTenants(
      _prospectiveTenants,
      searchQuery: searchQuery,
      city: city,
      minBudget: minBudget,
      maxBudget: maxBudget,
      amenities: amenities,
    );
  }

  /// Get property assignment for specific tenant
  Map<String, dynamic>? getTenantPropertyAssignment(int tenantId) {
    return _propertyAssignments[tenantId];
  }

  /// Get tenant statistics
  Map<String, int> getStatistics() {
    return _repository.getTenantStatistics(items, _prospectiveTenants);
  }

  // Refresh methods

  /// Refresh all data (for pull-to-refresh)
  Future<void> refreshAllData() async {
    // Clear local data
    _prospectiveTenants.clear();
    _propertyAssignments.clear();

    // Use built-in refresh method for current tenants
    await refreshItems();

    // Reload prospective tenants and assignments
    await _loadProspectiveTenantsInternal();
    if (items.isNotEmpty) {
      await _loadPropertyAssignmentsInternal(items.map((t) => t.id).toList());
    }
  }

  /// Refresh current tenants and their assignments
  Future<void> refreshCurrentTenants() async {
    await refreshItems();

    if (items.isNotEmpty) {
      await _loadPropertyAssignmentsInternal(items.map((t) => t.id).toList());
    }
  }

  /// Refresh prospective tenants only
  Future<void> refreshProspectiveTenants() async {
    _isLoadingProspective = true;
    if (!disposed) notifyListeners();

    try {
      await _loadProspectiveTenantsInternal();
    } finally {
      _isLoadingProspective = false;
      if (!disposed) notifyListeners();
    }
  }

  // Private helper methods

  Future<void> _loadProspectiveTenantsInternal({
    Map<String, String>? queryParams,
  }) async {
    final preferences = await _repository.getProspectiveTenants(
      queryParams: queryParams,
    );
    _prospectiveTenants.clear();
    _prospectiveTenants.addAll(preferences);
    if (!disposed) notifyListeners();
  }

  Future<void> _loadPropertyAssignmentsInternal(List<int> tenantIds) async {
    if (tenantIds.isEmpty) return;

    final assignments = await _repository.getTenantPropertyAssignments(
      tenantIds,
    );
    _propertyAssignments.clear();
    _propertyAssignments.addAll(assignments);
    if (!disposed) notifyListeners();
  }

  // Override unsupported operations for tenants
  @override
  Future<User> addItem(User item) async {
    throw UnsupportedError(
      'Adding tenants directly not supported. Use booking/lease creation.',
    );
  }

  @override
  Future<User> updateItem(String id, User item) async {
    throw UnsupportedError(
      'Updating tenants directly not supported. Use user management.',
    );
  }

  @override
  Future<void> removeItem(String id) async {
    throw UnsupportedError(
      'Deleting tenants directly not supported. Use lease termination.',
    );
  }

  @override
  String _getItemId(User item) {
    return item.id.toString();
  }
}
