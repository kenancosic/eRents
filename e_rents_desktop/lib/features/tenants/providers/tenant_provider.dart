import 'package:e_rents_desktop/base/base_provider.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/tenant_feedback.dart';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';

class TenantProvider extends BaseProvider<User> {
  List<User> _currentTenants = [];
  List<TenantPreference> _searchingTenants = [];
  final Map<String, List<TenantFeedback>> _tenantFeedbacks = {};
  final Map<String, List<Message>> _tenantMessages = {};
  final Map<String, List<String>> _tenantPropertyOffers = {};
  bool _isLoading = false;

  List<User> get currentTenants => _currentTenants;
  List<TenantPreference> get searchingTenants => _searchingTenants;
  bool get isLoading => _isLoading;

  List<TenantFeedback> getTenantFeedbacks(String tenantId) {
    return _tenantFeedbacks[tenantId] ?? [];
  }

  List<Message> getTenantMessages(String tenantId) {
    return _tenantMessages[tenantId] ?? [];
  }

  List<String> getTenantPropertyOffers(String tenantId) {
    return _tenantPropertyOffers[tenantId] ?? [];
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
        .where(
          (user) => user.role == UserType.landlord,
        ) // For now treat all as landlord
        .toList();
  }

  Future<void> loadCurrentTenants() async {
    _isLoading = true;
    notifyListeners();

    try {
      final allUsers = MockDataService.getMockUsers();
      _currentTenants =
          allUsers
              .where((user) => user.role == UserType.landlord)
              .toList(); // For now treat all as landlord

      print('Loaded ${_currentTenants.length} current tenants');
      for (var tenant in _currentTenants) {
        print(
          'Tenant: ${tenant.firstName} ${tenant.lastName} - ${tenant.addressDetail?.geoRegion?.city}',
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

  Future<void> recordPropertyOffer(String tenantId, String propertyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Add property offer to tenant's offers (local mock implementation)
      if (!_tenantPropertyOffers.containsKey(tenantId)) {
        _tenantPropertyOffers[tenantId] = [];
      }

      if (!_tenantPropertyOffers[tenantId]!.contains(propertyId)) {
        _tenantPropertyOffers[tenantId]!.add(propertyId);
      }

      print(
        'Property offer recorded for tenant $tenantId for property $propertyId',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // This method is problematic as TenantProvider shouldn't manage chat messages directly.
  // It's kept for now to avoid breaking existing calls but should be deprecated/removed
  // in favor of using ChatProvider for all chat message sending.
  Future<void> sendMessageToTenant(String tenantId, String content) async {
    _isLoading = true;
    notifyListeners();

    try {
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId:
            'landlord_currentUser_id', // FIXME: This should be actual landlord ID from AuthProvider
        receiverId: tenantId,
        messageText: content,
        dateSent: DateTime.now(),
      );

      if (!_tenantMessages.containsKey(tenantId)) {
        _tenantMessages[tenantId] = [];
      }
      _tenantMessages[tenantId]!.add(message);

      print(
        'DEBUG TenantProvider: Message supposedly sent to $tenantId: $content',
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
