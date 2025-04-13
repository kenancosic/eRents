import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/tenant_feedback.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class TenantProvider extends BaseProvider<User> {
  List<User> _currentTenants = [];
  List<TenantPreference> _searchingTenants = [];
  final Map<String, List<TenantFeedback>> _tenantFeedbacks = {};
  bool _isLoading = false;

  List<User> get currentTenants => _currentTenants;
  List<TenantPreference> get searchingTenants => _searchingTenants;
  bool get isLoading => _isLoading;

  List<TenantFeedback> getTenantFeedbacks(String tenantId) {
    return _tenantFeedbacks[tenantId] ?? [];
  }

  TenantProvider() {
    enableMockData(); // Enable mock data by default
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
  String get endpoint => 'tenants';

  @override
  List<User> getMockItems() {
    return MockDataService.getMockUsers()
        .where((user) => user.role == 'tenant')
        .toList();
  }

  Future<void> loadCurrentTenants() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allUsers = MockDataService.getMockUsers();
      _currentTenants =
          allUsers.where((user) => user.role == 'tenant').toList();

      print('Loaded ${_currentTenants.length} current tenants');
      for (var tenant in _currentTenants) {
        print(
          'Tenant: ${tenant.firstName} ${tenant.lastName} - ${tenant.city}',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadSearchingTenants() async {
    _isLoading = true;
    notifyListeners();

    try {
      _searchingTenants = MockDataService.getMockTenantPreferences();

      print('Loaded ${_searchingTenants.length} searching tenants');
      for (var preference in _searchingTenants) {
        print(
          'Preference: ${preference.city} - \$${preference.minPrice} - \$${preference.maxPrice}',
        );
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadTenantFeedbacks(String tenantId) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      _tenantFeedbacks[tenantId] =
          MockDataService.getMockTenantFeedbacks()
              .where((feedback) => feedback.tenantId == tenantId)
              .toList();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllData() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      await Future.wait([loadCurrentTenants(), loadSearchingTenants()]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessageToTenant(String tenantId, String message) async {
    // TODO: Implement sending message to tenant
    print('Sending message to tenant $tenantId: $message');
  }

  Future<void> sendPropertyOffer(String tenantId, String propertyId) async {
    // TODO: Implement sending property offer to tenant
    print(
      'Sending property offer to tenant $tenantId for property $propertyId',
    );
  }
}
