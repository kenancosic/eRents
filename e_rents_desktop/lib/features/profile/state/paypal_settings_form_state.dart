import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/repositories/profile_repository.dart';
import 'package:flutter/material.dart';

class PaypalSettingsFormState extends ChangeNotifier {
  final ProfileRepository _repository;
  User _user;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final TextEditingController paypalEmailController = TextEditingController();

  bool _isLinking = false;
  bool _isUnlinking = false;
  String? _errorMessage;

  PaypalSettingsFormState(this._repository, User initialUser)
    : _user = initialUser;

  bool get isLinking => _isLinking;
  bool get isUnlinking => _isUnlinking;
  bool get isPaypalLinked => _user.isPaypalLinked;
  String? get paypalIdentifier => _user.paypalUserIdentifier;
  String? get errorMessage => _errorMessage;

  Future<void> linkPaypalAccount() async {
    if (!formKey.currentState!.validate()) {
      return;
    }
    _isLinking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _repository.linkPayPalAccount(
        paypalEmailController.text.trim(),
      );
      _user = updatedUser;
      paypalEmailController.clear();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLinking = false;
      notifyListeners();
    }
  }

  Future<void> unlinkPaypalAccount() async {
    _isUnlinking = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _repository.unlinkPayPalAccount();
      _user = updatedUser;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isUnlinking = false;
      notifyListeners();
    }
  }

  void updateUser(User user) {
    _user = user;
    notifyListeners();
  }

  @override
  void dispose() {
    paypalEmailController.dispose();
    super.dispose();
  }
}
