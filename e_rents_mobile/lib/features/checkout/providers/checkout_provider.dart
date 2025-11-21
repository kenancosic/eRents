import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/base/app_error.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
/// Provider for managing checkout flow and Stripe payment processing
/// Uses Stripe as the primary payment method
/// Refactored to use new standardized BaseProvider without caching
/// Uses proper state management with loading, success, and error states
class CheckoutProvider extends BaseProvider {
  CheckoutProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────

  // Payment and booking state
  final String _selectedPaymentMethod = 'Stripe'; // Stripe is now the only payment method

  // Checkout session data
  PropertyDetail? _currentProperty;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDailyRental = false;
  double _totalPrice = 0.0;
  int? _pendingBookingId; // store booking id created before payment

  // Stripe payment flow state
  String? _stripeClientSecret;
  String? _stripePaymentIntentId;

  // ─── Getters ────────────────────────────────────────────────────────────
  String get selectedPaymentMethod => _selectedPaymentMethod;
  
  PropertyDetail? get currentProperty => _currentProperty;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isDailyRental => _isDailyRental;
  double get totalPrice => _totalPrice;
  int? get pendingBookingId => _pendingBookingId;
  String? get stripeClientSecret => _stripeClientSecret;
  String? get stripePaymentIntentId => _stripePaymentIntentId;

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
    
    // Reset Stripe payment state
    _stripeClientSecret = null;
    _stripePaymentIntentId = null;

    notifyListeners();
    debugPrint('CheckoutProvider: Initialized checkout for property ${property.name}');
  }

  /// Submits a tenant request for MONTHLY rentals (no upfront payment).
  /// Backend will set UserId from auth context and default status to Inactive.
  Future<bool> submitTenantRequest() async {
    if (_currentProperty == null || _startDate == null) {
      setError(GenericError(message: 'Missing property or start date.'));
      return false;
    }
    if (_isDailyRental) {
      setError(GenericError(message: 'Tenant requests are only for monthly rentals.'));
      return false;
    }

    final y = _startDate!.year.toString().padLeft(4, '0');
    final m = _startDate!.month.toString().padLeft(2, '0');
    final d = _startDate!.day.toString().padLeft(2, '0');
    final payload = <String, dynamic>{
      'propertyId': _currentProperty!.propertyId,
      'leaseStartDate': '$y-$m-$d',
      if (_endDate != null)
        'leaseEndDate': '${_endDate!.year.toString().padLeft(4, '0')}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}',
      // TenantStatus is ignored by backend for mobile; defaults to Inactive
    };

    final ok = await executeWithStateForSuccess(() async {
      await api.post('tenants', payload, authenticated: true);
    }, errorMessage: 'Failed to submit tenant request');

    return ok;
  }

  // ─── Stripe Payment Flow ────────────────────────────────────────────────

  /// Create Stripe payment intent for daily rentals
  Future<Map<String, String>> createStripePaymentIntent() async {
    if (!_isDailyRental) {
      throw Exception('Stripe flow is only available for daily rentals.');
    }
    if (!isFormValid) {
      throw Exception('Invalid form data - cannot create payment intent');
    }
    if (_totalPrice <= 0) {
      throw Exception('Total price must be greater than zero.');
    }

    setLoading();
    try {
      // Step 1: Create booking with 'Pending' status to get a bookingId
      final bookingData = {
        'propertyId': _currentProperty!.propertyId,
        'startDate': _startDate!.toIso8601String().split('T').first,
        'endDate': _endDate?.toIso8601String().split('T').first,
        'totalPrice': _totalPrice,
        'paymentMethod': _selectedPaymentMethod,
        'currency': currentProperty?.currency ?? 'USD',
      };

      final booking = await api.postAndDecode(
        'bookings',
        bookingData,
        Booking.fromJson,
        authenticated: true,
      );

      debugPrint('CheckoutProvider: Created pending booking ID: \${booking.bookingId}');
      _pendingBookingId = booking.bookingId;

      // Step 2: Create Stripe payment intent
      final intentResp = await api.postJson(
        'payments/stripe/create-intent',
        {
          'bookingId': booking.bookingId,
          'amount': _totalPrice,
          'currency': currentProperty?.currency ?? 'USD',
          'metadata': {
            'propertyId': _currentProperty!.propertyId.toString(),
            'propertyName': _currentProperty!.name,
          },
        },
        authenticated: true,
      );

      final clientSecret = (intentResp['clientSecret'] ?? '').toString();
      final paymentIntentId = (intentResp['paymentIntentId'] ?? '').toString();
      
      if (clientSecret.isEmpty || paymentIntentId.isEmpty) {
        throw Exception('Backend did not return valid payment intent.');
      }

      _stripeClientSecret = clientSecret;
      _stripePaymentIntentId = paymentIntentId;

      setSuccess();
      return {
        'clientSecret': clientSecret,
        'paymentIntentId': paymentIntentId,
      };
    } catch (e, st) {
      final friendly = _mapPaymentError(e);
      setError(GenericError(message: friendly, originalError: e, stackTrace: st));
      rethrow;
    }
  }

  /// Map payment errors to user-friendly messages
  String _mapPaymentError(Object e) {
    final raw = e.toString();
    final msg = raw.startsWith('Exception: ')
        ? raw.substring('Exception: '.length)
        : raw;
    final m = msg.toLowerCase();

    // Amount validation errors
    if (m.contains('cannot_be_zero_or_negative') || m.contains('greater than zero')) {
      return 'Payment amount must be greater than zero. Please adjust your booking or contact support.';
    }

    // Generic Stripe errors
    if (m.contains('stripe') && m.contains('error')) {
      return 'Payment processing error: $msg';
    }

    // Default friendly fallback
    return 'Failed to process payment: $msg';
  }

  /// Confirm Stripe payment completion (called after Stripe SDK confirmation)
  Future<bool> confirmStripePayment() async {
    if (_stripePaymentIntentId == null) {
      setError(GenericError(message: 'No Stripe payment intent to confirm'));
      return false;
    }

    final success = await executeWithStateForSuccess(() async {
      debugPrint('CheckoutProvider: Confirming Stripe payment intent: \$_stripePaymentIntentId');
      // The payment intent is confirmed by Stripe SDK on client side
      // Backend webhook will handle the payment_intent.succeeded event
      // We just need to clear the checkout session
      _clearCheckoutSession();
    }, errorMessage: 'Failed to confirm Stripe payment');

    return success;
  }

  /// Process payment with Stripe
  /// Uses BaseProvider's executeWithState for proper error handling
  Future<bool> processPayment() async {
    if (!_isDailyRental) {
      throw Exception('Payment is not required for monthly rentals.');
    }
    if (!isFormValid) {
      throw Exception('Invalid form data - cannot process payment');
    }

    // Only Stripe is supported now
    await createStripePaymentIntent();
    return true;
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
    _stripeClientSecret = null;
    _stripePaymentIntentId = null;
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
