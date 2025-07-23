import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/review.dart';
import 'package:e_rents_desktop/models/paged_result.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/services/api_service.dart';

/// ✅ NEW PROVIDER-ONLY ARCHITECTURE
/// Consolidated provider for all tenant management functionality
/// Replaces: TenantCollectionProvider, TenantDetailProvider, TenantUniversalTableProvider
/// Direct API calls via ApiService (no repository/service layers)
class TenantsProvider extends ChangeNotifier {
  final ApiService _api;
  
  TenantsProvider(this._api);

  // ─── State ──────────────────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  bool get hasError => _error != null;

  // Current tenants state
  List<User> _currentTenants = [];
  List<User> get currentTenants => _currentTenants;

  // Prospective tenants state
  List<TenantPreference> _prospectiveTenants = [];
  List<TenantPreference> get prospectiveTenants => _prospectiveTenants;
  bool _isLoadingProspective = false;
  bool get isLoadingProspective => _isLoadingProspective;

  // Selected tenant details state
  User? _selectedTenant;
  User? get selectedTenant => _selectedTenant;
  List<Review> _tenantFeedbacks = [];
  List<Review> get tenantFeedbacks => _tenantFeedbacks;
  bool _isLoadingFeedbacks = false;
  bool get isLoadingFeedbacks => _isLoadingFeedbacks;

  // Property assignments state
  Map<int, Map<String, dynamic>> _propertyAssignments = {};
  Map<int, Map<String, dynamic>> get propertyAssignments => _propertyAssignments;
  bool _isLoadingAssignments = false;
  bool get isLoadingAssignments => _isLoadingAssignments;

  // Pagination state for Universal System
  PagedResult<User>? _pagedResult;
  PagedResult<User>? get pagedResult => _pagedResult;

  // Property offer functionality state
  List<Property> _availableProperties = [];
  List<Property> get availableProperties => _availableProperties;
  bool _isLoadingProperties = false;
  bool get isLoadingProperties => _isLoadingProperties;
  bool _isSendingOffer = false;
  bool get isSendingOffer => _isSendingOffer;

  // Simple in-memory caching with TTL
  final Map<String, dynamic> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheTtl = Duration(minutes: 10);
  static const Duration _feedbacksCacheTtl = Duration(minutes: 5);

  // ─── Statistics ─────────────────────────────────────────────────────────
  int get totalCurrentTenants => _currentTenants.length;
  int get totalProspectiveTenants => _prospectiveTenants.length;
  int get recentProspectives => _prospectiveTenants
      .where((p) => p.searchStartDate.isAfter(
          DateTime.now().subtract(const Duration(days: 7))))
      .length;

  double get averageRating {
    if (_tenantFeedbacks.isEmpty) return 0.0;
    final totalRating = _tenantFeedbacks.fold<double>(
        0.0, (sum, review) => sum + (review.starRating ?? 0.0));
    return totalRating / _tenantFeedbacks.length;
  }

  List<Review> get recentFeedbacks {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _tenantFeedbacks
        .where((review) => review.dateCreated.isAfter(thirtyDaysAgo))
        .toList();
  }

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load all tenant data (current + prospective + assignments)
  Future<void> loadAllData() async {
    await loadCurrentTenants();
    await loadProspectiveTenants();
    
    if (_currentTenants.isNotEmpty) {
      await loadPropertyAssignments(_currentTenants.map((t) => t.id).toList());
    }
  }

