import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/subscription.dart';

/// Provider for managing tenant subscriptions (monthly rental payments)
/// 
/// Features:
/// - View active subscriptions
/// - View subscription payment schedule
/// - Cancel/pause/resume subscriptions
class SubscriptionProvider extends BaseProvider {
  SubscriptionProvider(super.api);

  // ─── State ─────────────────────────────────────────────────────────────────
  List<Subscription> _subscriptions = [];
  Subscription? _selectedSubscription;

  // ─── Getters ───────────────────────────────────────────────────────────────
  
  List<Subscription> get subscriptions => _subscriptions;
  Subscription? get selectedSubscription => _selectedSubscription;
  bool get isEmpty => _subscriptions.isEmpty;
  
  /// Active subscriptions only
  List<Subscription> get activeSubscriptions => 
      _subscriptions.where((s) => s.isActive).toList();
  
  /// Paused subscriptions
  List<Subscription> get pausedSubscriptions => 
      _subscriptions.where((s) => s.isPaused).toList();
  
  /// Check if user has any active subscriptions
  bool get hasActiveSubscription => activeSubscriptions.isNotEmpty;

  // ─── Public API ────────────────────────────────────────────────────────────

  /// Load all subscriptions for current user
  Future<void> loadSubscriptions() async {
    final subs = await executeWithState<List<Subscription>?>(() async {
      debugPrint('SubscriptionProvider: Loading subscriptions');
      
      return await api.getListAndDecode(
        '/subscriptions',
        Subscription.fromJson,
        authenticated: true,
      );
    });

    if (subs != null) {
      _subscriptions = subs;
      debugPrint('SubscriptionProvider: Loaded ${subs.length} subscriptions');
      notifyListeners();
    }
  }

  /// Get a single subscription by ID
  Future<Subscription?> getSubscription(int subscriptionId) async {
    return await executeWithState<Subscription?>(() async {
      debugPrint('SubscriptionProvider: Loading subscription $subscriptionId');
      return await api.getAndDecode(
        '/subscriptions/$subscriptionId',
        Subscription.fromJson,
        authenticated: true,
      );
    });
  }

  /// Cancel a subscription
  Future<bool> cancelSubscription(int subscriptionId) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('SubscriptionProvider: Cancelling subscription $subscriptionId');
      await api.post('/subscriptions/$subscriptionId/cancel', {}, authenticated: true);
    });

    if (success) {
      // Update local state
      final index = _subscriptions.indexWhere((s) => s.subscriptionId == subscriptionId);
      if (index != -1) {
        // Refresh from server to get updated status
        await loadSubscriptions();
      }
    }

    return success;
  }

  /// Pause a subscription
  Future<bool> pauseSubscription(int subscriptionId) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('SubscriptionProvider: Pausing subscription $subscriptionId');
      await api.post('/subscriptions/$subscriptionId/pause', {}, authenticated: true);
    });

    if (success) {
      await loadSubscriptions();
    }

    return success;
  }

  /// Resume a paused subscription
  Future<bool> resumeSubscription(int subscriptionId) async {
    final success = await executeWithStateForSuccess(() async {
      debugPrint('SubscriptionProvider: Resuming subscription $subscriptionId');
      await api.post('/subscriptions/$subscriptionId/resume', {}, authenticated: true);
    });

    if (success) {
      await loadSubscriptions();
    }

    return success;
  }

  /// Select a subscription for detail view
  void selectSubscription(Subscription subscription) {
    _selectedSubscription = subscription;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedSubscription = null;
    notifyListeners();
  }

  /// Clear all data on logout
  void clearOnLogout() {
    _subscriptions = [];
    _selectedSubscription = null;
    notifyListeners();
  }
}
