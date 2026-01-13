// lib/feature/checkout/checkout_screen.dart
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/section_container.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/features/checkout/providers/checkout_provider.dart';
import 'package:e_rents_mobile/features/checkout/widgets/payment_loading_modal.dart';
import 'package:e_rents_mobile/features/checkout/widgets/payment_success_modal.dart';
import 'package:e_rents_mobile/features/checkout/widgets/trust_signals.dart';
import 'package:e_rents_mobile/features/home/providers/home_provider.dart';
import 'package:e_rents_mobile/features/profile/providers/user_bookings_provider.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';
// Stripe payment processing - Flutter Stripe SDK
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;


class CheckoutScreen extends StatefulWidget {
  final PropertyDetail property;
  final DateTime startDate;
  final DateTime endDate;
  final bool isDailyRental;
  final double totalPrice;

  const CheckoutScreen({
    super.key,
    required this.property,
    required this.startDate,
    required this.endDate,
    required this.isDailyRental,
    required this.totalPrice,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  
  // Define the accent color as a constant for consistency
  static const Color accentColor = Color(0xFF7265F0);
  
  // Payment processing guard
  bool _isProcessingPayment = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize checkout provider with widget data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CheckoutProvider>().initializeCheckout(
        property: widget.property,
        startDate: widget.startDate,
        endDate: widget.endDate,
        isDailyRental: widget.isDailyRental,
        totalPrice: widget.totalPrice,
      );
    });
  }

  Future<void> _submitMonthlyRequest(CheckoutProvider provider) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accentColor)),
            SizedBox(height: 16),
            Text('Submitting request...'),
          ],
        ),
      ),
    );

    bool ok = false;
    try {
      ok = await provider.submitTenantRequest();
    } catch (_) {}

    if (!mounted) return;
    context.pop();

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent. The landlord will review your request.')),
      );
      _showSuccessDialog(false);
    } else {
      _showErrorSnackBar(provider.errorMessage.isNotEmpty
          ? provider.errorMessage
          : 'Failed to submit request. Please try again.');
    }
  }
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Checkout',
      showBackButton: true,
    );

    return BaseScreen(
      appBar: appBar,
      body: Consumer<CheckoutProvider>(
        builder: (context, provider, child) {
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Compact booking summary instead of full property card
                  _buildCompactSummary(provider),
                  const SizedBox(height: 24),
                  // Price details section
                  _buildPriceDetails(provider),
                  const SizedBox(height: 24),
                  // Booking details section
                  _buildBookingDetails(provider),
                  const SizedBox(height: 24),
                  // Payment methods section (daily rentals only)
                  if (provider.isDailyRental) _buildPaymentMethods(provider),
                  const SizedBox(height: 16),
                  // Trust signals
                  if (provider.isDailyRental) const TrustSignals(),
                  const SizedBox(height: 32),
                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      isLoading: provider.isLoading,
                      onPressed: provider.isLoading
                          ? null
                          : () {
                              if (provider.isDailyRental) {
                                _processPayment(provider);
                              } else {
                                _submitMonthlyRequest(provider);
                              }
                            },
                      label: Text(
                        provider.isLoading
                            ? 'Processing...'
                            : (provider.isDailyRental ? 'Pay and Book' : 'Send Request'),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      height: 56,
                    ),
                  ),
                  // Show error message if payment fails
                  if (provider.hasError) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              provider.errorMessage.isNotEmpty
                                ? provider.errorMessage
                                : 'Payment failed. Please try again.',
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCompactSummary(CheckoutProvider provider) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          // Property image with hero effect
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha((255 * 0.1).round()),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: widget.property.coverImageId != null
                  ? Image.network(
                      context.read<ApiService>().makeAbsoluteUrl('/api/Images/${widget.property.coverImageId}/content'),
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[200],
                        child: Icon(Icons.home_work, size: 40, color: Colors.grey[400]),
                      ),
                    )
                  : Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: Icon(Icons.home_work, size: 40, color: Colors.grey[400]),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          // Property details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.property.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${provider.startDate?.day}/${provider.startDate?.month}/${provider.startDate?.year} - '
                        '${provider.endDate?.day}/${provider.endDate?.month}/${provider.endDate?.year}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${provider.propertyPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceDetails(CheckoutProvider provider) {
    return SectionCard(
      title: 'Total price',
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Large total price display
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: accentColor.withAlpha((255 * 0.08).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                '\$${provider.propertyPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Pricing note with icon
          Row(
            children: [
              Icon(
                provider.isDailyRental ? Icons.event_repeat : Icons.subscriptions_outlined,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  provider.isDailyRental
                      ? 'Pricing model: billed per night'
                      : 'Pricing model: billed monthly (subscription)',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(CheckoutProvider provider) {
    final daysDifference = provider.endDate?.difference(provider.startDate ?? DateTime.now()).inDays ?? 0;
    
    return SectionCard(
      title: 'Booking Details',
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // Dates row with improved styling
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withAlpha((255 * 0.1).round()),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.calendar_month,
                    color: accentColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dates',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${provider.startDate?.day}/${provider.startDate?.month}/${provider.startDate?.year} - '
                        '${provider.endDate?.day}/${provider.endDate?.month}/${provider.endDate?.year}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (daysDifference > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.nights_stay_outlined, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '$daysDifference ${daysDifference == 1 ? "night" : "nights"}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(CheckoutProvider provider) {
    // Stripe payment UI
    return SectionCard(
      padding: const EdgeInsets.all(16),
      margin: EdgeInsets.zero,
      child: Row(
        children: [
          // Stripe logo styled container
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withAlpha((255 * 0.1).round()),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.payment, color: accentColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Stripe',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Secure payment',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          Icon(Icons.lock_outline, color: Colors.grey[400], size: 20),
        ],
      ),
    );
  }
  // Payment method selection removed - Stripe is the only option

  Future<void> _processPayment(CheckoutProvider provider) async {
    // Prevent duplicate payment processing
    if (_isProcessingPayment) return;
    _isProcessingPayment = true;

    try {
      // Stripe payment flow
      // Step 1: Create Stripe payment intent
      PaymentLoadingModal.showCreatingIntent(context);

      Map<String, String> paymentIntent;
      try {
        paymentIntent = await provider.createStripePaymentIntent();
      } catch (_) {
        if (!mounted) return;
        context.pop();
        return;
      }

      if (!mounted) return;
      context.pop(); // Close preparing dialog

      // Step 2: Initialize and present Stripe payment sheet
      await _initializeAndPresentPaymentSheet(
        clientSecret: paymentIntent['clientSecret']!,
        provider: provider,
      );
    } finally {
      _isProcessingPayment = false;
    }
  }

  /// Initialize and present Stripe payment sheet
  Future<void> _initializeAndPresentPaymentSheet({
    required String clientSecret,
    required CheckoutProvider provider,
  }) async {
    try {
      // Initialize Stripe payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'eRents',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.system,
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: accentColor,
            ),
          ),
          billingDetailsCollectionConfiguration: const BillingDetailsCollectionConfiguration(
            email: CollectionMode.always,
            phone: CollectionMode.always,
            name: CollectionMode.always,
            address: AddressCollectionMode.full,
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      _showPaymentSuccess(provider);

    } catch (e) {
      // Handle Stripe-specific errors
      if (!mounted) return;

      // Handle StripeException
      if (e is StripeException) {
        if (e.error.code == FailureCode.Canceled) {
          _showCancelledMessage();
          return;
        }
      }

      _showPaymentError(e.toString());
    }
  }

  void _showPaymentSuccess(CheckoutProvider provider) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PaymentSuccessModal(
        bookingId: provider.pendingBookingId?.toString(),
        onViewBooking: () {
          dialogContext.pop();
          // Refresh home and bookings data so new booking appears immediately
          final currentUserProvider = context.read<CurrentUserProvider>();
          context.read<HomeProvider>().refreshDashboard(currentUserProvider);
          context.read<UserBookingsProvider>().loadUserBookings(forceRefresh: true, currentUserProvider: currentUserProvider);
          context.go('/bookings?tab=0'); // Navigate to upcoming bookings
        },
      ),
    );
  }

  void _showPaymentError(String error) {
    // Error is already displayed via provider.hasError in the UI
    // Show additional snackbar for immediate feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            _processPayment(context.read<CheckoutProvider>());
          },
        ),
      ),
    );
  }

  void _showCancelledMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payment cancelled. Your booking was not confirmed.'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showSuccessDialog(bool isDailyRental) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Payment Successful'),
        content: Text(
          isDailyRental
              ? 'Your booking has been confirmed. You will receive a confirmation email shortly.'
              : 'Your lease application has been submitted. You\'ll be notified when the landlord reviews and accepts your request.',
        ),
        actions: [
          CustomButton.compact(
            label: 'OK',
            isLoading: false,
            onPressed: () {
              Navigator.of(dialogContext).pop(); // Close dialog
              // Refresh home and bookings data so new booking/request appears immediately
              final currentUserProvider = context.read<CurrentUserProvider>();
              context.read<HomeProvider>().refreshDashboard(currentUserProvider);
              context.read<UserBookingsProvider>().loadUserBookings(forceRefresh: true, currentUserProvider: currentUserProvider);
              context.go('/'); // Navigate to home
            },
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
