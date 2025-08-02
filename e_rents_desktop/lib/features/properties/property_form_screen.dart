import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/services/api_service.dart';
import 'package:e_rents_desktop/features/properties/providers/properties_provider.dart';

import 'package:e_rents_desktop/features/properties/widgets/property_form_fields.dart';
import 'package:e_rents_desktop/models/lookup_data.dart';
import 'dart:typed_data';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/widgets/amenity_manager.dart';
import 'package:e_rents_desktop/widgets/common/section_card.dart';

import 'package:e_rents_desktop/widgets/inputs/custom_dropdown.dart';
import 'package:e_rents_desktop/widgets/inputs/address_input.dart'; // Use generic AddressInput
import 'package:flutter/material.dart' hide ImageInfo;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PropertyFormScreen extends StatelessWidget {
  final Property? property;

  const PropertyFormScreen({super.key, this.property});

  @override
  Widget build(BuildContext context) {
    final lookupProvider = context.watch<LookupProvider>();

    if (lookupProvider.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (lookupProvider.error != null) {
      return Scaffold(
        body: Center(
          child: Text('Error loading lookup data: ${lookupProvider.error}'),
        ),
      );
    }

    if (!lookupProvider.hasData) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Lookup data not available. Please try again.'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed:
                    () => context.read<LookupProvider>().loadLookupData(),
                child: const Text('Reload'),
              ),
            ],
          ),
        ),
      );
    }

    return _PropertyFormScreenContent(
      property: property,
      lookupData: lookupProvider.lookupData!,
    );
  }
}

class _PropertyFormScreenContent extends StatefulWidget {
  final Property? property;
  final LookupData lookupData;

  const _PropertyFormScreenContent({this.property, required this.lookupData});

  @override
  State<_PropertyFormScreenContent> createState() =>
      _PropertyFormScreenContentState();
}

class _PropertyFormScreenContentState extends State<_PropertyFormScreenContent> {
  bool get isEditMode => widget.property != null;
  final _formKey = GlobalKey<FormState>();
  late Property _property;
  late List<ImageInfo> _images;

  final List<Uint8List> _newImageData = [];
  final List<String> _newImageFileNames = [];

  // Text editing controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _bedroomsController = TextEditingController();
  final _bathroomsController = TextEditingController();
  final _areaController = TextEditingController();
  final _minimumStayDaysController = TextEditingController();
  final _streetNameController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _countryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _property = widget.property?.copyWith() ??
        Property(
          propertyId: 0,
          ownerId: context.read<AuthProvider>().currentUser!.id,
          name: '',
          description: '',
          price: 0.0,
        );

    _images = [];

    if (isEditMode) {
      final apiService = context.read<ApiService>();
      _images = _property.imageIds.map((id) {
        return ImageInfo(
          id: id,
          url: apiService.makeAbsoluteUrl('Images/$id'),
          isCover: id == _property.coverImageId,
          isNew: false,
        );
      }).toList();
    }

    // Initialize controllers
    _nameController.text = _property.name;
    _descriptionController.text = _property.description;
    _priceController.text = _property.price.toString();
    _bedroomsController.text = _property.bedrooms.toString();
    _bathroomsController.text = _property.bathrooms.toString();
    _areaController.text = _property.area.toString();
    _minimumStayDaysController.text = _property.minimumStayDays?.toString() ?? '';

