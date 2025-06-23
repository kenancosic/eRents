import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/repositories/property_repository.dart';
import 'package:e_rents_desktop/features/chat/providers/chat_collection_provider.dart';
import 'package:e_rents_desktop/base/app_error.dart';

class SendPropertyOfferState extends ChangeNotifier {
  final PropertyRepository _propertyRepository;
  final ChatCollectionProvider _chatProvider;
  final int _tenantId;

  SendPropertyOfferState(
    this._propertyRepository,
    this._chatProvider,
    this._tenantId,
  ) {
    _loadAvailableProperties();
  }

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  bool _isSending = false;
  bool get isSending => _isSending;

  AppError? _error;
  AppError? get error => _error;

  List<Property> _availableProperties = [];
  List<Property> get availableProperties => _availableProperties;

  Future<void> _loadAvailableProperties() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Assuming a method exists to get available properties.
      // We might need to adjust this based on the repository's capabilities.
      _availableProperties = await _propertyRepository.getAll({
        'IsAvailable': true,
      });
    } catch (e, s) {
      _error = AppError.fromException(e, s);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendOffer(int propertyId) async {
    _isSending = true;
    _error = null;
    notifyListeners();

    try {
      await _chatProvider.sendPropertyOfferMessage(_tenantId, propertyId);
      return true;
    } catch (e, s) {
      _error = AppError.fromException(e, s);
      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
