import 'dart:async';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/payment.dart' as model;
import 'package:e_rents_mobile/core/base/app_error.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';

class InvoicesProvider extends BaseProvider {
  InvoicesProvider(super.api);

  List<model.Payment> _pending = [];
  bool _isPaying = false;
  String? _stripeClientSecret;
  String? _stripePaymentIntentId;

  List<model.Payment> get pending => _pending;
  bool get isPaying => _isPaying;
  String? get stripeClientSecret => _stripeClientSecret;
  String? get stripePaymentIntentId => _stripePaymentIntentId;

  /// Load pending invoices using CurrentUserProvider
  /// 
  /// Uses CurrentUserProvider to avoid duplicate /profile API calls.
  Future<void> loadPending(CurrentUserProvider currentUserProvider) async {
    await executeWithState(() async {
      final user = await currentUserProvider.ensureLoaded();
      final userId = user?.userId;
      if (userId == null) throw Exception('Unable to load current user');
      final qs = api.buildQueryString({
        'TenantUserId': userId.toString(),
        'PaymentStatus': 'Pending',
        'PaymentType': 'SubscriptionPayment',
        'SortBy': 'createdat',
        'SortDirection': 'desc',
      });
      final items = await api.getListAndDecode('/payments$qs', model.Payment.fromJson, authenticated: true);
      _pending = items;
    });
  }

  /// Create Stripe payment intent for an invoice payment
  Future<Map<String, String>> createStripePaymentIntent(model.Payment p) async {
    if (_isPaying) throw Exception('Another payment is in progress');
    _isPaying = true;
    notifyListeners();

    try {
      final resp = await api.postJson(
        'payments/stripe/create-intent-for-invoice',
        {'paymentId': p.paymentId},
        authenticated: true,
      );
      final clientSecret = (resp['clientSecret'] ?? '').toString();
      final paymentIntentId = (resp['paymentIntentId'] ?? '').toString();
      if (clientSecret.isEmpty || paymentIntentId.isEmpty) {
        throw Exception('Backend did not return valid payment intent');
      }
      _stripeClientSecret = clientSecret;
      _stripePaymentIntentId = paymentIntentId;
      notifyListeners();
      return {'clientSecret': clientSecret, 'paymentIntentId': paymentIntentId};
    } catch (e, st) {
      setError(GenericError(message: 'Failed to start invoice payment: $e', originalError: e, stackTrace: st));
      rethrow;
    } finally {
      _isPaying = false;
      notifyListeners();
    }
  }

  /// Confirm Stripe payment was successful (called after Stripe SDK confirmation)
  /// 
  /// Note: This method doesn't refresh pending invoices automatically.
  /// Call loadPending(currentUserProvider) after this if needed.
  Future<bool> confirmStripePayment() async {
    return await executeWithStateForSuccess(() async {
      // Payment is confirmed by webhook, clear local state
      _stripeClientSecret = null;
      _stripePaymentIntentId = null;
    }, errorMessage: 'Failed to confirm invoice payment');
  }
}
