import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/properties/state/property_form_state.dart';
import 'package:e_rents_desktop/features/properties/providers/property_collection_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_detail_provider.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_form_fields.dart';
import 'package:e_rents_desktop/models/lookup_data.dart';
import 'package:e_rents_desktop/models/property.dart';

import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/widgets/amenity_manager.dart';
import 'package:e_rents_desktop/widgets/common/section_card.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/widgets/common/section_header.dart';
import 'package:e_rents_desktop/widgets/inputs/custom_dropdown.dart';
import 'package:e_rents_desktop/widgets/inputs/address_input.dart';
import 'package:e_rents_desktop/services/property_service.dart';
import 'dart:typed_data';

class PropertyFormScreen extends StatelessWidget {
  final Property? property;

  const PropertyFormScreen({super.key, this.property});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create:
          (context) => PropertyFormState(
            lookupProvider: context.read<LookupProvider>(),
            propertyService: context.read<PropertyService>(),
            authProvider: context.read<AuthProvider>(),
            collectionProvider: context.read<PropertyCollectionProvider>(),
            initialProperty: property,
          ),
      child: _PropertyFormScreenContent(isEditMode: property != null),
    );
  }
}

class _PropertyFormScreenContent extends StatefulWidget {
  final bool isEditMode;

  const _PropertyFormScreenContent({required this.isEditMode});

  @override
  State<_PropertyFormScreenContent> createState() =>
      _PropertyFormScreenContentState();
}

class _PropertyFormScreenContentState
    extends State<_PropertyFormScreenContent> {
  Future<void> _saveProperty() async {
    final formState = context.read<PropertyFormState>();
    // No need to check form validity here, it's done in saveProperty()

    final success = await formState.saveProperty();

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Property updated successfully!'
                  : 'Property created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              formState.errorMessage ?? 'An unknown error occurred.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formState = context.watch<PropertyFormState>();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditMode ? 'Edit Property' : 'Add New Property'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save_outlined),
              onPressed: formState.isLoading ? null : _saveProperty,
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body:
          formState.isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: formState.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBasicInfoSection(theme, formState),
                        PropertyFormFields.buildSpacer(),
                        _buildDetailsSection(theme, formState),
                        PropertyFormFields.buildSpacer(),
                        _buildAddressSection(theme, formState),
                        PropertyFormFields.buildSpacer(),
                        _buildImagesSection(theme, formState),
                        PropertyFormFields.buildSpacer(),
                        _buildAmenitiesSection(theme, formState),
                      ],
                    ),
                  ),
                ),
              ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme, PropertyFormState formState) {
    return SectionCard(
      title: 'Basic Information',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyFormFields.buildRequiredTextField(
            controller: formState.nameController,
            labelText: 'Property Name',
          ),
          PropertyFormFields.buildSpacer(),
          PropertyFormFields.buildTextField(
            controller: formState.descriptionController,
            labelText: 'Description',
            maxLines: 4,
            validator: (_) => null, // Optional field
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme, PropertyFormState formState) {
    final lookup = context.watch<LookupProvider>();

    return SectionCard(
      title: 'Property Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PropertyFormFields.buildRequiredTextField(
                controller: formState.priceController,
                labelText: 'Price',
                keyboardType: TextInputType.number,
                flex: 1,
              ),
              const SizedBox(width: 12),
              PropertyFormFields.buildRequiredTextField(
                controller: formState.currencyController,
                labelText: 'Currency',
                flex: 1,
              ),
            ],
          ),
          PropertyFormFields.buildSpacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PropertyFormFields.buildNumberField(
                controller: formState.bedroomsController,
                labelText: 'Bedrooms',
                errorMessage: 'Enter beds',
              ),
              const SizedBox(width: 12),
              PropertyFormFields.buildNumberField(
                controller: formState.bathroomsController,
                labelText: 'Bathrooms',
                errorMessage: 'Enter baths',
              ),
            ],
          ),
          PropertyFormFields.buildSpacer(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PropertyFormFields.buildDecimalField(
                controller: formState.areaController,
                labelText: 'Area',
                suffixText: 'm²',
                errorMessage: 'Enter area',
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PropertyFormFields.buildTextField(
                  controller: formState.minimumStayDaysController,
                  labelText: 'Min. Stay',
                  suffixText: 'days',
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null &&
                        value.isNotEmpty &&
                        int.tryParse(value) == null) {
                      return 'Invalid number';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          PropertyFormFields.buildSpacer(),
          Row(
            children: [
              Expanded(
                child: CustomDropdown<int>(
                  label: 'Property Type',
                  value: formState.property.propertyTypeId,
                  items: lookup.propertyTypes,
                  onChanged: (val) => formState.setPropertyTypeId(val),
                  itemToString: (item) => (item as LookupItem).name,
                  itemToValue: (item) => (item as LookupItem).id,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomDropdown<int>(
                  label: 'Renting Type',
                  value: formState.property.rentingTypeId,
                  items: lookup.rentingTypes,
                  onChanged: (val) => formState.setRentingTypeId(val),
                  itemToString: (item) => (item as LookupItem).name,
                  itemToValue: (item) => (item as LookupItem).id,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(ThemeData theme, PropertyFormState formState) {
    return SectionCard(
      title: 'Location & Address',
      child: AddressInput(
        initialAddress: formState.property.address,
        initialAddressString: formState.initialAddressString,
        onAddressSelected: formState.updateAddressFromGoogle,
        streetNameController: formState.streetNameController,
        streetNumberController: formState.streetNumberController,
        cityController: formState.cityController,
        postalCodeController: formState.postalCodeController,
        countryController: formState.countryController,
        onManualAddressChanged: () {},
      ),
    );
  }

  Widget _buildImagesSection(ThemeData theme, PropertyFormState formState) {
    return SectionCard(
      title: 'Property Images',
      child: ImagePickerInput(
        initialImages: formState.images,
        onChanged: (images) {
          formState.setImages(images);
        },
      ),
    );
  }

  Widget _buildAmenitiesSection(ThemeData theme, PropertyFormState formState) {
    return SectionCard(
      title: 'Amenities',
      child: AmenityManager(
        mode: AmenityManagerMode.select,
        initialAmenityIds: formState.property.amenityIds,
        onAmenityIdsChanged: (ids) {
          formState.setAmenityIds(ids);
        },
        showTitle: false, // We have a SectionCard title now
      ),
    );
  }
}
