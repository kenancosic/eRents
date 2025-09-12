// lib/feature/property_detail/widgets/property_price_footer.dart
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';

class PropertyPriceFooter extends StatelessWidget {
  final PropertyDetail property;
  final VoidCallback onCheckoutPressed;

  const PropertyPriceFooter({
    super.key,
    required this.property,
    required this.onCheckoutPressed,
  });

  @override
  Widget build(BuildContext context) {
    final isDaily = property.rentalType == PropertyRentalType.daily;
    final priceAmount = isDaily ? (property.dailyRate ?? property.price) : property.price;
    final suffix = isDaily ? '/day' : '/month';
    final currency = property.currency.isNotEmpty ? ' ${property.currency}' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${priceAmount.toStringAsFixed(0)}$currency $suffix',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                  ),
                  Text(
                    isDaily ? 'Flexible daily booking' : 'All bills included',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey,
                        ),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: 120,
                child: CustomButton(
                  isLoading: false,
                  onPressed: onCheckoutPressed,
                  label: Text(
                    isDaily ? 'Book Now' : 'Start Lease',
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
