import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_form_provider.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/widgets/inputs/address_input.dart';

/// Atomic widget for property address management.
/// Wraps AddressInput and connects it to PropertyFormProvider.
class AddressSection extends StatefulWidget {
  const AddressSection({super.key});

  @override
  State<AddressSection> createState() => _AddressSectionState();
}

class _AddressSectionState extends State<AddressSection> {
  late TextEditingController _streetNameController;
  late TextEditingController _streetNumberController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  Address? _lastAddress;

  @override
  void initState() {
    super.initState();
    _streetNameController = TextEditingController();
    _streetNumberController = TextEditingController();
    _cityController = TextEditingController();
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllersWithProvider();
  }

  void _syncControllersWithProvider() {
    final address = context.read<PropertyFormProvider>().state.address;
    debugPrint('AddressSection: Syncing controllers - provider address: ${address?.streetLine1}, ${address?.city}');
    // Only update if address changed to avoid loops
    if (_lastAddress == address) return;
    _lastAddress = address;
    
    if (address != null) {
      // Only set text if different to avoid triggering controller listeners
      if (_streetNameController.text != (address.streetLine1 ?? '')) {
        _streetNameController.text = address.streetLine1 ?? '';
      }
      if (_streetNumberController.text != (address.streetLine2 ?? '')) {
        _streetNumberController.text = address.streetLine2 ?? '';
      }
      if (_cityController.text != (address.city ?? '')) {
        _cityController.text = address.city ?? '';
      }
      if (_postalCodeController.text != (address.postalCode ?? '')) {
        _postalCodeController.text = address.postalCode ?? '';
      }
      if (_countryController.text != (address.country ?? '')) {
        _countryController.text = address.country ?? '';
      }
      debugPrint('AddressSection: Controllers synced - streetName: ${_streetNameController.text}, city: ${_cityController.text}');
    } else {
      debugPrint('AddressSection: Address is null, clearing controllers');
    }
  }

  @override
  void dispose() {
    _streetNameController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  void _onAddressSelected(Address? address) {
    debugPrint('AddressSection: Address selected - ${address?.streetLine1}, ${address?.city}');
    context.read<PropertyFormProvider>().updateAddress(address);
  }

  void _onManualAddressChanged() {
    final address = Address(
      streetLine1: _streetNameController.text.trim().isNotEmpty 
          ? _streetNameController.text.trim() 
          : null,
      streetLine2: _streetNumberController.text.trim().isNotEmpty 
          ? _streetNumberController.text.trim() 
          : null,
      city: _cityController.text.trim().isNotEmpty 
          ? _cityController.text.trim() 
          : null,
      postalCode: _postalCodeController.text.trim().isNotEmpty 
          ? _postalCodeController.text.trim() 
          : null,
      country: _countryController.text.trim().isNotEmpty 
          ? _countryController.text.trim() 
          : null,
    );
    debugPrint('AddressSection: Manual address changed - ${address.streetLine1}, ${address.city}');
    context.read<PropertyFormProvider>().updateAddress(address);
  }

  @override
  Widget build(BuildContext context) {
    return Selector<PropertyFormProvider, Address?>(
      selector: (_, p) => p.state.address,
      builder: (context, address, _) {
        // Sync controllers whenever address changes in provider
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _syncControllersWithProvider();
        });
        
        final error = context.read<PropertyFormProvider>().getFieldError('address');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AddressInput(
              initialAddress: address,
              onAddressSelected: _onAddressSelected,
              onManualAddressChanged: _onManualAddressChanged,
              streetNameController: _streetNameController,
              streetNumberController: _streetNumberController,
              cityController: _cityController,
              postalCodeController: _postalCodeController,
              countryController: _countryController,
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
