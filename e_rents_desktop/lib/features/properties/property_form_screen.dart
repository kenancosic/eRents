import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/services/mock_data_service.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:go_router/go_router.dart';
import './widgets/amenity_input.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:e_rents_desktop/widgets/inputs/google_address_input.dart';

class PropertyFormScreen extends StatefulWidget {
  final String? propertyId;

  const PropertyFormScreen({super.key, this.propertyId});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _bedroomsController;
  late final TextEditingController _bathroomsController;
  late final TextEditingController _areaController;
  late String _type;
  late String _status;
  List<String> _images = [];
  bool _isLoading = false;
  List<String> _selectedAmenities = [];
  Map<String, IconData> _allAmenitiesWithIcons = {};
  Property? _initialProperty;
  bool _isEditMode = false;
  bool _isFetchingData = false;
  String? _fetchError;
  String? _selectedFormattedAddress;
  String? _initialAddressString;
  double? _latitude;
  double? _longitude;
  String? _streetNumber;
  String? _streetName;
  String? _city;
  String? _postalCode;
  String? _country;
  bool _isAddressDetailValid = false;
  RentingType _rentingType = RentingType.monthly;

  // Controllers for manual address input
  late final TextEditingController _streetNameController;
  late final TextEditingController _streetNumberController;
  late final TextEditingController _cityController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.propertyId != null;

    // Initialize standard controllers
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _priceController = TextEditingController();
    _bedroomsController = TextEditingController();
    _bathroomsController = TextEditingController();
    _areaController = TextEditingController();

    // Initialize address controllers
    _streetNameController = TextEditingController();
    _streetNumberController = TextEditingController();
    _cityController = TextEditingController();
    _postalCodeController = TextEditingController();
    _countryController = TextEditingController();

    // Set initial default values
    _type = 'Apartment';
    _status = 'Available';
    _rentingType = RentingType.monthly;
    _images = [];
    _selectedAmenities = [];
    _selectedFormattedAddress = null;
    _initialAddressString = null;
    _latitude = null;
    _longitude = null;
    _isAddressDetailValid = false; // Address needs selection first

    // TODO: Replace MockDataService with AmenityService via Provider once DI is stable
    _allAmenitiesWithIcons = MockDataService.getMockAmenitiesWithIcons();

