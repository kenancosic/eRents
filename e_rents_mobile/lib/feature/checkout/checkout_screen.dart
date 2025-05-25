// lib/feature/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';

class CheckoutScreen extends StatefulWidget {
  final Property property;
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
  String _selectedPaymentMethod = 'PayPal';
  // Define the accent color as a constant for consistency
  static const Color accentColor = Color(0xFF7265F0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Advance Payment',
          style: TextStyle(
            color: accentColor, // Use the accent color for the title
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: accentColor, // Use accent color for back button
        iconTheme: const IconThemeData(
            color: accentColor), // Ensure back icon uses accent color
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Property card using the existing PropertyCard widget
              PropertyCard(
                property: widget.property,
              ),
              const SizedBox(height: 24),
              // Price details section
              _buildPriceDetails(),
              const SizedBox(height: 24),
              // Payment methods section
              _buildPaymentMethods(),
              const SizedBox(height: 32),
              // Pay button
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  isLoading: false,
                  onPressed: _processPayment,
                  label: const Text(
                    'Pay in Advance',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor:
                      accentColor, // Use the accent color for the button
                  height: 56,
                  borderRadius: 28,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPriceDetails() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Price details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CustomOutlinedButton.compact(
                label: 'More info',
                isLoading: false,
                width: OutlinedButtonWidth.content,
                textColor: accentColor,
                borderColor: accentColor,
                onPressed: () {
                  // Show detailed price breakdown
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total price',
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
              Text(
                '\$${widget.totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: accentColor, // Use accent color for price
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods() {
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

          // Payment methods list
          _buildPaymentOption(
            'Debit card',
            Icons.credit_card,
            'Accepting Visa, Mastercard, etc',
            isSelected: _selectedPaymentMethod == 'Debit card',
          ),

          const Divider(height: 1),

          _buildPaymentOption(
            'Google Pay',
            Icons.account_balance_wallet,
            '',
            icon: const Icon(Icons.g_mobiledata, size: 24, color: Colors.blue),
            isSelected: _selectedPaymentMethod == 'Google Pay',
          ),

          const Divider(height: 1),

          _buildPaymentOption(
            'Apple Pay',
            Icons.account_balance_wallet,
            '',
            icon: const Icon(Icons.apple, size: 24, color: Colors.black),
            isSelected: _selectedPaymentMethod == 'Apple Pay',
          ),

          const Divider(height: 1),

          _buildPaymentOption(
            'PayPal',
            Icons.account_balance_wallet,
            '',
            icon: SvgPicture.asset(
              'assets/icons/paypal-icon.svg',
              width: 24,
              height: 24,
            ),
            isSelected: _selectedPaymentMethod == 'PayPal',
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(
      String title, IconData defaultIcon, String subtitle,
      {Widget? icon, bool isSelected = false}) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = title;
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            // Payment method icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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

            // Add payment method button or selected indicator
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? accentColor // Use accent color for selected border
                      : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check,
                      size: 18,
                      color: accentColor) // Use accent color for check icon
                  : const Icon(Icons.add, size: 18, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                  accentColor), // Use accent color for loading indicator
            ),
            const SizedBox(height: 16),
            const Text('Processing payment...'),
          ],
        ),
      ),
    );

    // Simulate payment processing
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.pop(); // Close loading dialog
      }

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Payment Successful'),
          content: const Text(
              'Your booking has been confirmed. You will receive a confirmation email shortly.'),
          actions: [
            CustomButton.compact(
              label: 'OK',
              isLoading: false,
              onPressed: () {
                context.pop(); // Close dialog
                context
                    .pop(); // Go back to property details (assuming it's the previous route)
              },
            ),
          ],
        ),
      );
    });
  }
}
