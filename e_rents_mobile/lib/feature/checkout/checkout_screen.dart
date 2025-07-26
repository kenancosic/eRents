// lib/feature/checkout/checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/widgets/custom_outlined_button.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/feature/checkout/providers/checkout_provider.dart';
import 'package:flutter_svg/svg.dart';


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
  late final TextEditingController _specialRequestsController;
  
  // Define the accent color as a constant for consistency
  static const Color accentColor = Color(0xFF7265F0);

  @override
  void initState() {
    super.initState();
    _specialRequestsController = TextEditingController();
    
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
    _specialRequestsController.dispose();
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
                  // Property card using the existing PropertyCard widget
                  PropertyCard(
                    property: widget.property,
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
                              provider.error ?? 'Payment failed. Please try again.',
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                provider.showPriceBreakdown ? 'Hide details' : 'Show details',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              CustomOutlinedButton.compact(
                label: provider.showPriceBreakdown ? 'Less info' : 'More info',
                isLoading: false,
                width: OutlinedButtonWidth.content,
                textColor: accentColor,
                borderColor: accentColor,
                onPressed: () {
                  provider.togglePriceBreakdown();
                },
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Price breakdown (expandable)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: provider.showPriceBreakdown ? null : 0,
            child: provider.showPriceBreakdown ? _buildExpandedPriceBreakdown(provider) : null,
          ),

          // Total price (always visible)
          Container(
            margin: EdgeInsets.only(top: provider.showPriceBreakdown ? 16 : 0),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.withAlpha((255 * 0.3).round()),
                  width: 1,
                ),
              ),
            ),
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
                  '\$${widget.totalPrice.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 16,
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

  Widget _buildExpandedPriceBreakdown(CheckoutProvider provider) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildPriceRow(
          '\$${(provider.basePrice / provider.nights).toStringAsFixed(0)} × ${provider.nights} night${provider.nights > 1 ? 's' : ''}',
          provider.basePrice,
        ),
        _buildPriceRow('Cleaning fee', provider.cleaningFee),
        _buildPriceRow('Service fee', provider.serviceFee),
        _buildPriceRow('Taxes', provider.taxes),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
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

          // Number of guests selector
          Row(
            children: [
              Icon(Icons.group, color: Colors.grey[600]),
              const SizedBox(width: 8),
              const Text(
                'Number of guests',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: provider.numberOfGuests > 1
                          ? () => provider.updateNumberOfGuests(provider.numberOfGuests - 1)
                          : null,
                      icon: const Icon(Icons.remove),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '${provider.numberOfGuests}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      onPressed: provider.numberOfGuests < 10
                          ? () => provider.updateNumberOfGuests(provider.numberOfGuests + 1)
                          : null,
                      icon: const Icon(Icons.add),
                      constraints:
                          const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Special requests field
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.note_alt, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  const Text(
                    'Special requests (optional)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _specialRequestsController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText:
                      'Any special requests or preferences for your stay...',
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: accentColor),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
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
    try {
      // Store navigator to avoid async context usage issues  
      final navigator = context;

      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
              const SizedBox(height: 16),
              const Text('Processing payment...'),
            ],
          ),
        ),
      );

      // Process payment using provider
      final success = await provider.processPayment();

      if (!mounted) return;

      // Close loading dialog
      navigator.pop();

      if (success) {
        // Show success dialog
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Payment Successful'),
            content: const Text(
                'Your booking has been confirmed. You will receive a confirmation email shortly.'),
            actions: [
              CustomButton.compact(
                label: 'OK',
                isLoading: false,
                onPressed: () {
                  dialogContext.pop(); // Close dialog
                  context.pop(); // Go back to property details
                },
              ),
            ],
          ),
        );
      } else {
        // Show error message (provider will handle state)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.error ?? 'Payment failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      // Close loading dialog
      context.pop();
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
