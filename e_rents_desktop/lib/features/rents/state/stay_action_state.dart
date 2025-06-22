import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/booking.dart';
import 'package:e_rents_desktop/repositories/booking_repository.dart';
import 'package:flutter/material.dart';

class StayActionState extends ChangeNotifier {
  final BookingRepository _repository;
  final Booking _initialStay;
  AppError? error;
  bool isLoading = false;

  StayActionState(this._repository, this._initialStay);

  Future<bool> cancelStay({
    required String reason,
    bool requestRefund = false,
    String? additionalNotes,
  }) async {
    return _executeAction(() async {
      await _repository.cancelBooking(
        _initialStay.bookingId,
        reason,
        requestRefund,
        additionalNotes: additionalNotes,
      );
    });
  }

  Future<bool> _executeAction(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await action();
      isLoading = false;
      notifyListeners();
      return true;
    } on AppError catch (e) {
      error = e;
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
