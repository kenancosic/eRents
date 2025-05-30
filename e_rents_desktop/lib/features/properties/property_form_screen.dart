import 'package:e_rents_desktop/models/address_detail.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import './widgets/amenity_input.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:e_rents_desktop/widgets/inputs/google_address_input.dart';
import './widgets/property_form_fields.dart';
import './widgets/property_selection_widgets.dart';
import './models/property_form_state.dart';

class PropertyFormScreen extends StatefulWidget {
  final String? propertyId;

  const PropertyFormScreen({super.key, this.propertyId});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PropertyFormState _formState;
  Map<String, IconData> _allAmenitiesWithIcons = {};
  Property? _initialProperty;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.propertyId != null;
    _formState = PropertyFormState();

    if (_isEditMode) {
      _fetchPropertyData();
    }
  }

  @override
  void dispose() {
    _formState.dispose();
    super.dispose();
  }

  Future<void> _fetchPropertyData() async {
    if (!mounted) return;
    _formState.setFetchingState(true);

    try {
      final provider = context.read<PropertyProvider>();
      if (provider.properties.isEmpty) {
        await provider.fetchProperties();
      }
      _initialProperty = provider.getPropertyById(widget.propertyId!);

      if (_initialProperty != null) {
        _formState.populateFromProperty(_initialProperty!);
      } else {
        _formState.setFetchingState(
          false,
          'Property with ID ${widget.propertyId} not found.',
        );
      }
    } catch (e) {
      _formState.setFetchingState(
        false,
        "Failed to fetch property data: ${e.toString()}",
      );
    } finally {
      if (mounted) {
        _formState.setFetchingState(false);
      }
    }
  }

  Future<void> _saveProperty() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId =
        authProvider.currentUser?.id ?? 'error_user_id_not_found';

    if (currentUserId == 'error_user_id_not_found') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not authenticated. Cannot save property.'),
        ),
      );
      return;
    }

    final propertyToSave = _formState.createProperty(
      currentUserId,
      _initialProperty,
    );
    final provider = context.read<PropertyProvider>();

    try {
      if (_isEditMode) {
        await provider.updateProperty(propertyToSave);
      } else {
        await provider.addProperty(propertyToSave);
      }
      if (context.mounted) context.pop();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save property: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(
      context,
      listen: false,
    );

    return ChangeNotifierProvider.value(
      value: _formState,
      child: Consumer<PropertyFormState>(
        builder: (context, formState, child) {
          return FutureBuilder<Map<String, IconData>>(
            future: propertyProvider.fetchAmenitiesWithIcons(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  _allAmenitiesWithIcons.isEmpty) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasData) {
                _allAmenitiesWithIcons = snapshot.data!;
              } else if (_allAmenitiesWithIcons.isEmpty) {
                _allAmenitiesWithIcons = propertyProvider.amenityIcons;
              }

              return LoadingOrErrorWidget(
                isLoading: formState.isFetchingData,
                error: formState.fetchError,
                onRetry: _isEditMode ? _fetchPropertyData : null,
                errorTitle: 'Failed to Load Property Data',
                child: _buildForm(formState),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildForm(PropertyFormState formState) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            PropertyFormFields.buildSpacer(height: 16),

            // Title and Price Row
            _buildTitleAndPriceRow(formState),
            PropertyFormFields.buildSpacer(),

            // Description
            PropertyFormFields.buildRequiredTextField(
              controller: formState.descriptionController,
              labelText: 'Description',
              maxLines: 3,
            ),
            PropertyFormFields.buildSpacer(height: 16),

            // Selection Sections
            _buildSelectionSections(formState),

            // Address Section
            _buildAddressSection(formState),

            // Property Details
            _buildPropertyDetailsRow(formState),

            // Daily Rate (if daily rental)
            if (formState.rentingType == RentingType.daily) ...[
              PropertyFormFields.buildSpacer(),
              _buildDailyRateRow(formState),
            ],

            PropertyFormFields.buildSpacer(height: 16),

            // Amenities
            PropertyFormFields.buildSectionTitle(context, 'Amenities'),
            PropertyFormFields.buildSpacer(height: 8),
            AmenityInput(
              initialAmenities: formState.selectedAmenities,
              availableAmenitiesWithIcons: _allAmenitiesWithIcons,
              onChanged: (amenities) => formState.selectedAmenities = amenities,
            ),

            PropertyFormFields.buildSpacer(height: 24),

            // Images
            Text(
              'Property Images',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            PropertyFormFields.buildSpacer(),
            ImagePickerInput(
              initialImages: formState.images,
              onChanged: (images) => formState.images = images,
            ),

            PropertyFormFields.buildSpacer(height: 24),

            // Action Buttons
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleAndPriceRow(PropertyFormState formState) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyFormFields.buildRequiredTextField(
          controller: formState.titleController,
          labelText: 'Title',
          flex: 2,
        ),
        PropertyFormFields.buildSpacer(height: 0),
        PropertyFormFields.buildNumberField(
          controller: formState.priceController,
          labelText: 'Monthly Price',
          suffixText: 'BAM',
          errorMessage: 'Please enter a price',
          flex: 1,
        ),
      ],
    );
  }

  Widget _buildSelectionSections(PropertyFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyFormFields.buildSectionTitle(context, 'Renting Type'),
        PropertySelectionWidgets.buildRentingTypeSelection(
          selectedType: formState.rentingType,
          onChanged: (type) => formState.rentingType = type,
          context: context,
        ),
        PropertyFormFields.buildSpacer(),

        PropertyFormFields.buildSectionTitle(context, 'Property Type'),
        PropertySelectionWidgets.buildPropertyTypeSelection(
          selectedType: formState.type,
          onChanged: (type) => formState.type = type,
          context: context,
        ),
        PropertyFormFields.buildSpacer(),

        PropertyFormFields.buildSectionTitle(context, 'Status'),
        PropertySelectionWidgets.buildStatusSelection(
          selectedStatus: formState.status,
          onChanged: (status) => formState.status = status,
          context: context,
        ),
        PropertyFormFields.buildSpacer(),
      ],
    );
  }

  Widget _buildAddressSection(PropertyFormState formState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Google address input if API key available
        if (dotenv.env['GOOGLE_MAPS_API_KEY']?.isNotEmpty == true) ...[
          GoogleAddressInput(
            googleApiKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
            initialValue: formState.initialAddressString,
            countries: const ["BA"],
            onAddressSelected: (selectedDetails) {
              formState.updateAddressData(
                formattedAddress: selectedDetails?.formattedAddress,
                lat: selectedDetails?.latitude,
                lng: selectedDetails?.longitude,
                streetNumber: selectedDetails?.streetNumber,
                streetName: selectedDetails?.streetName,
                city: selectedDetails?.city,
                postalCode: selectedDetails?.postalCode,
                country: selectedDetails?.country,
              );
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please select an address or fill details manually';
              }
              return null;
            },
          ),
          PropertyFormFields.buildSpacer(),
          const Divider(),
          PropertyFormFields.buildSpacer(),
          Text(
            'Or enter address details manually:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              border: Border.all(color: Colors.orange.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Google Maps API key not configured. Please enter address manually.',
                    style: TextStyle(color: Colors.orange.shade700),
                  ),
                ),
              ],
            ),
          ),
        ],

        PropertyFormFields.buildSpacer(),

        // Manual address fields
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PropertyFormFields.buildRequiredTextField(
              controller: formState.streetNameController,
              labelText: 'Street Name *',
              flex: 1,
            ),
            PropertyFormFields.buildSpacer(height: 0),
            PropertyFormFields.buildTextField(
              controller: formState.streetNumberController,
              labelText: 'Street No.',
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
              controller: formState.cityController,
              labelText: 'City *',
              flex: 1,
            ),
            PropertyFormFields.buildSpacer(height: 0),
            PropertyFormFields.buildTextField(
              controller: formState.postalCodeController,
              labelText: 'Postal Code',
              flex: 1,
              validator: (_) => null,
            ),
            PropertyFormFields.buildSpacer(height: 0),
            PropertyFormFields.buildTextField(
              controller: formState.countryController,
              labelText: 'Country',
              flex: 1,
              validator: (_) => null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsRow(PropertyFormState formState) {
    return Row(
      children: [
        PropertyFormFields.buildNumberField(
          controller: formState.bedroomsController,
          labelText: 'Bedrooms',
          errorMessage: 'Please enter number of bedrooms',
          flex: 1,
        ),
        PropertyFormFields.buildSpacer(height: 0),
        PropertyFormFields.buildNumberField(
          controller: formState.bathroomsController,
          labelText: 'Bathrooms',
          errorMessage: 'Please enter number of bathrooms',
          flex: 1,
        ),
        PropertyFormFields.buildSpacer(height: 0),
        PropertyFormFields.buildNumberField(
          controller: formState.areaController,
          labelText: 'Area (sqft)',
          errorMessage: 'Please enter area',
          flex: 1,
        ),
      ],
    );
  }

  Widget _buildDailyRateRow(PropertyFormState formState) {
    return Row(
      children: [
        PropertyFormFields.buildTextField(
          controller: formState.dailyRateController,
          labelText: 'Daily Rate',
          suffixText: formState.currencyController.text,
          keyboardType: TextInputType.number,
          flex: 1,
          validator: (value) {
            if (formState.rentingType == RentingType.daily &&
                (value == null || value.isEmpty)) {
              return 'Daily rate is required for daily rentals';
            }
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return 'Please enter a valid daily rate';
            }
            return null;
          },
        ),
        PropertyFormFields.buildSpacer(height: 0),
        PropertyFormFields.buildTextField(
          controller: formState.minimumStayDaysController,
          labelText: 'Minimum Stay (days)',
          keyboardType: TextInputType.number,
          flex: 1,
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                int.tryParse(value) == null) {
              return 'Please enter a valid number of days';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        const SizedBox(width: 12),
        ElevatedButton(onPressed: _saveProperty, child: const Text('Save')),
      ],
    );
  }
}