  /// Load current tenants with optional query parameters
  Future<void> loadCurrentTenants({Map<String, String>? queryParams}) async {
    if (_isLoading) return;

    final cacheKey = 'current_tenants_${_hashParams(queryParams)}';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      _currentTenants = _cache[cacheKey] as List<User>;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _api.get('/tenant/current${_buildQueryString(queryParams)}', authenticated: true);
      final List<dynamic> data = jsonDecode(response.body);
      _currentTenants = data.map((json) => User.fromJson(json)).toList();
      
      // Cache the result
      _cache[cacheKey] = _currentTenants;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load current tenants: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load prospective tenants with optional query parameters
  Future<void> loadProspectiveTenants({Map<String, String>? queryParams}) async {
    if (_isLoadingProspective) return;

    final cacheKey = 'prospective_tenants_${_hashParams(queryParams)}';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      _prospectiveTenants = _cache[cacheKey] as List<TenantPreference>;
      notifyListeners();
      return;
    }

    _isLoadingProspective = true;
    notifyListeners();

    try {
      final response = await _api.get('/tenant/prospective${_buildQueryString(queryParams)}', authenticated: true);
      final List<dynamic> data = jsonDecode(response.body);
      _prospectiveTenants = data.map((json) => TenantPreference.fromJson(json)).toList();
      
      // Cache the result
      _cache[cacheKey] = _prospectiveTenants;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load prospective tenants: $e');
    } finally {
      _isLoadingProspective = false;
      notifyListeners();
    }
  }

