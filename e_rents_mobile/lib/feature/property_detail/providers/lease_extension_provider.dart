import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/models/lease_extension_request.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';

/// Provider for managing lease extensions
/// Handles lease extension requests for properties
class LeaseExtensionProvider extends BaseProvider {
  LeaseExtensionProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  List<LeaseExtensionRequest> _leaseExtensions = [];
  List<LeaseExtensionRequest> _allLeaseExtensions = [];
  LeaseExtensionRequest? _selectedLeaseExtension;
  bool _isRequestingExtension = false;
  DateTime? _extensionStartDate;
  DateTime? _extensionEndDate;
  String _extensionReason = '';
  bool _isDateRangeValid = true;
  String? _dateRangeError;

  // ─── Getters ────────────────────────────────────────────────────────────
  List<LeaseExtensionRequest> get leaseExtensions => _leaseExtensions;
  List<LeaseExtensionRequest> get allLeaseExtensions => _allLeaseExtensions;
  LeaseExtensionRequest? get selectedLeaseExtension => _selectedLeaseExtension;
  bool get isRequestingExtension => _isRequestingExtension;
  DateTime? get extensionStartDate => _extensionStartDate;
  DateTime? get extensionEndDate => _extensionEndDate;
  String get extensionReason => _extensionReason;
  bool get isDateRangeValid => _isDateRangeValid;
  String? get dateRangeError => _dateRangeError;

  // ─── Public API ─────────────────────────────────────────────────────────
  
  /// Fetch lease extensions for a property
  Future<void> fetchLeaseExtensions(int propertyId) async {
    final extensions = await executeWithState(() async {
      return await api.getListAndDecode('/lease-extensions/property/$propertyId', LeaseExtensionRequest.fromJson, authenticated: true);
    });

    if (extensions != null) {
      _allLeaseExtensions = extensions;
      _leaseExtensions = List.from(_allLeaseExtensions);
    }
  }

  /// Request a lease extension
  Future<bool> requestLeaseExtension(int propertyId) async {
    if (_extensionStartDate == null || _extensionEndDate == null) {
      setError(GenericError(message: 'Please select start and end dates for extension', code: 'lease_extension_dates_missing'));
      return false;
    }
    
    if (!_isDateRangeValid) {
      setError(GenericError(message: _dateRangeError ?? 'Invalid date range for extension', code: 'lease_extension_invalid_date_range'));
      return false;
    }
    
    if (_isRequestingExtension) return false;
    _isRequestingExtension = true;
    notifyListeners();

    final success = await executeWithStateForSuccess(() async {
      final newExtension = await api.postAndDecode('/lease-extensions', {
        'propertyId': propertyId,
        'startDate': _extensionStartDate!.toIso8601String(),
        'endDate': _extensionEndDate!.toIso8601String(),
        'reason': _extensionReason,
      }, LeaseExtensionRequest.fromJson, authenticated: true);
      
      _allLeaseExtensions.insert(0, newExtension);
      _leaseExtensions = List.from(_allLeaseExtensions);
    }, errorMessage: 'Failed to request lease extension');

    _isRequestingExtension = false;
    notifyListeners();
    return success;
  }

  /// Select a lease extension
  void selectLeaseExtension(LeaseExtensionRequest extension) {
    _selectedLeaseExtension = extension;
    notifyListeners();
  }

  /// Set extension date range
  void setExtensionDateRange(DateTime? start, DateTime? end) {
    _extensionStartDate = start;
    _extensionEndDate = end;
    _validateDateRange();
    notifyListeners();
  }

  /// Set extension reason
  void setExtensionReason(String reason) {
    _extensionReason = reason;
    notifyListeners();
  }

  /// Clear extension form
  void clearExtensionForm() {
    _extensionStartDate = null;
    _extensionEndDate = null;
    _extensionReason = '';
    _isDateRangeValid = true;
    _dateRangeError = null;
    notifyListeners();
  }

  void _validateDateRange() {
    if (_extensionStartDate == null || _extensionEndDate == null) {
      _isDateRangeValid = true;
      _dateRangeError = null;
      return;
    }

    if (_extensionStartDate!.isAfter(_extensionEndDate!)) {
      _isDateRangeValid = false;
      _dateRangeError = 'Start date must be before end date';
      return;
    }

    if (_extensionStartDate!.isBefore(DateTime.now())) {
      _isDateRangeValid = false;
      _dateRangeError = 'Extension start date cannot be in the past';
      return;
    }

    final difference = _extensionEndDate!.difference(_extensionStartDate!).inDays;
    if (difference > 30) {
      _isDateRangeValid = false;
      _dateRangeError = 'Extension duration cannot exceed 30 days';
      return;
    }

    _isDateRangeValid = true;
    _dateRangeError = null;
  }
}
