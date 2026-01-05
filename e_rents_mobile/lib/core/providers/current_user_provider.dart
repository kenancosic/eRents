import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/user.dart';

/// Centralized provider for current user data
/// 
/// This provider eliminates duplicate /profile API calls across multiple providers.
/// Other providers should depend on this to get current user information.
/// 
/// Usage:
/// ```dart
/// // Ensure user is loaded
/// final user = await currentUserProvider.ensureLoaded();
/// 
/// // Access cached user
/// final userId = currentUserProvider.currentUserId;
/// final city = currentUserProvider.currentCity;
/// ```
class CurrentUserProvider extends BaseProvider {
  CurrentUserProvider(super.api);

  // ─── State ─────────────────────────────────────────────────────────────────
  User? _user;
  DateTime? _loadedAt;
  static const _cacheDuration = Duration(minutes: 15);

  // ─── Getters ───────────────────────────────────────────────────────────────
  
  /// The currently loaded user (may be null if not loaded)
  User? get currentUser => _user;
  
  /// The current user's ID (null if not loaded)
  int? get currentUserId => _user?.userId;
  
  /// The current user's city (null if not loaded or no address)
  String? get currentCity => _user?.address?.city;
  
  /// The current user's full name
  String? get currentUserName => _user != null 
      ? '${_user!.firstName ?? ''} ${_user!.lastName ?? ''}'.trim()
      : null;
  
  /// The current user's email
  String? get currentUserEmail => _user?.email;
  
  /// Whether user data is available
  bool get hasUser => _user != null;
  
  /// Whether the cached data is still valid
  bool get _isCacheValid => 
      _user != null && 
      _loadedAt != null && 
      DateTime.now().difference(_loadedAt!) < _cacheDuration;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Ensure user data is loaded, using cache if valid
  /// 
  /// This is the primary method other providers should call.
  /// It will only make an API call if:
  /// - No user data is cached
  /// - Cache has expired (15 minutes)
  /// - Force refresh is requested
  /// 
  /// Returns the loaded user or null if loading failed.
  Future<User?> ensureLoaded({bool force = false}) async {
    // Return cached data if valid and not forcing refresh
    if (!force && _isCacheValid) {
      debugPrint('CurrentUserProvider: Using cached user data');
      return _user;
    }

    // Load fresh data
    final user = await executeWithState(() async {
      debugPrint('CurrentUserProvider: Loading current user from API');
      return await api.getAndDecode('/profile', User.fromJson, authenticated: true);
    });

    if (user != null) {
      _user = user;
      _loadedAt = DateTime.now();
      debugPrint('CurrentUserProvider: User loaded - ID: ${user.userId}, City: ${user.address?.city}');
    }

    return _user;
  }

  /// Force refresh user data from API
  Future<User?> refresh() async {
    return await ensureLoaded(force: true);
  }

  /// Clear user data on logout
  /// 
  /// Should be called when the user logs out to ensure
  /// stale data isn't used on next login.
  void clearOnLogout() {
    _user = null;
    _loadedAt = null;
    debugPrint('CurrentUserProvider: User data cleared on logout');
    notifyListeners();
  }

  /// Update local user data
  /// 
  /// Used when user profile is updated to keep cached data in sync
  /// without requiring a new API call.
  void updateUser(User user) {
    _user = user;
    _loadedAt = DateTime.now();
    notifyListeners();
  }
}
