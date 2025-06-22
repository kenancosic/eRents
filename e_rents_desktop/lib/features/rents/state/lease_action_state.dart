import 'package:e_rents_desktop/base/base.dart';
import 'package:e_rents_desktop/models/rental_request.dart';
import 'package:e_rents_desktop/repositories/rental_request_repository.dart';
import 'package:flutter/material.dart';

class LeaseActionState extends ChangeNotifier {
  final RentalRequestRepository _repository;
  final RentalRequest _initialLease;
  AppError? error;
  bool isLoading = false;
  RentalRequest? _updatedLease;

  RentalRequest? get updatedLease => _updatedLease;

  LeaseActionState(this._repository, this._initialLease);

  Future<bool> approveRequest({String? response}) async {
    return _executeAction(() async {
      await _repository.approveRequest(
        _initialLease.requestId,
        response: response,
      );
    });
  }

  Future<bool> rejectRequest({String? response}) async {
    return _executeAction(() async {
      await _repository.rejectRequest(
        _initialLease.requestId,
        response: response,
      );
    });
  }

  Future<bool> _executeAction(Future<void> Function() action) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await action();
      // After action, we expect the main provider to reload,
      // so we don't fetch the updated item here.
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
