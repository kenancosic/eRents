import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/properties/models/property_form_state.dart';
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
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/widgets/common/section_header.dart';
import 'package:e_rents_desktop/widgets/inputs/custom_dropdown.dart';
import 'package:e_rents_desktop/widgets/inputs/address_input.dart';

class PropertyFormScreen extends StatelessWidget {
  final Property? property;

  const PropertyFormScreen({super.key, this.property});

  @override
  Widget build(BuildContext context) {
    // Using a simple key for the provider to ensure it's recreated
    // if we navigate to the form for a different property.
    final key = ValueKey(property?.propertyId ?? 'new');

    return ChangeNotifierProvider(
      key: key,
      create: (context) {
        final lookupProvider = context.read<LookupProvider>();
        final formState = PropertyFormState(lookupProvider: lookupProvider);
        if (property != null) {
          formState.populateFromProperty(property!);
        }
        return formState;
      },
      child: _PropertyFormScreenContent(
        isEditMode: property != null,
        initialProperty: property,
      ),
    );
  }
}

class _PropertyFormScreenContent extends StatefulWidget {
  final bool isEditMode;
  final Property? initialProperty;

  const _PropertyFormScreenContent({
    required this.isEditMode,
    this.initialProperty,
  });

  @override
  State<_PropertyFormScreenContent> createState() =>
      _PropertyFormScreenContentState();
}

class _PropertyFormScreenContentState
    extends State<_PropertyFormScreenContent> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _formKey.currentState!.save();
    setState(() => _isLoading = true);

    final formState = context.read<PropertyFormState>();
    final authProvider = context.read<AuthProvider>();
    final collectionProvider = context.read<PropertyCollectionProvider>();

    try {
      final user = authProvider.currentUser;
      if (user == null) {
        throw Exception('User not authenticated.');
      }
      final currentUserId = user.id;

      final propertyToSave = formState.createProperty(
        currentUserId,
        widget.initialProperty,
      );

      Property savedProperty;

      if (widget.isEditMode) {
        // For existing properties, upload images first
        final uploadedImageIds = await formState.uploadNewImages(
          propertyId: propertyToSave.propertyId,
        );

        // Update the property with all image IDs (existing + newly uploaded)
        final updatedProperty = propertyToSave.copyWith(
          imageIds: uploadedImageIds,
        );

        await collectionProvider.updateItem(
          updatedProperty.propertyId.toString(),
          updatedProperty,
        );
        savedProperty = updatedProperty;
      } else {
        // For new properties, create first, then upload images
        await collectionProvider.addItem(propertyToSave);

        // Find the newly created property in the collection
        // Note: This assumes the property was successfully created and added to the collection
        savedProperty =
            collectionProvider.items.isNotEmpty
                ? collectionProvider.items.last
                : propertyToSave;

        // Upload images after property creation if we have a valid property ID
        print(
          'PropertyFormScreen: Created property ID: ${savedProperty.propertyId}',
        );
        if (savedProperty.propertyId > 0) {
          final uploadedImageIds = await formState.uploadNewImages(
            propertyId: savedProperty.propertyId,
          );

          // Update the property with uploaded image IDs if any were uploaded
          if (uploadedImageIds.isNotEmpty) {
            print(
              'PropertyFormScreen: Updating property ${savedProperty.propertyId} with image IDs: $uploadedImageIds',
            );
            final updatedProperty = savedProperty.copyWith(
              imageIds: uploadedImageIds,
            );

            await collectionProvider.updateItem(
              updatedProperty.propertyId.toString(),
              updatedProperty,
            );
            savedProperty = updatedProperty;
          }
        }
      }

      // Show success message with upload status
      final totalImages = formState.images.length;
      final uploadedCount = formState.uploadedImageIds.length;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isEditMode
                  ? 'Property updated successfully! Images: $uploadedCount/$totalImages uploaded.'
                  : 'Property created successfully! Images: $uploadedCount/$totalImages uploaded.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Also update the detail provider if we are editing and it holds this item
      if (widget.isEditMode && mounted) {
        final detailProvider = context.read<PropertyDetailProvider>();
        if (detailProvider.property?.propertyId == propertyToSave.propertyId) {
          await detailProvider.forceReloadProperty();
        }

        // Clear collection provider cache to ensure list view shows updated data
        await collectionProvider.clearCacheAndRefresh();
      } else {
        // For new properties, just refresh the collection
        await collectionProvider.refreshItems();
      }

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save property: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
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
              onPressed: _isLoading ? null : _save,
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
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
            controller: formState.titleController,
            labelText: 'Property Title',
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
                  value: formState.propertyTypeId,
                  items: lookup.propertyTypes,
                  onChanged: (val) => formState.propertyTypeId = val,
                  itemToString: (item) => (item as LookupItem).name,
                  itemToValue: (item) => (item as LookupItem).id,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomDropdown<int>(
                  label: 'Renting Type',
                  value: formState.rentingTypeId,
                  items: lookup.rentingTypes,
                  onChanged: (val) => formState.rentingTypeId = val,
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
        initialAddress: formState.selectedAddress,
        initialAddressString: formState.initialAddressString,
        onAddressSelected: formState.updateAddressFromGoogle,
        streetNameController: formState.streetNameController,
        streetNumberController: formState.streetNumberController,
        cityController: formState.cityController,
        postalCodeController: formState.postalCodeController,
        countryController: formState.countryController,
        onManualAddressChanged: formState.updateAddressFromManualFields,
      ),
    );
  }

  Widget _buildImagesSection(ThemeData theme, PropertyFormState formState) {
    return SectionCard(
      title: 'Property Images',
      child: ImagePickerInput(
        initialImages: formState.images,
        onChanged: (images) {
          formState.images = images;
        },
      ),
    );
  }

  Widget _buildAmenitiesSection(ThemeData theme, PropertyFormState formState) {
    return SectionCard(
      title: 'Amenities',
      child: AmenityManager(
        mode: AmenityManagerMode.select,
        initialAmenityIds: formState.selectedAmenityIds,
        onAmenityIdsChanged: (ids) {
          formState.selectedAmenityIds = ids;
        },
        showTitle: false, // We have a SectionCard title now
      ),
    );
  }
}
