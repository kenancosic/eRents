import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_form_provider.dart';
import 'package:e_rents_desktop/models/enums/renting_type.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_renting_type_dropdown.dart';

/// Atomic widget for property pricing configuration.
class PricingSection extends StatefulWidget {
  const PricingSection({super.key});

  @override
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  late TextEditingController _priceController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = context.read<PropertyFormProvider>();
      _priceController.text = provider.state.price > 0 
          ? provider.state.price.toStringAsFixed(2) 
          : '';
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pricing', style: theme.textTheme.titleMedium),
        const SizedBox(height: 16),
        
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Price field
            Expanded(
              flex: 2,
              child: Selector<PropertyFormProvider, String?>(
                selector: (_, p) => p.getFieldError('price'),
                builder: (context, error, _) {
                  return TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: 'Price *',
                      border: const OutlineInputBorder(),
                      prefixText: '\$ ',
                      errorText: error,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                    ],
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      context.read<PropertyFormProvider>().updatePrice(price);
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Price is required';
                      }
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) {
                        return 'Price must be greater than 0';
                      }
                      return null;
                    },
                  );
                },
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Renting type dropdown
            Expanded(
              flex: 2,
              child: Selector<PropertyFormProvider, RentingType>(
                selector: (_, p) => p.state.rentingType,
                builder: (context, rentingType, _) {
                  return PropertyRentingTypeDropdown(
                    selected: rentingType,
                    onChanged: (value) {
                      context.read<PropertyFormProvider>().updateRentingType(value);
                    },
                  );
                },
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Helper text based on renting type
        Selector<PropertyFormProvider, RentingType>(
          selector: (_, p) => p.state.rentingType,
          builder: (context, rentingType, _) {
            final text = rentingType == RentingType.daily
                ? 'Price per night for short-term rentals'
                : 'Monthly rent for long-term leases';
            return Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
      ],
    );
  }
}
