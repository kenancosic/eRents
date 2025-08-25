import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/payment.dart'; // Assuming Payment model exists

/// Provider for managing payment methods
class PaymentMethodsProvider extends BaseProvider {
  PaymentMethodsProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<Payment> _paymentMethods = [];
  bool _isUpdatingPaypal = false;

  // ─── Getters ────────────────────────────────────────────────────────────
  List<Payment> get paymentMethods => _paymentMethods;
  bool get isUpdatingPaypal => _isUpdatingPaypal;

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Load user payment methods
  Future<void> loadPaymentMethods({bool forceRefresh = false}) async {
    if (!forceRefresh && _paymentMethods.isNotEmpty) {
      debugPrint('PaymentMethodsProvider: Using existing payment methods');
      return;
    }

    final methods = await executeWithState<List<Payment>>(() async {
      final response = await api.get('/users/current/payment-methods', authenticated: true);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Payment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load payment methods');
      }
    });

    if (methods != null) {
      _paymentMethods = methods;
    }
  }

  /// Add a new payment method
  Future<bool> addPaymentMethod(Map<String, dynamic> paymentData) async {
    return await executeWithStateForSuccess(() async {
      final response = await api.post('/users/current/payment-methods', paymentData, authenticated: true);
      if (response.statusCode == 200 || response.statusCode == 201) {
        await loadPaymentMethods(forceRefresh: true); // Refresh list
      } else {
        throw Exception('Failed to add payment method');
      }
    }, errorMessage: 'Failed to add payment method');
  }

  /// Update an existing payment method
  Future<bool> updatePaymentMethod(String methodId, Map<String, dynamic> paymentData) async {
    return await executeWithStateForSuccess(() async {
      final response = await api.put('/users/current/payment-methods/$methodId', paymentData, authenticated: true);
      if (response.statusCode == 200) {
        await loadPaymentMethods(forceRefresh: true); // Refresh list
      } else {
        throw Exception('Failed to update payment method');
      }
    }, errorMessage: 'Failed to update payment method');
  }

  /// Delete a payment method
  Future<bool> deletePaymentMethod(String methodId) async {
    return await executeWithStateForSuccess(() async {
      final response = await api.delete('/users/current/payment-methods/$methodId', authenticated: true);
      if (response.statusCode == 200) {
        _paymentMethods.removeWhere((method) => method.paymentId.toString() == methodId);
        notifyListeners();
      } else {
        throw Exception('Failed to delete payment method');
      }
    }, errorMessage: 'Failed to delete payment method');
  }

  /// Start PayPal linking process and return the approval URL
  Future<String?> startPayPalLinking() async {
    _isUpdatingPaypal = true;
    notifyListeners();

    final url = await executeWithState<String?>(() async {
      final response = await api.get('/api/PaypalLink/start', authenticated: true);
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['approvalUrl'];
      } else {
        throw Exception('Failed to start PayPal linking process.');
      }
    });

    _isUpdatingPaypal = false;
    notifyListeners();
    return url;
  }

  /// Unlink PayPal account
  Future<bool> unlinkPaypal() async {
    return await executeWithStateForSuccess(() async {
      final response = await api.delete('/api/PaypalLink', authenticated: true);
      if (response.statusCode != 200) {
        throw Exception('Failed to unlink PayPal account');
      }
      // You might want to refresh user profile data here to reflect the change
    }, errorMessage: 'Failed to unlink PayPal account');
  }
}
