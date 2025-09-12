import 'dart:async';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/payment.dart' as model;
import 'package:e_rents_mobile/core/models/user.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';

class InvoicesProvider extends BaseProvider {
  InvoicesProvider(super.api);

  List<model.Payment> _pending = [];
  bool _isPaying = false;
  String? _orderId;
  String? _approvalUrl;

  List<model.Payment> get pending => _pending;
  bool get isPaying => _isPaying;
  String? get orderId => _orderId;
  String? get approvalUrl => _approvalUrl;

  Future<int?> _getCurrentUserId() async {
    final user = await api.getAndDecode('/profile', User.fromJson, authenticated: true);
    return user.userId;
  }

  Future<void> loadPending() async {
    await executeWithState(() async {
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('Unable to load current user');
      final qs = api.buildQueryString({
        'TenantId': userId.toString(),
        'PaymentStatus': 'Pending',
        'PaymentType': 'SubscriptionPayment',
        'SortBy': 'createdat',
        'SortDirection': 'desc',
      });
      final items = await api.getListAndDecode('/payments$qs', model.Payment.fromJson, authenticated: true);
      _pending = items;
    });
  }

  /// Create a server order for an invoice payment and expose approvalUrl + orderId
  Future<Map<String, String>> createPaymentOrder(model.Payment p) async {
    if (_isPaying) throw Exception('Another payment is in progress');
    _isPaying = true;
    notifyListeners();

    try {
      final resp = await api.postJson(
        'payments/create-payment-order',
        {'paymentId': p.paymentId},
        authenticated: true,
      );
      final oid = (resp['orderId'] ?? '').toString();
      final url = (resp['approvalUrl'] ?? '').toString();
      if (oid.isEmpty || url.isEmpty) {
        throw Exception('Backend did not return orderId/approvalUrl');
      }
      _orderId = oid;
      _approvalUrl = url;
      notifyListeners();
      return {'orderId': oid, 'approvalUrl': url};
    } catch (e, st) {
      setError(GenericError(message: 'Failed to start invoice payment: $e', originalError: e, stackTrace: st));
      rethrow;
    } finally {
      _isPaying = false;
      notifyListeners();
    }
  }

  /// Capture a previously approved PayPal order, then refresh pending invoices
  Future<bool> captureOrder(String orderId) async {
    return await executeWithStateForSuccess(() async {
      await api.post('payments/capture-order', {'orderId': orderId}, authenticated: true);
      await loadPending();
    }, errorMessage: 'Failed to capture PayPal invoice');
  }
}
