import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_form_fields.dart';
import 'package:e_rents_desktop/services/google_places_service.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final _placesService = GooglePlacesService();
  List<AutocompletePrediction> _predictions = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add listeners to manual controllers to signal changes
    widget.streetNameController.addListener(widget.onManualAddressChanged);
    widget.streetNumberController.addListener(widget.onManualAddressChanged);
    widget.cityController.addListener(widget.onManualAddressChanged);
    widget.postalCodeController.addListener(widget.onManualAddressChanged);
    widget.countryController.addListener(widget.onManualAddressChanged);

    // Initialize with initial address if provided
    if (widget.initialAddress != null) {
      _searchController.text = _formatAddressForSearch(widget.initialAddress!);
    } else if (widget.initialAddressString != null) {
      _searchController.text = widget.initialAddressString!;
    }
  }

  @override
  void dispose() {
    widget.streetNameController.removeListener(widget.onManualAddressChanged);
    widget.streetNumberController.removeListener(widget.onManualAddressChanged);
    widget.cityController.removeListener(widget.onManualAddressChanged);
    widget.postalCodeController.removeListener(widget.onManualAddressChanged);
    widget.countryController.removeListener(widget.onManualAddressChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _formatAddressForSearch(Address address) {
    final parts = [
      address.streetLine1,
      address.streetLine2,
      address.city,
      address.state,
      address.country,
      address.postalCode,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }

  Future<void> _searchPlaces(String input) async {
    if (input.isEmpty) {
      setState(() => _predictions = []);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await _placesService.getAutocompleteSuggestions(input);
      setState(() {
        _predictions = result;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      print('Error searching places: $e');
    }
  }

  Future<void> _selectPlace(AutocompletePrediction prediction) async {
    final Place? details = await _placesService.getPlaceDetails(prediction.placeId);
    if (details != null) {
      _fillAddressFromPlaceDetails(details);
      widget.onAddressSelected(_buildAddressFromFields());
      setState(() {
        _searchController.clear();
        _predictions = [];
      });
    }
  }

  void _fillAddressFromPlaceDetails(Place details) {
    // Clear all fields first
    widget.streetNameController.clear();
    widget.streetNumberController.clear();
    widget.cityController.clear();
    widget.postalCodeController.clear();
    widget.countryController.clear();

    // Fill the controllers from the details model
    final streetName = details.addressComponents?.firstWhere((c) => c.types.contains('route'), orElse: () => AddressComponent(name: '', shortName: '', types: [])).name ?? '';
    final streetNumber = details.addressComponents?.firstWhere((c) => c.types.contains('street_number'), orElse: () => AddressComponent(name: '', shortName: '', types: [])).name ?? '';
    final city = details.addressComponents?.firstWhere((c) => c.types.contains('locality'), orElse: () => AddressComponent(name: '', shortName: '', types: [])).name ?? '';
    final postalCode = details.addressComponents?.firstWhere((c) => c.types.contains('postal_code'), orElse: () => AddressComponent(name: '', shortName: '', types: [])).name ?? '';
    final country = details.addressComponents?.firstWhere((c) => c.types.contains('country'), orElse: () => AddressComponent(name: '', shortName: '', types: [])).name ?? '';

    widget.streetNameController.text = streetName;
    widget.streetNumberController.text = streetNumber;
    widget.cityController.text = city;
    widget.postalCodeController.text = postalCode;
    widget.countryController.text = country;
  }

  Address _buildAddressFromFields() {
    return Address(
      streetLine1: widget.streetNameController.text.trim().isNotEmpty ? widget.streetNameController.text.trim() : null,
      streetLine2: widget.streetNumberController.text.trim().isNotEmpty ? widget.streetNumberController.text.trim() : null,
      city: widget.cityController.text.trim().isNotEmpty ? widget.cityController.text.trim() : null,
      state: null, // Not collected in form
      country: widget.countryController.text.trim().isNotEmpty ? widget.countryController.text.trim() : null,
      postalCode: widget.postalCodeController.text.trim().isNotEmpty ? widget.postalCodeController.text.trim() : null,
      latitude: null, // Will be set by backend
      longitude: null, // Will be set by backend
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Address', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        // Google Places search field
        TextFormField(
          controller: _searchController,
          decoration: InputDecoration(
            labelText: 'Search Address',
            hintText: 'Start typing an address...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
            border: const OutlineInputBorder(),
          ),
          onChanged: _searchPlaces,
        ),
        if (_predictions.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _predictions.length,
              itemBuilder: (context, index) {
                final prediction = _predictions[index];
                return ListTile(
                  title: Text(prediction.fullText),
                  dense: true,
                  onTap: () => _selectPlace(prediction),
                );
              },
            ),
          ),
        const SizedBox(height: 16),
        // Manual entry fields
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
