import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_form_fields.dart';

class AddressInput extends StatefulWidget {
  final Address? initialAddress;
  final String? initialAddressString;
  final Function(Address?) onAddressSelected;
  final Function() onManualAddressChanged;
  final TextEditingController streetNameController;
  final TextEditingController streetNumberController;
  final TextEditingController cityController;
  final TextEditingController postalCodeController;
  final TextEditingController countryController;

  const AddressInput({
    super.key,
    this.initialAddress,
    this.initialAddressString,
    required this.onAddressSelected,
    required this.onManualAddressChanged,
    required this.streetNameController,
    required this.streetNumberController,
    required this.cityController,
    required this.postalCodeController,
    required this.countryController,
  });

  @override
  State<AddressInput> createState() => _AddressInputState();
}

class _AddressInputState extends State<AddressInput> {
  @override
  void initState() {
    super.initState();
    // Add listeners to manual controllers to signal changes
    widget.streetNameController.addListener(widget.onManualAddressChanged);
    widget.streetNumberController.addListener(widget.onManualAddressChanged);
    widget.cityController.addListener(widget.onManualAddressChanged);
    widget.postalCodeController.addListener(widget.onManualAddressChanged);
    widget.countryController.addListener(widget.onManualAddressChanged);
  }

  @override
  void dispose() {
    widget.streetNameController.removeListener(widget.onManualAddressChanged);
    widget.streetNumberController.removeListener(widget.onManualAddressChanged);
    widget.cityController.removeListener(widget.onManualAddressChanged);
    widget.postalCodeController.removeListener(widget.onManualAddressChanged);
    widget.countryController.removeListener(widget.onManualAddressChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // This is a placeholder for a more advanced address input.
    // We can add Google Places API search here later.
    return _buildManualAddressFields();
  }

  Widget _buildManualAddressFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Manual Entry', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropertyFormFields.buildRequiredTextField(
              controller: widget.streetNameController,
              labelText: 'Street Name',
              flex: 3,
            ),
            const SizedBox(width: 12),
            PropertyFormFields.buildTextField(
              controller: widget.streetNumberController,
              labelText: 'No.',
              flex: 1,
              validator: (_) => null,
            ),
          ],
        ),
        PropertyFormFields.buildSpacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropertyFormFields.buildRequiredTextField(
              controller: widget.cityController,
              labelText: 'City',
              flex: 2,
            ),
            const SizedBox(width: 12),
            PropertyFormFields.buildTextField(
              controller: widget.postalCodeController,
              labelText: 'Postal Code',
              flex: 1,
              validator: (_) => null,
            ),
          ],
        ),
        PropertyFormFields.buildSpacer(),
        PropertyFormFields.buildRequiredTextField(
          controller: widget.countryController,
          labelText: 'Country',
        ),
      ],
    );
  }
}
