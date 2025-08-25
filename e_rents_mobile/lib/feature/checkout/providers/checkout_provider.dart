import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/models/property.dart';

/// Provider for managing checkout flow and payment processing
/// Refactored to use new standardized BaseProvider without caching
/// Uses proper state management with loading, success, and error states
class CheckoutProvider extends BaseProvider {
  CheckoutProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────

  // Payment and booking state
  String _selectedPaymentMethod = 'PayPal';
  int _numberOfGuests = 1;
  String _specialRequests = '';
  bool _showPriceBreakdown = false;

  // Checkout session data
  Property? _currentProperty;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isDailyRental = false;
  double _totalPrice = 0.0;

  // ─── Getters ────────────────────────────────────────────────────────────
  String get selectedPaymentMethod => _selectedPaymentMethod;
  int get numberOfGuests => _numberOfGuests;
  String get specialRequests => _specialRequests;
  bool get showPriceBreakdown => _showPriceBreakdown;
  
  Property? get currentProperty => _currentProperty;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  bool get isDailyRental => _isDailyRental;
  double get totalPrice => _totalPrice;

  // Price breakdown calculations
  double get basePrice => _totalPrice / 1.1; // Remove 10% markup to get base
  double get serviceFee => basePrice * 0.05; // 5% service fee
  double get taxes => basePrice * 0.05; // 5% taxes
  double get cleaningFee => 25.0; // Fixed cleaning fee
  int get nights => _endDate != null && _startDate != null 
      ? _endDate!.difference(_startDate!).inDays 
      : 0;

  // Validation
  bool get isFormValid => 
      _currentProperty != null &&
      _startDate != null &&
      _endDate != null &&
      _numberOfGuests > 0 &&
      _selectedPaymentMethod.isNotEmpty;

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Initialize checkout session with property and booking details
  void initializeCheckout({
    required Property property,
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
    
    // Reset form state
    _selectedPaymentMethod = 'PayPal';
    _numberOfGuests = 1;
    _specialRequests = '';
    _showPriceBreakdown = false;
    
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

  /// Update number of guests
  void updateNumberOfGuests(int guests) {
    if (guests > 0 && _numberOfGuests != guests) {
      _numberOfGuests = guests;
      notifyListeners();
      debugPrint('CheckoutProvider: Updated guests count to $guests');
    }
  }

  /// Update special requests
  void updateSpecialRequests(String requests) {
    if (_specialRequests != requests) {
      _specialRequests = requests;
      notifyListeners();
      debugPrint('CheckoutProvider: Updated special requests');
    }
  }

  /// Toggle price breakdown visibility
  void togglePriceBreakdown() {
    _showPriceBreakdown = !_showPriceBreakdown;
    notifyListeners();
    debugPrint('CheckoutProvider: Toggled price breakdown to ${_showPriceBreakdown ? 'visible' : 'hidden'}');
  }

  /// Process payment and create booking
  /// Uses BaseProvider's executeWithState for proper error handling
  Future<bool> processPayment() async {
    if (!isFormValid) {
      throw Exception('Invalid form data - cannot process payment');
    }

    final success = await executeWithStateForSuccess(() async {
      // Create booking request payload
      final bookingData = {
        'propertyId': _currentProperty!.propertyId,
        'startDate': _startDate!.toIso8601String(),
        'endDate': _endDate!.toIso8601String(),
        'numberOfGuests': _numberOfGuests,
        'totalPrice': _totalPrice,
        'paymentMethod': _selectedPaymentMethod,
        'specialRequests': _specialRequests.isNotEmpty ? _specialRequests : null,
        'isDailyRental': _isDailyRental,
      };

      // Process payment via API
      final booking = await api.postAndDecode(
        'bookings',
        bookingData,
        Booking.fromJson,
        authenticated: true,
      );

      debugPrint('CheckoutProvider: Payment processed successfully. Booking ID: ${booking.bookingId}');
      
      // Clear checkout session after successful payment
      _clearCheckoutSession();
    }, errorMessage: 'Failed to process payment');

    return success;
  }

  /// Calculate price breakdown for display
  Map<String, double> getPriceBreakdown() {
    return {
      'basePrice': basePrice,
      'serviceFee': serviceFee,
      'taxes': taxes,
      'cleaningFee': cleaningFee,
      'total': _totalPrice,
    };
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
      'guests': _numberOfGuests,
      'paymentMethod': _selectedPaymentMethod,
      'totalPrice': formatPrice(_totalPrice),
      'specialRequests': _specialRequests.isNotEmpty ? _specialRequests : null,
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
    _numberOfGuests = 1;
    _specialRequests = '';
    _showPriceBreakdown = false;
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