    final address = _property.address;
    if (address != null) {
      _streetNameController.text = address.streetLine1 ?? '';
      _streetNumberController.text = address.streetLine2 ?? '';
      _cityController.text = address.city ?? '';
      _postalCodeController.text = address.postalCode ?? '';
      _countryController.text = address.country ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();
    _minimumStayDaysController.dispose();
    _streetNameController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  Future<void> _saveProperty() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final currentImageIds = _images
          .where((img) => !img.isNew && img.id != null)
          .map((img) => img.id!)
          .toList();

      final coverImage = _images.firstWhere(
        (img) => img.isCover,
        orElse: () => _images.isNotEmpty ? _images.first : ImageInfo(),
      );

      final int? coverId = coverImage.isNew ? null : coverImage.id;

      final propertyToSave = _property.copyWith(
        name: _nameController.text,
        description: _descriptionController.text,
        price: double.tryParse(_priceController.text) ?? 0.0,
        bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        area: double.tryParse(_areaController.text) ?? 0.0,
        minimumStayDays: int.tryParse(_minimumStayDaysController.text),
        coverImageId: coverId,
        address: (_property.address ?? Address(latitude: null, longitude: null))
            .copyWith(
          streetLine1: _streetNameController.text,
          streetLine2: _streetNumberController.text,
          city: _cityController.text,
          postalCode: _postalCodeController.text,
          country: _countryController.text,
          latitude: null, 
          longitude: null,
        ),
      );

      final success = await context.read<PropertiesProvider>().saveProperty(
            propertyToSave,
            newImageData: _newImageData,
            newImageFileNames: _newImageFileNames,
            existingImageIds: currentImageIds,
          );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property saved successfully')),
          );
          context.pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Failed to save property: ${context.read<PropertiesProvider>().error}'),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditMode ? 'Edit Property' : 'Add New Property'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ElevatedButton.icon(
              onPressed: _saveProperty,
              icon: const Icon(Icons.save),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBasicInfoSection(theme),
              const SizedBox(height: 24),
              _buildDetailsSection(theme),
              const SizedBox(height: 24),
              _buildAddressSection(theme), // Now uses generic AddressInput
              const SizedBox(height: 24),
              _buildImagesSection(context, theme),
              const SizedBox(height: 24),
              _buildAmenitiesSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return SectionCard(
      title: 'Basic Information',
      child: Column(
        children: [
          PropertyFormFields.buildRequiredTextField(
            controller: _nameController,
            labelText: 'Property Name',
          ),
          PropertyFormFields.buildSpacer(),
          PropertyFormFields.buildRequiredTextField(
            controller: _priceController,
            labelText: 'Price per Night',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          PropertyFormFields.buildSpacer(),
          PropertyFormFields.buildTextField(
            controller: _descriptionController,
            labelText: 'Description',
            maxLines: 5,
            validator: (_) => null,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection(ThemeData theme) {
    return SectionCard(
      title: 'Property Details',
      child: Column(
        children: [
          PropertyFormFields.buildRequiredTextField(
            controller: _bedroomsController,
            labelText: 'Bedrooms',
            keyboardType: TextInputType.number,
          ),
          PropertyFormFields.buildSpacer(),
          PropertyFormFields.buildRequiredTextField(
            controller: _bathroomsController,
            labelText: 'Bathrooms',
            keyboardType: TextInputType.number,
          ),
          PropertyFormFields.buildSpacer(),
          PropertyFormFields.buildRequiredTextField(
            controller: _areaController,
            labelText: 'Area (sq ft)',
            keyboardType: TextInputType.number,
          ),
          PropertyFormFields.buildSpacer(),
          PropertyFormFields.buildTextField(
            controller: _minimumStayDaysController,
            labelText: 'Minimum Stay (days)',
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null &&
                  value.isNotEmpty &&
                  int.tryParse(value) == null) {
                return 'Please enter a valid number';
              }
              return null;
            },
          ),
          PropertyFormFields.buildSpacer(),
          Row(
            children: [
              Expanded(
                child: CustomDropdown<int>(
                  label: 'Property Type',
                  value: _property.propertyTypeId,
                  items: widget.lookupData.propertyTypes,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _property = _property.copyWith(propertyTypeId: val);
                      });
                    }
                  },
                  itemToString: (item) => (item as LookupItem).name,
                  itemToValue: (item) => (item as LookupItem).id,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomDropdown<int>(
                  label: 'Renting Type',
                  value: _property.rentingTypeId,
                  items: widget.lookupData.rentingTypes,
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _property = _property.copyWith(rentingTypeId: val);
                      });
                    }
                  },
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

  Widget _buildAddressSection(ThemeData theme) {
    return SectionCard(
      title: 'Location & Address',
      child: AddressInput(
        initialAddress: _property.address,
        // Existing controllers are passed directly
        streetNameController: _streetNameController,
        streetNumberController: _streetNumberController,
        cityController: _cityController,
        postalCodeController: _postalCodeController,
        countryController: _countryController,
        // Callbacks to ensure _property is updated from manual changes
        onManualAddressChanged: () {
          setState(() {
            _property = _property.copyWith(
              address: Address(
                streetLine1: _streetNameController.text,
                streetLine2: _streetNumberController.text,
                city: _cityController.text,
                postalCode: _postalCodeController.text,
                country: _countryController.text,
                latitude: null, // No longer used with simple input
                longitude: null, // No longer used with simple input
              ),
            );
          });
        },
        // This callback could be removed as it's for external address selection
        // For a simplified manual input, it will not be triggered by AddressInput itself
        onAddressSelected: (Address? selectedAddress) {
          if (selectedAddress != null) {
            setState(() {
              _property = _property.copyWith(address: selectedAddress);
              _streetNameController.text = selectedAddress.streetLine1 ?? '';
              _streetNumberController.text = selectedAddress.streetLine2 ?? '';
              _cityController.text = selectedAddress.city ?? '';
              _postalCodeController.text = selectedAddress.postalCode ?? '';
              _countryController.text = selectedAddress.country ?? '';
            });
          }
        },
      ),
    );
  }

  Widget _buildImagesSection(BuildContext context, ThemeData theme) {
    return SectionCard(
      title: 'Property Images',
      child: ImagePickerInput(
        apiService: context.read<ApiService>(),
        initialImages: _images,
        onChanged: (images) {
          setState(() {
            _images = images;
            _newImageData.clear();
            _newImageFileNames.clear();
            for (var img in images) {
              if (img.isNew && img.data != null) {
                _newImageData.add(img.data!);
                _newImageFileNames.add(img.fileName ?? 'image.jpg');
              }
            }
          });
        },
      ),
    );
  }

  Widget _buildAmenitiesSection(ThemeData theme) {
    return SectionCard(
      title: 'Amenities',
      child: AmenityManager(
        mode: AmenityManagerMode.select,
        initialAmenityIds: _property.amenityIds,
        onAmenityIdsChanged: (ids) {
          setState(() {
            _property = _property.copyWith(amenityIds: ids);
          });
        },
        showTitle: false, // We have a SectionCard title now
      ),
    );
  }
}
