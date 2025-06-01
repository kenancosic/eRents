import 'package:e_rents_desktop/models/address_detail.dart';
import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/widgets/amenity_manager.dart';
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
      final propertyId = int.tryParse(widget.propertyId!);
      if (propertyId == null) {
        throw Exception('Invalid property ID: ${widget.propertyId}');
      }
      _initialProperty = provider.getPropertyById(propertyId);

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
    if (!_formKey.currentState!.validate()) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fix the validation errors before saving.'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    if (!mounted) return;
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUserId = authProvider.currentUser?.id ?? 0;

    if (currentUserId == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: User not authenticated. Cannot save property.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final propertyToSave = _formState.createProperty(
        currentUserId,
        _initialProperty,
      );

      if (!mounted) return;
      final provider = context.read<PropertyProvider>();

      if (_isEditMode) {
        await provider.updateProperty(propertyToSave);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Property "${propertyToSave.title}" updated successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        await provider.addProperty(propertyToSave);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Property "${propertyToSave.title}" created successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }

      if (!mounted) return;
      context.pop();
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to save property: ';
      if (e.toString().contains('401') ||
          e.toString().contains('Unauthorized')) {
        errorMessage += 'Authentication required. Please log in again.';
      } else if (e.toString().contains('403') ||
          e.toString().contains('Forbidden')) {
        errorMessage += 'You do not have permission to perform this action.';
      } else if (e.toString().contains('400') ||
          e.toString().contains('Bad Request')) {
        errorMessage += 'Invalid data provided. Please check your inputs.';
      } else if (e.toString().contains('500') ||
          e.toString().contains('Internal Server Error')) {
        errorMessage += 'Server error. Please try again later.';
      } else {
        errorMessage += e.toString().replaceAll('Exception: ', '');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.redAccent,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ChangeNotifierProvider.value(
      value: _formState,
      child: Consumer<PropertyFormState>(
        builder: (context, formState, child) {
          return LoadingOrErrorWidget(
            isLoading: formState.isFetchingData,
            error: formState.fetchError,
            onRetry: _isEditMode ? _fetchPropertyData : null,
            errorTitle: 'Failed to Load Property Data',
            child: Scaffold(
              appBar: AppBar(
                title: Text(_isEditMode ? 'Edit Property' : 'Add New Property'),
                elevation: 1,
              ),
              body: _buildForm(formState, theme),
              bottomNavigationBar: _buildBottomAppBar(theme),
            ),
          );
        },
      ),
    );
  }

  Widget _buildForm(PropertyFormState formState, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionCard(
              title: 'Basic Information',
              theme: theme,
              sectionIcon: Icons.info_outline,
              children: [
                _buildTitleAndPriceRow(formState, theme),
                const SizedBox(height: 16),
                _buildDescriptionField(formState, theme),
              ],
            ),
            _buildSectionCard(
              title: 'Property Type & Status',
              theme: theme,
              sectionIcon: Icons.category_outlined,
              children: [_buildSelectionSections(formState, theme)],
            ),
            _buildSectionCard(
              title: 'Address Details',
              theme: theme,
              sectionIcon: Icons.location_on_outlined,
              children: [_buildAddressSection(formState, theme)],
            ),
            _buildSectionCard(
              title: 'Property Features',
              theme: theme,
              sectionIcon: Icons.construction_outlined,
              children: [
                _buildPropertyDetailsRow(formState, theme),
                if (formState.rentingType == RentingType.daily) ...[
                  const SizedBox(height: 16),
                  _buildDailyRateRow(formState, theme),
                ],
              ],
            ),
            _buildSectionCard(
              title: 'Amenities',
              theme: theme,
              sectionIcon: Icons.deck_outlined,
              children: [
                AmenityManager(
                  mode: AmenityManagerMode.edit,
                  initialAmenityIds: formState.selectedAmenityIds,
                  initialAmenityNames: formState.selectedAmenities,
                  onAmenityIdsChanged: (amenityIds) {
                    formState.selectedAmenityIds = amenityIds;
                  },
                  showTitle: false, // Title is already shown by section card
                ),
              ],
            ),
            _buildSectionCard(
              title: 'Property Images',
              theme: theme,
              sectionIcon: Icons.image_outlined,
              children: [
                ImagePickerInput(
                  initialImages: formState.images,
                  onChanged: (images) => formState.images = images,
                  maxImages: 15,
                  allowReordering: true,
                  allowCoverSelection: true,
                  emptyStateText:
                      'Add property images to showcase your rental. The first image will be the cover image.',
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required ThemeData theme,
    required List<Widget> children,
    IconData? sectionIcon,
  }) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.only(bottom: 16.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (sectionIcon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Icon(sectionIcon, color: theme.colorScheme.primary),
                  ),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String labelText,
    required ThemeData theme,
    String? suffixText,
    int? maxLines = 1,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    bool isRequired = true,
    IconData? leadingIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        labelStyle: theme.textTheme.bodyLarge,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 16.0,
        ),
        suffixText: suffixText,
        prefixIcon:
            leadingIcon != null
                ? Icon(leadingIcon, color: theme.colorScheme.onSurfaceVariant)
                : null,
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator:
          validator ??
          (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return 'Please enter $labelText';
            }
            return null;
          },
    );
  }

  Widget _buildModernNumberField({
    required TextEditingController controller,
    required String labelText,
    required ThemeData theme,
    String? suffixText,
    String? errorMessage,
    double? minValue,
    bool isRequired = true,
    TextInputType? keyboardType,
    FormFieldValidator<String>? validator,
    IconData? leadingIcon,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: isRequired ? '$labelText *' : labelText,
        labelStyle: theme.textTheme.bodyLarge,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 16.0,
        ),
        suffixText: suffixText,
        prefixIcon:
            leadingIcon != null
                ? Icon(leadingIcon, color: theme.colorScheme.onSurfaceVariant)
                : null,
      ),
      keyboardType: keyboardType ?? TextInputType.number,
      validator:
          validator ??
          (value) {
            if (isRequired && (value == null || value.isEmpty)) {
              return errorMessage ?? 'Please enter $labelText';
            }
            if (value != null && value.isNotEmpty) {
              final number = double.tryParse(value);
              if (number == null) {
                return 'Please enter a valid number';
              }
              if (minValue != null && number < minValue) {
                return '$labelText must be at least $minValue';
              }
            }
            return null;
          },
    );
  }

  Widget _buildTitleAndPriceRow(PropertyFormState formState, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: _buildModernTextField(
            controller: formState.titleController,
            labelText: 'Property Title',
            theme: theme,
            isRequired: true,
            leadingIcon: Icons.title,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildModernNumberField(
            controller: formState.priceController,
            labelText: 'Monthly Price',
            suffixText: 'BAM',
            errorMessage: 'Please enter a price',
            theme: theme,
            isRequired: true,
            minValue: 0.01,
            leadingIcon: Icons.attach_money,
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField(PropertyFormState formState, ThemeData theme) {
    return _buildModernTextField(
      controller: formState.descriptionController,
      labelText: 'Description',
      maxLines: 4,
      theme: theme,
      isRequired: true,
      leadingIcon: Icons.description,
    );
  }

  Widget _buildSelectionSections(PropertyFormState formState, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDropdownSection<RentingType>(
          title: 'Renting Type *',
          value: formState.rentingType,
          items: RentingType.values,
          onChanged: (type) => formState.rentingType = type!,
          itemToString: (type) => type.displayName,
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildDropdownSection<PropertyType>(
          title: 'Property Type *',
          value: formState.type,
          items: PropertyType.values,
          onChanged: (type) => formState.type = type!,
          itemToString: (type) => type.displayName,
          theme: theme,
        ),
        const SizedBox(height: 16),
        _buildDropdownSection<PropertyStatus>(
          title: 'Status *',
          value: formState.status,
          items: PropertyStatus.values,
          onChanged: (status) => formState.status = status!,
          itemToString: (status) => status.displayName,
          theme: theme,
        ),
      ],
    );
  }

  Widget _buildDropdownSection<T>({
    required String title,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) itemToString,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<T>(
          value: value,
          items:
              items.map((item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(
                    itemToString(item),
                    style: theme.textTheme.bodyLarge,
                  ),
                );
              }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 16.0,
            ),
          ),
          validator: (val) => val == null ? 'Please select an option' : null,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }

  Widget _buildAddressSection(PropertyFormState formState, ThemeData theme) {
    final bool hasGoogleApi =
        dotenv.env['GOOGLE_MAPS_API_KEY']?.isNotEmpty == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasGoogleApi) ...[
          Text(
            'Search Address (Recommended)',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
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
              final hasManualAddress =
                  formState.streetNameController.text.trim().isNotEmpty ||
                  formState.cityController.text.trim().isNotEmpty;
              if (!hasManualAddress && (value == null || value.isEmpty)) {
                return 'Select an address or fill details manually';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: Divider()),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text("OR", style: theme.textTheme.bodySmall),
              ),
              const Expanded(child: Divider()),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Enter Address Manually',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
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
          const SizedBox(height: 16),
          Text(
            'Manual Address Details',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: formState.streetNameController,
                labelText: 'Street Name',
                theme: theme,
                isRequired: !hasGoogleApi,
                leadingIcon: Icons.maps_home_work_outlined,
                validator: (value) {
                  if (hasGoogleApi) {
                    final hasGoogleAddress =
                        formState.selectedFormattedAddress?.isNotEmpty == true;
                    final hasManualEntry =
                        value?.trim().isNotEmpty == true ||
                        formState.cityController.text.trim().isNotEmpty;
                    if (!hasGoogleAddress && !hasManualEntry)
                      return 'Enter street or use Google Address';
                  } else {
                    if (value == null || value.isEmpty)
                      return 'Please enter street name';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildModernTextField(
                controller: formState.streetNumberController,
                labelText: 'Street No.',
                theme: theme,
                isRequired: false,
                leadingIcon: Icons.format_list_numbered,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildModernTextField(
                controller: formState.cityController,
                labelText: 'City',
                theme: theme,
                isRequired: !hasGoogleApi,
                leadingIcon: Icons.location_city,
                validator: (value) {
                  if (hasGoogleApi) {
                    final hasGoogleAddress =
                        formState.selectedFormattedAddress?.isNotEmpty == true;
                    final hasManualEntry =
                        value?.trim().isNotEmpty == true ||
                        formState.streetNameController.text.trim().isNotEmpty;
                    if (!hasGoogleAddress && !hasManualEntry)
                      return 'Enter city or use Google Address';
                  } else {
                    if (value == null || value.isEmpty)
                      return 'Please enter city';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: formState.postalCodeController,
                labelText: 'Postal Code',
                theme: theme,
                isRequired: false,
                leadingIcon: Icons.local_post_office_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildModernTextField(
                controller: formState.countryController,
                labelText: 'Country',
                theme: theme,
                isRequired: false,
                leadingIcon: Icons.public_outlined,
                validator: (value) {
                  if (!hasGoogleApi &&
                      (value == null || value.isEmpty) &&
                      (formState.cityController.text.isNotEmpty ||
                          formState.streetNameController.text.isNotEmpty)) {
                    return 'Country is required for manual entry';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsRow(
    PropertyFormState formState,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildModernNumberField(
            controller: formState.bedroomsController,
            labelText: 'Bedrooms',
            errorMessage: 'Enter number of bedrooms',
            theme: theme,
            minValue: 1,
            isRequired: true,
            leadingIcon: Icons.bed_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernNumberField(
            controller: formState.bathroomsController,
            labelText: 'Bathrooms',
            errorMessage: 'Enter number of bathrooms',
            theme: theme,
            minValue: 1,
            isRequired: true,
            leadingIcon: Icons.bathtub_outlined,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernNumberField(
            controller: formState.areaController,
            labelText: 'Area (sqft)',
            theme: theme,
            errorMessage: 'Please enter area',
            minValue: 1,
            isRequired: true,
            leadingIcon: Icons.square_foot_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter area';
              }
              final area = double.tryParse(value);
              if (area == null) {
                return 'Please enter a valid area';
              }
              if (area <= 0) {
                return 'Area must be greater than 0';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyRateRow(PropertyFormState formState, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildModernNumberField(
            controller: formState.dailyRateController,
            labelText: 'Daily Rate',
            suffixText:
                formState.currencyController.text.isNotEmpty
                    ? formState.currencyController.text
                    : 'BAM',
            theme: theme,
            isRequired: formState.rentingType == RentingType.daily,
            leadingIcon: Icons.price_check_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (formState.rentingType == RentingType.daily &&
                  (value == null || value.isEmpty)) {
                return 'Daily rate is required for daily rentals';
              }
              if (value != null && value.isNotEmpty) {
                final rate = double.tryParse(value);
                if (rate == null) {
                  return 'Please enter a valid daily rate';
                }
                if (rate <= 0) {
                  return 'Daily rate must be positive';
                }
              }
              return null;
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildModernNumberField(
            controller: formState.minimumStayDaysController,
            labelText: 'Min. Stay (days)',
            theme: theme,
            isRequired: false,
            leadingIcon: Icons.calendar_today_outlined,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final days = int.tryParse(value);
                if (days == null) return 'Enter a valid number of days';
                if (days < 1 && formState.rentingType == RentingType.daily)
                  return 'Minimum stay must be at least 1 day';
              }
              return null;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAppBar(ThemeData theme) {
    return BottomAppBar(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel'),
              style: TextButton.styleFrom(
                foregroundColor: theme.textTheme.bodyLarge?.color,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.save_alt_outlined),
              onPressed: _saveProperty,
              label: const Text('Save Property'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                textStyle: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension PropertyTypeExtension on PropertyType {
  String get displayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.studio:
        return 'Studio';
      default:
        return toString().split('.').last.toUpperCase();
    }
  }
}

extension PropertyStatusExtension on PropertyStatus {
  String get displayName {
    switch (this) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.maintenance:
        return 'Maintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
      default:
        return toString().split('.').last.toUpperCase();
    }
  }
}