    if (_isEditMode) {
      _fetchPropertyData();
    }
  }

  @override
  void dispose() {
    // Dispose standard controllers
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    _areaController.dispose();

    // Dispose address controllers
    _streetNameController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();

    super.dispose();
  }

  void _updateSelectedAmenities(List<String> updatedList) {
    setState(() {
      _selectedAmenities = updatedList;
    });
  }

  void _updateSelectedImages(List<String> updatedList) {
    setState(() {
      _images = updatedList;
    });
  }

  Future<void> _fetchPropertyData() async {
    if (!mounted) return;
    setState(() {
      _isFetchingData = true;
      _fetchError = null;
    });

    try {
      final provider = context.read<PropertyProvider>();
      if (provider.properties.isEmpty) {
        await provider.fetchProperties();
      }
      _initialProperty = provider.getPropertyById(widget.propertyId!);

      if (_initialProperty != null) {
        _titleController.text = _initialProperty!.title;
        _descriptionController.text = _initialProperty!.description;
        _priceController.text = _initialProperty!.price.toString();
        _initialAddressString = _initialProperty!.address;
        _selectedFormattedAddress = _initialProperty!.address;
        _bedroomsController.text = _initialProperty!.bedrooms.toString();
        _bathroomsController.text = _initialProperty!.bathrooms.toString();
        _areaController.text = _initialProperty!.area.toString();
        _type = _initialProperty!.type;
        _status = _initialProperty!.status;
        _images = List.from(_initialProperty!.images);
        _selectedAmenities = _initialProperty!.amenities ?? [];
        _latitude = _initialProperty!.latitude;
        _longitude = _initialProperty!.longitude;
        _streetNumberController.text = _initialProperty!.streetNumber ?? '';
        _streetNameController.text = _initialProperty!.streetName ?? '';
        _cityController.text = _initialProperty!.city ?? '';
        _postalCodeController.text = _initialProperty!.postalCode ?? '';
        _countryController.text = _initialProperty!.country ?? '';
        _isAddressDetailValid =
            (_cityController.text.isNotEmpty) &&
            (_streetNameController.text.isNotEmpty);
        _rentingType = _initialProperty!.rentingType;
      } else {
        _fetchError = 'Property with ID ${widget.propertyId} not found.';
      }
    } catch (e) {
      _fetchError = "Failed to fetch property data: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingData = false;
        });
      }
    }
  }

  Property _createProperty() {
    return Property(
      id:
          _initialProperty?.id ??
          DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      type: _type,
      price: double.parse(_priceController.text),
      rentingType: _rentingType,
      status: _status,
      images: _images,
      address: _selectedFormattedAddress!,
      bedrooms: int.parse(_bedroomsController.text),
      bathrooms: int.parse(_bathroomsController.text),
      area: double.parse(_areaController.text),
      maintenanceIssues: _initialProperty?.maintenanceIssues ?? [],
      amenities: _selectedAmenities,
      yearBuilt: _initialProperty?.yearBuilt,
      lastInspectionDate: _initialProperty?.lastInspectionDate,
      nextInspectionDate: _initialProperty?.nextInspectionDate,
      latitude: _latitude,
      longitude: _longitude,
      streetNumber: _streetNumberController.text,
      streetName: _streetNameController.text,
      city: _cityController.text,
      postalCode: _postalCodeController.text,
      country: _countryController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title: _isEditMode ? 'Edit Property' : 'Add Property',
      currentPath: '/properties',
      child: LoadingOrErrorWidget(
        isLoading: _isFetchingData,
        error: _fetchError,
        onRetry: _isEditMode ? _fetchPropertyData : null,
        errorTitle: 'Failed to Load Property Data',
        child: SingleChildScrollView(
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
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: TextFormField(
                        controller: _priceController,
                        decoration: const InputDecoration(
                          labelText: 'Price',
                          border: OutlineInputBorder(),
                          suffixText: 'KM',
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a price';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<RentingType>(
                        value: _rentingType,
                        decoration: const InputDecoration(
                          labelText: 'Renting Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items:
                            RentingType.values
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type.displayName),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _rentingType = value);
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a renting type';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items:
                            ['Apartment', 'House', 'Villa']
                                .map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _type = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items:
                            ['Available', 'Occupied']
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(status),
                                  ),
                                )
                                .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _status = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GoogleAddressInput(
                  googleApiKey: dotenv.env['GOOGLE_MAPS_API_KEY']!,
                  initialValue: _initialAddressString,
                  countries: const ["BA"],
                  onAddressSelected: (selectedDetails) {
                    setState(() {
                      if (selectedDetails != null) {
                        _selectedFormattedAddress =
                            selectedDetails.formattedAddress;
                        _latitude = selectedDetails.latitude;
                        _longitude = selectedDetails.longitude;
                        _streetNumberController.text =
                            selectedDetails.streetNumber ?? '';
                        _streetNameController.text =
                            selectedDetails.streetName ?? '';
                        _cityController.text = selectedDetails.city ?? '';
                        _postalCodeController.text =
                            selectedDetails.postalCode ?? '';
                        _countryController.text = selectedDetails.country ?? '';
                      } else {
                        _selectedFormattedAddress = null;
                        _latitude = null;
                        _longitude = null;
                      }
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select an address or fill details manually';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _streetNameController,
                        decoration: const InputDecoration(
                          labelText: 'Street Name *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Street name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _streetNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Street No.',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'City is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _postalCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Postal Code',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _countryController,
                        decoration: const InputDecoration(
                          labelText: 'Country',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _bedroomsController,
                        decoration: const InputDecoration(
                          labelText: 'Bedrooms',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter number of bedrooms';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _bathroomsController,
                        decoration: const InputDecoration(
                          labelText: 'Bathrooms',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter number of bathrooms';
                          }
                          if (int.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _areaController,
                        decoration: const InputDecoration(
                          labelText: 'Area (sqft)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter area';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Please enter a valid number';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Amenities',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                AmenityInput(
                  initialAmenities: _selectedAmenities,
                  availableAmenitiesWithIcons: _allAmenitiesWithIcons,
                  onChanged: _updateSelectedAmenities,
                ),
                const SizedBox(height: 24),
                Text(
                  'Property Images',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                ImagePickerInput(
                  initialImages: _images,
                  onChanged: _updateSelectedImages,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Perform form validation first
                        if (!_formKey.currentState!.validate()) {
                          return; // Stop if basic form validation fails
                        }

                        // Proceed with saving if all validations pass
                        final propertyToSave = _createProperty();
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
                                content: Text(
                                  'Failed to save property: ${e.toString()}',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