  /// Load paginated tenants using Universal System
  Future<void> loadPagedTenants(Map<String, dynamic> params) async {
    if (_isLoading) return;

    final cacheKey = 'paged_tenants_${_hashParams(params)}';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      _pagedResult = _cache[cacheKey] as PagedResult<User>;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _api.get('/tenant${_buildQueryString(params)}', authenticated: true);
      final responseData = jsonDecode(response.body);
      
      _pagedResult = PagedResult<User>(
        items: (responseData['data'] as List).map((json) => User.fromJson(json)).toList(),
        totalCount: responseData['totalCount'] as int,
        page: (responseData['pageNumber'] as int) - 1, // Convert to 0-based
        pageSize: responseData['pageSize'] as int,
      );
      
      // Cache the result
      _cache[cacheKey] = _pagedResult;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load paged tenants: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load tenant details by ID
  Future<void> loadTenantDetails(int tenantId) async {
    final cacheKey = 'tenant_details_$tenantId';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      _selectedTenant = _cache[cacheKey] as User;
      notifyListeners();
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      final response = await _api.get('/tenant/current/$tenantId', authenticated: true);
      _selectedTenant = User.fromJson(jsonDecode(response.body));
      
      // Cache the result
      _cache[cacheKey] = _selectedTenant;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      // Also load feedbacks for this tenant
      await loadTenantFeedbacks(tenantId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tenant details: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Load tenant feedbacks
  Future<void> loadTenantFeedbacks(int tenantId) async {
    if (_isLoadingFeedbacks) return;

    final cacheKey = 'tenant_feedbacks_$tenantId';
    
    // Check cache first (shorter TTL for feedbacks)
    if (_isCacheValid(cacheKey, _feedbacksCacheTtl)) {
      _tenantFeedbacks = _cache[cacheKey] as List<Review>;
      notifyListeners();
      return;
    }

    _isLoadingFeedbacks = true;
    notifyListeners();

    try {
      final response = await _api.get('/tenant/feedback/$tenantId', authenticated: true);
      final List<dynamic> data = jsonDecode(response.body);
      _tenantFeedbacks = data.map((json) => Review.fromJson(json)).toList();
      
      // Cache the result with shorter TTL
      _cache[cacheKey] = _tenantFeedbacks;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load tenant feedbacks: $e');
      _tenantFeedbacks = []; // Reset on error
    } finally {
      _isLoadingFeedbacks = false;
      notifyListeners();
    }
  }

  /// Load property assignments for tenant IDs
  Future<void> loadPropertyAssignments(List<int> tenantIds) async {
    if (_isLoadingAssignments || tenantIds.isEmpty) return;

    final cacheKey = 'property_assignments_${tenantIds.join('_')}';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      _propertyAssignments = Map<int, Map<String, dynamic>>.from(_cache[cacheKey]);
      notifyListeners();
      return;
    }

    _isLoadingAssignments = true;
    notifyListeners();

    try {
      final queryParts = tenantIds.map((id) => 'tenantIds=$id').toList();
      final queryString = queryParts.join('&');
      
      final response = await _api.get('/tenant/assignments?$queryString', authenticated: true);
      
      if (response.body.isNotEmpty) {
        final responseData = jsonDecode(response.body);
        _propertyAssignments = Map<int, Map<String, dynamic>>.from(responseData);
      } else {
        _propertyAssignments = {};
      }
      
      // Cache the result
      _cache[cacheKey] = _propertyAssignments;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load property assignments: $e');
      _propertyAssignments = {}; // Reset on error
    } finally {
      _isLoadingAssignments = false;
      notifyListeners();
    }
  }

  /// Record property offer to tenant
  Future<bool> recordPropertyOffer(int tenantId, int propertyId) async {
    try {
      await _api.post('/tenant/$tenantId/offer/$propertyId', {}, authenticated: true);
      
      // Invalidate relevant caches
      _invalidateCache('current_tenants');
      _invalidateCache('property_assignments');
      
      // Refresh data
      await loadAllData();
      
      return true;
    } catch (e) {
      _setError('Failed to record property offer: $e');
      return false;
    }
  }

  /// Submit tenant review
  Future<bool> submitTenantReview({
    required int tenantId,
    required double rating,
    required String description,
  }) async {
    try {
      final reviewData = {
        'rating': rating,
        'description': description,
      };
      
      await _api.post('/tenant/feedback/$tenantId', reviewData, authenticated: true);
      
      // Invalidate feedbacks cache and reload
      _invalidateCache('tenant_feedbacks_$tenantId');
      await loadTenantFeedbacks(tenantId);
      
      return true;
    } catch (e) {
      _setError('Failed to submit tenant review: $e');
      return false;
    }
  }

  /// Add tenant feedback
  Future<bool> addTenantFeedback(int tenantId, Review feedback) async {
    try {
      final response = await _api.post('/tenant/feedback/$tenantId', feedback.toJson(), authenticated: true);
      final newFeedback = Review.fromJson(jsonDecode(response.body));
      
      _tenantFeedbacks.add(newFeedback);
      
      // Invalidate cache
      _invalidateCache('tenant_feedbacks_$tenantId');
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Failed to add tenant feedback: $e');
      return false;
    }
  }

  /// Get tenant property assignment
  Map<String, dynamic>? getTenantPropertyAssignment(int tenantId) {
    return _propertyAssignments[tenantId];
  }

  /// Get tenant statistics
  Map<String, int> getStatistics() {
    return {
      'totalCurrentTenants': totalCurrentTenants,
      'totalProspectiveTenants': totalProspectiveTenants,
      'tenantsWithFeedback': _tenantFeedbacks.length,
      'recentProspectives': recentProspectives,
    };
  }

  /// Filter current tenants by search criteria
  List<User> filterCurrentTenants({
    String? searchQuery,
    String? city,
    String? status,
  }) {
    return _currentTenants.where((tenant) {
      bool matchesSearch = searchQuery == null ||
          searchQuery.isEmpty ||
          tenant.fullName.toLowerCase().contains(searchQuery.toLowerCase()) ||
          tenant.email.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesCity = city == null ||
          city.isEmpty ||
          (tenant.address?.city?.toLowerCase() == city.toLowerCase());

      bool matchesStatus = status == null ||
          status.isEmpty ||
          tenant.role.toString().split('.').last.toLowerCase() == status.toLowerCase();

      return matchesSearch && matchesCity && matchesStatus;
    }).toList();
  }

  /// Filter prospective tenants by search criteria
  List<TenantPreference> filterProspectiveTenants({
    String? searchQuery,
    String? city,
    double? minBudget,
    double? maxBudget,
    List<String>? amenities,
  }) {
    return _prospectiveTenants.where((pref) {
      bool matchesSearch = searchQuery == null ||
          searchQuery.isEmpty ||
          (pref.city.toLowerCase().contains(searchQuery.toLowerCase()));

      bool matchesCity = city == null ||
          city.isEmpty ||
          (pref.city.toLowerCase() == city.toLowerCase());

      bool matchesBudget = (minBudget == null || (pref.maxPrice ?? 0) >= minBudget) &&
          (maxBudget == null || (pref.maxPrice ?? double.infinity) <= maxBudget);

      bool matchesAmenities = amenities == null ||
          amenities.isEmpty ||
          (pref.amenities.any((amenity) => amenities.contains(amenity)));

      return matchesSearch && matchesCity && matchesBudget && matchesAmenities;
    }).toList();
  }

  /// Get feedbacks by rating
  List<Review> getFeedbacksByRating(double minRating) {
    return _tenantFeedbacks
        .where((review) => (review.starRating ?? 0.0) >= minRating)
        .toList();
  }

  /// Refresh all data (for pull-to-refresh)
  Future<void> refreshAllData() async {
    _clearAllCaches();
    await loadAllData();
  }

  /// Refresh current tenants only
  Future<void> refreshCurrentTenants() async {
    _invalidateCache('current_tenants');
    await loadCurrentTenants();
    
    if (_currentTenants.isNotEmpty) {
      await loadPropertyAssignments(_currentTenants.map((t) => t.id).toList());
    }
  }

  /// Refresh prospective tenants only
  Future<void> refreshProspectiveTenants() async {
    _invalidateCache('prospective_tenants');
    await loadProspectiveTenants();
  }

  // ─── Property Offer Functionality ──────────────────────────────────────

  /// Load available properties for property offers
  Future<void> loadAvailableProperties() async {
    if (_isLoadingProperties) return;

    final cacheKey = 'available_properties';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      _availableProperties.clear();
      _availableProperties = _cache[cacheKey] as List<Property>;
      notifyListeners();
      return;
    }

    _isLoadingProperties = true;
    notifyListeners();

    try {
      final response = await _api.get('/property?IsAvailable=true', authenticated: true);
      final List<dynamic> data = jsonDecode(response.body);
      _availableProperties = data.map((json) => Property.fromJson(json)).toList();
      
      // Cache the result
      _cache[cacheKey] = _availableProperties;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load available properties: $e');
      _availableProperties = []; // Reset on error
    } finally {
      _isLoadingProperties = false;
      notifyListeners();
    }
  }

  /// Send property offer to tenant
  Future<bool> sendPropertyOffer(int tenantId, int propertyId, {String? customMessage}) async {
    if (_isSendingOffer) return false;

    _isSendingOffer = true;
    _clearError();
    notifyListeners();

    try {
      // Send the property offer via chat/messaging system
      final offerData = {
        'tenantId': tenantId,
        'propertyId': propertyId,
        'message': customMessage ?? 'Property offer sent',
        'offerType': 'property_offer',
      };
      
      await _api.post('/chat/send-property-offer', offerData, authenticated: true);
      
      // Also record the property offer in the tenant system
      await recordPropertyOffer(tenantId, propertyId);
      
      return true;
    } catch (e) {
      _setError('Failed to send property offer: $e');
      return false;
    } finally {
      _isSendingOffer = false;
      notifyListeners();
    }
  }

  /// Clear tenant-specific data
  void clearTenantData() {
    _selectedTenant = null;
    _tenantFeedbacks.clear();
    _isLoadingFeedbacks = false;
    notifyListeners();
  }

  // ─── Private Helper Methods ────────────────────────────────────────────

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  bool _isCacheValid(String key, [Duration? ttl]) {
    ttl ??= _cacheTtl;
    if (!_cache.containsKey(key) || !_cacheTimestamps.containsKey(key)) {
      return false;
    }
    
    final timestamp = _cacheTimestamps[key]!;
    return DateTime.now().difference(timestamp) < ttl;
  }

  void _invalidateCache(String keyPrefix) {
    final keysToRemove = <String>[];
    for (final key in _cache.keys) {
      if (key.startsWith(keyPrefix)) {
        keysToRemove.add(key);
      }
    }
    
    for (final key in keysToRemove) {
      _cache.remove(key);
      _cacheTimestamps.remove(key);
    }
  }

  void _clearAllCaches() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  String _hashParams(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return 'default';
    final sortedParams = Map.fromEntries(
        params.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
    return sortedParams.entries.map((e) => '${e.key}:${e.value}').join('_');
  }

  String _buildQueryString(Map<String, dynamic>? params) {
    if (params == null || params.isEmpty) return '';
    final queryString = params.entries.map((e) => '${e.key}=${e.value}').join('&');
    return '?$queryString';
  }

  @override
  void dispose() {
    _clearAllCaches();
    super.dispose();
  }
}
