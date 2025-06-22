import 'package:flutter/material.dart';
import 'package:e_rents_desktop/repositories/profile_repository.dart';

class ChangePasswordFormState extends ChangeNotifier {
  final ProfileRepository _repository;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final TextEditingController currentPasswordController =
      TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  ChangePasswordFormState(this._repository);

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<bool> changePassword() async {
    if (!formKey.currentState!.validate()) {
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.changePassword(
        currentPassword: currentPasswordController.text,
        newPassword: newPasswordController.text,
        confirmPassword: confirmPasswordController.text,
      );

      // Clear fields on success
      currentPasswordController.clear();
      newPasswordController.clear();
      confirmPasswordController.clear();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }
}
