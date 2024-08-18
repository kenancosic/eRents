import 'dart:convert';
import 'package:e_rents_mobile/models/payment.dart';
import 'package:e_rents_mobile/providers/base_provider.dart';

class PaymentProvider extends BaseProvider<Payment> {
  PaymentProvider() : super("Payments");

  @override
  Payment fromJson(data) {
    return Payment.fromJson(data);
  }

  Future<Payment?> getPaymentById(int id) async {
    try {
      return await getById(id);
    } catch (e) {
      logError(e, 'getPaymentById');
      rethrow;
    }
  }

  Future<List<Payment>> getPayments({dynamic search}) async {
    try {
      return await get(search: search);
    } catch (e) {
      logError(e, 'getPayments');
      rethrow;
    }
  }

  Future<Payment?> createPayment(Payment payment) async {
    try {
      return await insert(payment);
    } catch (e) {
      logError(e, 'createPayment');
      rethrow;
    }
  }

  Future<Payment?> updatePayment(int id, Payment payment) async {
    try {
      return await update(id, payment);
    } catch (e) {
      logError(e, 'updatePayment');
      rethrow;
    }
  }

  Future<bool> deletePayment(int id) async {
    try {
      return await delete(id);
    } catch (e) {
      logError(e, 'deletePayment');
      rethrow;
    }
  }
}
