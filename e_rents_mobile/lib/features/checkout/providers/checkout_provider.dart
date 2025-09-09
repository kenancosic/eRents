import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';

/// Provider for managing checkout flow and payment processing
/// Refactored to use new standardized BaseProvider without caching
/// Uses proper state management with loading, success, and error states
class CheckoutProvider extends BaseProvider {
  CheckoutProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────

  // Payment and booking state
  String _selectedPaymentMethod = 'PayPal';

  // Checkout session data
  PropertyDetail? _currentProperty;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDailyRental = false;
  double _totalPrice = 0.0;
  int? _pendingBookingId; // store booking id created before payment

  // PayPal payment flow state
  String? _payPalApprovalUrl;
  String? _payPalOrderId;

  // ─── Getters ────────────────────────────────────────────────────────────
  String get selectedPaymentMethod => _selectedPaymentMethod;
  
  PropertyDetail? get currentProperty => _currentProperty;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isDailyRental => _isDailyRental;
  double get totalPrice => _totalPrice;
  String? get payPalApprovalUrl => _payPalApprovalUrl;
  String? get payPalOrderId => _payPalOrderId;
  int? get pendingBookingId => _pendingBookingId;

  // Simplified pricing - only show property price
  double get propertyPrice => _totalPrice;
  int get nights => _endDate != null && _startDate != null 
      ? _endDate!.difference(_startDate!).inDays 
      : 0;

  // Validation
  bool get isFormValid => 
      _currentProperty != null &&
      _startDate != null &&
      _endDate != null &&
      _selectedPaymentMethod.isNotEmpty;

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Initialize checkout session with property and booking details
  void initializeCheckout({
    required PropertyDetail property,
    required DateTime startDate,
    required DateTime endDate,
    required bool isDailyRental,
    required double totalPrice,
  }) {
    _currentProperty = property;
    _startDate = startDate;
    _endDate = endDate;
    _isDailyRental = isDailyRental;
    _totalPrice = totalPrice;
    _pendingBookingId = null;
    
    // Reset form state
    _selectedPaymentMethod = 'PayPal';

    notifyListeners();
    debugPrint('CheckoutProvider: Initialized checkout for property ${property.name}');
  }

  /// Update selected payment method
  void selectPaymentMethod(String paymentMethod) {
    if (_selectedPaymentMethod != paymentMethod) {
      _selectedPaymentMethod = paymentMethod;
      notifyListeners();
      debugPrint('CheckoutProvider: Selected payment method: $paymentMethod');
    }
  }

  /// Process payment and create booking
  /// Uses BaseProvider's executeWithState for proper error handling
  Future<bool> processPayment() async {
    if (!isFormValid) {
      throw Exception('Invalid form data - cannot process payment');
    }

    if (_selectedPaymentMethod == 'PayPal') {
      return await _initiatePayPalPayment();
    } else {
      // Handle other payment methods if any
      throw Exception('Selected payment method is not supported.');
    }
  }

  Future<bool> _initiatePayPalPayment() async {
    // Use manual state handling so we can surface friendly messages
    setLoading();
    try {
      // Step 1: Create booking with 'Pending' status to get a bookingId
      final bookingData = {
        'propertyId': _currentProperty!.propertyId,
        // Use DateOnly-friendly format to match backend binder
        'startDate': _startDate!.toIso8601String().split('T').first,
        'endDate': _endDate?.toIso8601String().split('T').first,
        'totalPrice': _totalPrice,
        'paymentMethod': _selectedPaymentMethod,
        // Currency required by backend validator (using USD for PayPal testing)
        'currency': 'USD',
      };

      final booking = await api.postAndDecode(
        'bookings',
        bookingData,
        Booking.fromJson,
        authenticated: true,
      );

      debugPrint('CheckoutProvider: Created pending booking ID: ${booking.bookingId}');
      _pendingBookingId = booking.bookingId;

      // Step 2: Create PayPal order
      final orderResponse = await api.postAndDecode(
        'payments/create-order',
        {'bookingId': booking.bookingId},
        (json) => {
          'orderId': json['orderId'],
          'approvalUrl': json['approvalUrl'],
        },
        authenticated: true,
      );

      _payPalOrderId = orderResponse['orderId'];
      _payPalApprovalUrl = orderResponse['approvalUrl'];

      debugPrint('CheckoutProvider: Created PayPal order ID: $_payPalOrderId');
      notifyListeners(); // Notify UI to open the approval URL

      setSuccess();
      return true;
    } catch (e, st) {
      final friendly = _mapPaymentInitiationError(e);
      setError(GenericError(message: friendly, originalError: e, stackTrace: st));
      return false;
    }
  }

  String _mapPaymentInitiationError(Object e) {
    final raw = e.toString();
    final msg = raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length)
        : raw;
    final m = msg.toLowerCase();

    // Detect PayPal linkage issues from backend message
    final ownerNotLinked =
        m.contains('owner') && m.contains('paypal') && m.contains('link');
    final tenantNotLinked =
        m.contains('tenant') && m.contains('paypal') && m.contains('link');

    if (ownerNotLinked) {
      return 'This property\'s owner hasn\'t linked a PayPal account yet. Please choose a different property or contact the owner.';
    }
    if (tenantNotLinked) {
      return 'You need to link your PayPal account before paying. Go to Profile → Payment methods to link your account.';
    }

    // Default friendly fallback including original brief reason
    return 'Failed to initiate PayPal payment: $msg';
  }

  /// Capture the PayPal order after user approval
  Future<bool> capturePayPalOrder(String orderId) async {
    final success = await executeWithStateForSuccess(() async {
      await api.post('payments/capture-order', {'orderId': orderId}, authenticated: true);
      debugPrint('CheckoutProvider: Successfully captured PayPal order ID: $orderId');
      // Backend will handle subscription creation for monthly rentals.
      _clearCheckoutSession();
    }, errorMessage: 'Failed to capture PayPal payment');

    return success;
  }

  /// Get property price for display
  double getPropertyPrice() {
    return _totalPrice;
  }

  /// Get formatted price string
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }

  /// Get booking summary for confirmation
  Map<String, dynamic> getBookingSummary() {
    return {
      'property': _currentProperty?.name ?? 'Unknown Property',
      'startDate': _startDate?.toIso8601String().split('T')[0],
      'endDate': _endDate?.toIso8601String().split('T')[0],
      'nights': nights,
      'paymentMethod': _selectedPaymentMethod,
      'totalPrice': formatPrice(_totalPrice),
    };
  }

  /// Clear checkout session data
  void _clearCheckoutSession() {
    _currentProperty = null;
    _startDate = null;
    _endDate = null;
    _isDailyRental = false;
    _totalPrice = 0.0;
    _selectedPaymentMethod = 'PayPal';
    _payPalApprovalUrl = null;
    _payPalOrderId = null;
    notifyListeners();
    debugPrint('CheckoutProvider: Cleared checkout session');
  }

  /// Cancel checkout and clear session
  void cancelCheckout() {
    _clearCheckoutSession();
    debugPrint('CheckoutProvider: Checkout cancelled by user');
  }

  @override
  void dispose() {
    _clearCheckoutSession();
    super.dispose();
  }
}
