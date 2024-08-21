import 'package:flutter/foundation.dart';
import 'base_provider.dart';
import '../services/payment_service.dart';

class PaymentProvider extends BaseProvider {
  final PaymentService _paymentService;

  PaymentProvider({required PaymentService paymentService})
      : _paymentService = paymentService;

  Future<bool> makePayment(double amount, String currency) async {
    setState(ViewState.Busy);
    final result = await _paymentService.processPayment(amount, currency);
    if (result.isSuccess) {
      setState(ViewState.Idle);
      return true;
    } else {
      setError(result.message!);
      return false;
    }
  }

  Future<bool> executePayment(String paymentId, String payerId) async {
    setState(ViewState.Busy);
    final result = await _paymentService.executePayment(paymentId, payerId);
    if (result.isSuccess) {
      setState(ViewState.Idle);
      return true;
    } else {
      setError(result.message!);
      return false;
    }
  }
}
