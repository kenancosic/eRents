// lib/feature/checkout/checkout_screen.dart
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/features/checkout/providers/checkout_provider.dart';
import 'package:flutter_svg/svg.dart';
import 'package:e_rents_mobile/features/checkout/paypal_webview_screen.dart';


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
  
  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = CustomAppBar(
      title: 'Advance Payment',
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
                  // Property card using the new PropertyCardModel
                  PropertyCard(
                    property: PropertyCardModel(
                      propertyId: widget.property.propertyId,
                      name: widget.property.name,
                      price: widget.property.price,
                      currency: widget.property.currency,
                      averageRating: widget.property.averageRating,
                      coverImageId: widget.property.coverImageId!,
                      address: widget.property.address,
                      rentalType: widget.property.rentalType,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Price details section
                  _buildPriceDetails(provider),
                  const SizedBox(height: 24),
                  // Booking details section
                  _buildBookingDetails(provider),
                  const SizedBox(height: 24),
                  // Payment methods section
                  _buildPaymentMethods(provider),
                  const SizedBox(height: 32),
                  // Pay button
                  SizedBox(
                    width: double.infinity,
                    child: CustomButton(
                      isLoading: provider.isLoading,
                      onPressed: provider.isLoading ? null : () { _processPayment(provider); },
                      label: Text(
                        provider.isLoading ? 'Processing...' : 'Pay in Advance',
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
            'Pay with',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Only PayPal payment option
          _buildPaymentOption(
            provider,
            'PayPal',
            Icons.account_balance_wallet,
            'Fast and secure payments',
            icon: SvgPicture.asset(
              'assets/icons/paypal-icon.svg',
              width: 24,
              height: 24,
            ),
            isSelected: provider.selectedPaymentMethod == 'PayPal',
          ),

          const SizedBox(height: 16),

          // PayPal benefits
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.security, color: Colors.blue[600], size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'PayPal Benefits',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '• Secure payment processing\n'
                  '• Buyer protection coverage\n'
                  '• No need to share card details',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      CheckoutProvider provider, String title, IconData defaultIcon, String subtitle,
      {Widget? icon, bool isSelected = false}) {
    return InkWell(
      onTap: () {
        provider.selectPaymentMethod(title);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                isSelected ? accentColor : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected
              ? accentColor.withValues(alpha: 0.05)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            // Payment method icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? accentColor.withValues(alpha: 0.1)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: icon ?? Icon(defaultIcon, color: Colors.grey.shade700),
            ),

            const SizedBox(width: 16),

            // Payment method details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? accentColor : Colors.black,
                    ),
                  ),
                  if (subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                ],
              ),
            ),

            // Selected indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? accentColor : Colors.grey.shade300,
                  width: 2,
                ),
                color: isSelected ? accentColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment(CheckoutProvider provider) async {
    // Show loading dialog for payment initiation
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accentColor)),
            SizedBox(height: 16),
            Text('Initiating payment...'),
          ],
        ),
      ),
    );

    final initiationSuccess = await provider.processPayment();

    if (!mounted) return;
    context.pop(); // Close loading dialog

    if (initiationSuccess && provider.payPalApprovalUrl != null) {
      // Navigate to PayPal WebView
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaypalWebViewScreen(approvalUrl: provider.payPalApprovalUrl!),
        ),
      );

      if (result == true) {
        // Show loading dialog for payment capture
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(accentColor)),
                SizedBox(height: 16),
                Text('Finalizing payment...'),
              ],
            ),
          ),
        );

        // Persist rental type flag before provider clears its state during capture
        final isDaily = provider.isDailyRental;
        final captureSuccess = await provider.capturePayPalOrder(provider.payPalOrderId!);
        if (!mounted) return;
        context.pop(); // Close loading dialog

        if (captureSuccess) {
          // For monthly rentals, show an immediate notification toast
          if (!isDaily) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Lease application submitted. You\'ll be notified when the landlord responds.'),
              ),
            );
          }
          _showSuccessDialog(isDaily);
        } else {
          _showErrorSnackBar('Failed to finalize payment. Please contact support.');
        }
      } else {
        _showErrorSnackBar('Payment was cancelled or failed.');
      }
    } else {
      // Show initiation error
      _showErrorSnackBar(provider.errorMessage.isNotEmpty
          ? provider.errorMessage
          : 'Failed to initiate PayPal payment.');
    }
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
