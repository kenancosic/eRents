import 'package:flutter/foundation.dart';
import 'package:paypal_sdk/catalog_products.dart';
import 'package:paypal_sdk/core.dart';
import 'package:paypal_sdk/orders.dart';
import 'package:paypal_sdk/payments.dart';
import 'package:paypal_sdk/subscriptions.dart';
import 'package:paypal_sdk/webhooks.dart';

class PaymentService {
  final PayPalEnvironment _payPalClient;

  PaymentService({required String clientId, required String clientSecret})
      : _payPalClient = PayPalEnvironment.sandbox(clientId: clientId, clientSecret: clientSecret);

  Future<PaymentResult> processPayment(double amount, String currency) async {
    try {
      final payment = await _payPalClient.(amount: amount, currency: currency);
      return PaymentResult.success(payment);
    } catch (error) {
      return PaymentResult.failure(error.toString());
    }
  }

  Future<PaymentResult> executePayment(String paymentId, String payerId) async {
    try {
      final payment = await _payPalClient.executePayment(paymentId: paymentId, payerId: payerId);
      return PaymentResult.success(payment);
    } catch (error) {
      return PaymentResult.failure(error.toString());
    }
  }
}

class PaymentResult {
  final bool isSuccess;
  final String? message;
  final dynamic data;

  PaymentResult.success(this.data) : isSuccess = true, message = null;

  PaymentResult.failure(this.message) : isSuccess = false, data = null;
}
