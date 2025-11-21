// lib/feature/checkout/checkout_screen.dart
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/features/checkout/providers/checkout_provider.dart';
// Stripe payment processing - Native Stripe SDK to be integrated


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
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Property image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: widget.property.coverImageId != null
                  ? Image.network(
                      context.read<ApiService>().makeAbsoluteUrl('/api/Images/${widget.property.coverImageId}/content'),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 80,
                      height: 80,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${provider.startDate?.day}/${provider.startDate?.month}/${provider.startDate?.year} - '
                    '${provider.endDate?.day}/${provider.endDate?.month}/${provider.endDate?.year}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${provider.propertyPrice.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceDetails(CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Simplified price display - only show total price
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total price',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '\$${provider.propertyPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          // Fixed pricing note: per-night or monthly subscription
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              provider.isDailyRental
                  ? 'Pricing model: billed per night'
                  : 'Pricing model: billed monthly (subscription)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingDetails(CheckoutProvider provider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((255 * 0.05).round()),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Booking Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Dates overview only (guests and special requests removed)
          Row(
            children: [
              Icon(Icons.calendar_today, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Dates',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                '${provider.startDate?.day}/${provider.startDate?.month}/${provider.startDate?.year} - '
                '${provider.endDate?.day}/${provider.endDate?.month}/${provider.endDate?.year}',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(CheckoutProvider provider) {
    // Minimal payment badge - no marketing copy
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.payment, color: accentColor, size: 24),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stripe',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Secure payment',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const Spacer(),
          Icon(Icons.lock_outline, color: Colors.grey[600], size: 20),
        ],
      ),
    );
  }

  // Payment method selection removed - Stripe is the only option

  Future<void> _processPayment(CheckoutProvider provider) async {
    // Step 1: Create Stripe payment intent
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accentColor)),
            SizedBox(height: 16),
            Text('Preparing secure payment...'),
          ],
        ),
      ),
    );

    Map<String, String> paymentIntent;
    try {
      paymentIntent = await provider.createStripePaymentIntent();
    } catch (_) {
      if (!mounted) return;
      context.pop();
      _showErrorSnackBar(provider.errorMessage.isNotEmpty
          ? provider.errorMessage
          : 'Failed to initialize payment.');
      return;
    }

    if (!mounted) return;
    context.pop(); // Close preparing dialog

    // TODO: Step 2: Integrate Stripe SDK to present payment sheet
    // For now, show a placeholder dialog indicating Stripe integration is pending
    _showStripePlaceholderDialog(paymentIntent['clientSecret']!);
  }

  void _showStripePlaceholderDialog(String clientSecret) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Stripe Integration Pending'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Payment intent created successfully!'),
            const SizedBox(height: 12),
            const Text(
              'Next steps:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text('• Integrate Stripe Flutter SDK\n'
                '• Present payment sheet\n'
                '• Confirm payment'),
            const SizedBox(height: 12),
            Text(
              'Client Secret: ${clientSecret.substring(0, 20)}...',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          CustomButton.compact(
            label: 'OK',
            isLoading: false,
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.go('/home');
            },
          ),
        ],
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
              context.go('/home'); // Navigate to home or another appropriate screen
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
