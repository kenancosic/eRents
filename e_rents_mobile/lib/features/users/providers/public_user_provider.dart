import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/models/paged_list.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';

/// Provider for loading a public user's profile info and their properties
class PublicUserProvider extends BaseProvider {
  PublicUserProvider(super.api);

  // State
  User? _user;
  List<PropertyDetail> _ownerProperties = [];
  bool _onlyAvailable = false;
  PublicUserSort _sort = PublicUserSort.availableFirst;
  int _currentPage = 1;
  final int _pageSize = 10;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  // Getters
  User? get user => _user;
  List<PropertyDetail> get ownerProperties => _ownerProperties;
  bool get onlyAvailable => _onlyAvailable;
  PublicUserSort get sort => _sort;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  List<PropertyDetail> get filteredProperties {
    if (!_onlyAvailable) return _ownerProperties;
    return _ownerProperties
        .where((p) => p.status == PropertyStatus.available)
        .toList();
  }

  // API
  Future<void> loadUser(int userId) async {
    final result = await executeWithState<User?>(() async {
      return await api.getAndDecode('/users/$userId', (json) {
        // Map supporting both camelCase and PascalCase
        final m = json;
        final id = m['userId'] ?? m['UserId'] ?? m['id'] ?? m['Id'];
        final firstName = m['firstName'] ?? m['FirstName'] ?? m['name'];
        final lastName = m['lastName'] ?? m['LastName'];
        final email = m['email'] ?? m['Email'];
        final username = m['username'] ?? m['Username'];
        final profileImageId = m['profileImageId'] ?? m['ProfileImageId'];
        return User(
          userId: id is int ? id : (int.tryParse(id?.toString() ?? '') ?? 0),
          username: username?.toString() ?? '',
          email: email?.toString() ?? '',
          firstName: firstName?.toString(),
          lastName: lastName?.toString(),
          profileImageId: profileImageId is int ? profileImageId : (int.tryParse(profileImageId?.toString() ?? '') ?? 0),
        );
      }, authenticated: true);
    });
    if (result != null) {
      _user = result;
      notifyListeners();
    }
  }

  Future<void> loadOwnerProperties(int ownerId, {bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _ownerProperties = [];
      notifyListeners();
    }

    if (!_hasMore) return;

    final page = await executeWithState<PagedList<PropertyDetail>>(() async {
      final params = {
        'OwnerId': ownerId.toString(),
        'pageNumber': _currentPage,
        'pageSize': _pageSize,
        if (_onlyAvailable) 'Status': 1, // Available=1
        ..._sortParamsForServer(_sort),
      };
      final endpoint = '/properties${api.buildQueryString(params)}';
      return await api.getPagedAndDecode(
        endpoint,
        (json) => PropertyDetail.fromJson(json),
        authenticated: true,
      );
    });

    if (page != null) {
      final newItems = page.items.where((p) => p.ownerId == ownerId).toList();
      final existingIds = _ownerProperties.map((e) => e.propertyId).toSet();
      final deduped = newItems.where((p) => !existingIds.contains(p.propertyId)).toList();
      _ownerProperties.addAll(deduped);
      _hasMore = page.hasNextPage;
      if (_hasMore) _currentPage++;
      notifyListeners();
    }
  }

  Future<void> loadMoreOwnerProperties(int ownerId) async {
    if (_isLoadingMore || !_hasMore) return;
    _isLoadingMore = true;
    notifyListeners();
    try {
      await loadOwnerProperties(ownerId);
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshOwner(int userId) async {
    await loadUser(userId);
    await loadOwnerProperties(userId, refresh: true);
  }

  void setOnlyAvailable(bool value) {
    _onlyAvailable = value;
    // Force refresh with server-side filtering
    // Note: userId may be needed; if user is loaded, use its id
    if (_user?.userId != null && _user!.userId! > 0) {
      // ignore: discarded_futures
      loadOwnerProperties(_user!.userId!, refresh: true);
    } else {
      notifyListeners();
    }
  }

  void setSort(PublicUserSort sort) {
    _sort = sort;
    if (_user?.userId != null && _user!.userId! > 0) {
      // ignore: discarded_futures
      loadOwnerProperties(_user!.userId!, refresh: true);
    } else {
      notifyListeners();
    }
  }

  Map<String, dynamic> _sortParamsForServer(PublicUserSort s) {
    switch (s) {
      case PublicUserSort.availableFirst:
        // Sort by numeric Status ascending: Available(1) first
        return {'sortBy': 'status', 'sortDirection': 'asc'};
      case PublicUserSort.priceLowToHigh:
        return {'sortBy': 'price', 'sortDirection': 'asc'};
      case PublicUserSort.priceHighToLow:
        return {'sortBy': 'price', 'sortDirection': 'desc'};
      case PublicUserSort.newest:
        return {'sortBy': 'createdat', 'sortDirection': 'desc'};
    }
  }
}

enum PublicUserSort { availableFirst, priceLowToHigh, priceHighToLow, newest }
