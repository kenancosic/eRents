import 'dart:async';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/payment.dart' as model;
import 'package:e_rents_mobile/core/base/app_error.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';

enum InvoiceFilter { all, pending, paid }

class InvoicesProvider extends BaseProvider {
  InvoicesProvider(super.api);

  List<model.Payment> _allInvoices = [];
  List<model.Payment> _pending = [];
  bool _isPaying = false;
  String? _stripeClientSecret;
  String? _stripePaymentIntentId;
  InvoiceFilter _filter = InvoiceFilter.pending;

  List<model.Payment> get allInvoices => _allInvoices;
  List<model.Payment> get pending => _pending;
  bool get isPaying => _isPaying;
  String? get stripeClientSecret => _stripeClientSecret;
  String? get stripePaymentIntentId => _stripePaymentIntentId;
  InvoiceFilter get filter => _filter;

  /// Get filtered invoices based on current filter
  List<model.Payment> get filteredInvoices {
    switch (_filter) {
      case InvoiceFilter.pending:
        return _allInvoices.where((p) => p.paymentStatus == 'Pending').toList();
      case InvoiceFilter.paid:
        return _allInvoices.where((p) => p.paymentStatus == 'Completed' || p.paymentStatus == 'Paid').toList();
      case InvoiceFilter.all:
        return _allInvoices;
    }
  }

  void setFilter(InvoiceFilter f) {
    _filter = f;
    notifyListeners();
  }

  /// Load all invoices (pending + paid) using CurrentUserProvider
  /// 
  /// Uses CurrentUserProvider to avoid duplicate /profile API calls.
  Future<void> loadInvoices(CurrentUserProvider currentUserProvider) async {
    await executeWithState(() async {
      final user = await currentUserProvider.ensureLoaded();
      final userId = user?.userId;
      if (userId == null) throw Exception('Unable to load current user');
      final qs = api.buildQueryString({
        'TenantUserId': userId.toString(),
        'PaymentType': 'SubscriptionPayment',
        'SortBy': 'createdat',
        'SortDirection': 'desc',
      });
      final items = await api.getListAndDecode('/payments$qs', model.Payment.fromJson, authenticated: true);
      _allInvoices = items;
      _pending = items.where((p) => p.paymentStatus == 'Pending').toList();
    });
  }

  /// Legacy method for backwards compatibility
  Future<void> loadPending(CurrentUserProvider currentUserProvider) => loadInvoices(currentUserProvider);

  /// Send invoice PDF to tenant's email
  Future<bool> sendInvoicePdfToEmail(int paymentId) async {
    return await executeWithStateForSuccess(() async {
      await api.postJson(
        'payments/$paymentId/send-invoice-email',
        {},
        authenticated: true,
      );
    }, errorMessage: 'Failed to send invoice email');
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
