import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/repositories/profile_repository.dart';
import 'package:flutter/material.dart';

class PersonalInfoFormState extends ChangeNotifier {
  final ProfileRepository _repository;
  User _user;

  bool _isLoading = false;
  String? _errorMessage;

  final TextEditingController firstNameController;
  final TextEditingController lastNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  PersonalInfoFormState(this._repository, User initialUser)
    : _user = initialUser.copyWith(),
      firstNameController = TextEditingController(text: initialUser.firstName),
      lastNameController = TextEditingController(text: initialUser.lastName),
      emailController = TextEditingController(text: initialUser.email),
      phoneController = TextEditingController(text: initialUser.phone ?? ''),
      addressController = TextEditingController(
        text: initialUser.address?.streetLine1 ?? '',
      );

  User get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void updateUser({
    String? firstName,
    String? lastName,
    String? phone,
    Address? address,
  }) {
    _user = _user.copyWith(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      address: address,
    );
    // No need to notify here, controllers are the source of truth for the UI
  }

  Future<User?> saveChanges() async {
    // Sync user object with controllers before saving
    _user = _user.copyWith(
      firstName: firstNameController.text,
      lastName: lastNameController.text,
      phone: phoneController.text,
    );

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedUser = await _repository.updateProfile(_user);
      _user = updatedUser.copyWith(); // Keep state in sync
      _syncControllers(); // Sync controllers with the final saved state
      return updatedUser;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateAddress(Address? address) {
    if (address == null) return;
    _user = _user.copyWith(address: address);
    addressController.text = address.getFullAddress();
    notifyListeners();
  }

  void _syncControllers() {
    firstNameController.text = _user.firstName;
    lastNameController.text = _user.lastName;
    emailController.text = _user.email;
    phoneController.text = _user.phone ?? '';
    addressController.text = _user.address?.getFullAddress() ?? '';
  }

  Future<User?> uploadProfileImage(String imagePath) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final updatedUser = await _repository.uploadProfileImage(imagePath);
      _user = updatedUser.copyWith();
      _syncControllers();
      return updatedUser;
    } catch (e) {
      _errorMessage = e.toString();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }
}
