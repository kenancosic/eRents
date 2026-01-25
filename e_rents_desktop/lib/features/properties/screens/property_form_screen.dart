import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/models/enums/renting_type.dart';
import 'package:e_rents_desktop/base/crud/form_screen.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart' as img_input;
import 'package:e_rents_desktop/widgets/inputs/address_input.dart';
import 'package:e_rents_desktop/widgets/amenity_manager.dart';
import 'package:e_rents_desktop/services/image_service.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_status_chip.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_renting_type_dropdown.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_unavailable_date_fields.dart';

class PropertyFormScreen extends StatefulWidget {
  final int? propertyId;
  
  const PropertyFormScreen({super.key, this.propertyId});

  @override
  State<PropertyFormScreen> createState() => _PropertyFormScreenState();
}

class _PropertyFormScreenState extends State<PropertyFormScreen> {
  Property? _initialProperty;
  bool _isLoading = true;
  bool _disposed = false;
  int _loadToken = 0; // prevents late completions from earlier requests
  List<img_input.ImageInfo> _pickedImages = [];
  final GlobalKey<_PropertyFormFieldsState> _fieldsKey = GlobalKey<_PropertyFormFieldsState>();

  @override
  void initState() {
    super.initState();
    _loadPropertyIfNeeded();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadPropertyIfNeeded() async {
    final int token = ++_loadToken;
    if (widget.propertyId != null) {
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      try {
        final loaded = await propertyProvider.loadProperty(widget.propertyId!);
        if (!mounted || _disposed || token != _loadToken) return;
        setState(() {
          _initialProperty = loaded;
          _isLoading = false;
        });
        return;
      } catch (e) {
        if (!mounted || _disposed || token != _loadToken) return;
        // Show error, then navigate back if possible
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load property')),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
        // Do not call setState here to avoid races after navigation/dispose
        return;
      }
    } else {
      if (!mounted || _disposed || token != _loadToken) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
    
    return FormScreen<Property>(
      title: widget.propertyId == null ? 'Add Property' : 'Edit Property',
      initialItem: _initialProperty,
      createNewItem: () => Property(
        propertyId: 0,
        ownerId: 0,
        name: '',
        description: '',
        price: 0.0,
        status: PropertyStatus.available,
        imageIds: [],
        amenityIds: [],
      ),
      formBuilder: (context, property, formKey) {
        // Prepare initial images for the picker: convert existing imageIds to simple maps
        final initialImages = <dynamic>[];
        final ids = property?.imageIds ?? const <int>[];
        if (ids.isNotEmpty) {
          for (final id in ids) {
            initialImages.add({
              'imageId': id,
              'fileName': 'image_$id.jpg',
              'isCover': false,
            });
          }
        }

        return SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PropertyFormFields(key: _fieldsKey, property: property),
                const SizedBox(height: 16),
                Text('Images', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                img_input.ImagePickerInput(
                  initialImages: initialImages,
                  apiService: propertyProvider.api,
                  onChanged: (List<img_input.ImageInfo> imgs) {
                    _pickedImages = imgs;
                  },
                  allowCoverSelection: true,
                  maxImages: 20,
                ),
              ],
            ),
          ),
        );
      },
      onSubmit: (property) async {
        // Use PropertyProvider instead of mock save operation
        try {
          // Build DTO from current form field values (works for both create/edit)
          final dto = _fieldsKey.currentState?.buildUpdatedProperty(base: _initialProperty ?? property) ?? property;
          Property? saved;
          if ((dto.propertyId) == 0) {
            saved = await propertyProvider.createProperty(dto);
          } else {
            saved = await propertyProvider.updateProperty(dto);
          }

          if (saved == null) return false;

          // After save, upload newly picked images (client-side compressed)
          final newImages = _pickedImages.where((i) => i.isNew && i.data != null).toList();
          if (newImages.isNotEmpty) {
            try {
              final imageService = ImageService(propertyProvider.api);
              // Ensure cover image (if any) is first in the list
              newImages.sort((a, b) {
                if (a.isCover == b.isCover) return 0;
                return a.isCover ? -1 : 1;
              });
              final bytesList = newImages.map((i) => i.data!).toList();
              final uploaded = await imageService.uploadImagesForProperty(
                saved.propertyId,
                bytesList,
              );
              // Optionally trigger a refresh to reflect new images (best-effort)
              if (uploaded.isNotEmpty) {
                await propertyProvider.fetchPropertyImages(saved.propertyId, maxImages: 10);
              }
            } catch (e) {
              // Show non-blocking error; property save already succeeded
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Images upload failed: $e')),
                );
              }
            }
          }

          return true;
        } catch (e) {
          // Handle error
          return false;
        }
      },
      onValidationError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
  }
}

class _PropertyFormFields extends StatefulWidget {
  final Property? property;
  
  const _PropertyFormFields({Key? key, required this.property}) : super(key: key);

  @override
  State<_PropertyFormFields> createState() => _PropertyFormFieldsState();
}

class _PropertyFormFieldsState extends State<_PropertyFormFields> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late PropertyStatus _selectedStatus;
  late RentingType _selectedRentingType;
  DateTime? _unavailableFrom;
  DateTime? _unavailableTo;
  
  // Address controllers
  late TextEditingController _streetNameController;
  late TextEditingController _streetNumberController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  
  // Amenities
  List<int> _selectedAmenityIds = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property?.name ?? '');
    _descriptionController = TextEditingController(text: widget.property?.description ?? '');
    _priceController = TextEditingController(text: widget.property?.price.toString() ?? '');
    _selectedStatus = widget.property?.status ?? PropertyStatus.available;
    _selectedRentingType = widget.property?.rentingType ?? RentingType.daily;
    _unavailableFrom = widget.property?.unavailableFrom;
    _unavailableTo = widget.property?.unavailableTo;
    
    // Initialize address controllers
    _streetNameController = TextEditingController(text: widget.property?.address?.streetLine1 ?? '');
    _streetNumberController = TextEditingController(text: widget.property?.address?.streetLine2 ?? '');
    _cityController = TextEditingController(text: widget.property?.address?.city ?? '');
    _postalCodeController = TextEditingController(text: widget.property?.address?.postalCode ?? '');
    _countryController = TextEditingController(text: widget.property?.address?.country ?? '');
    
    // Initialize amenity IDs
    _selectedAmenityIds = List.from(widget.property?.amenityIds ?? []);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _streetNameController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Title is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          AddressInput(
            initialAddress: widget.property?.address,
            onAddressSelected: (address) {
              // Handle address selection if needed
            },
            onManualAddressChanged: () {
              // Handle manual address changes
            },
            streetNameController: _streetNameController,
            streetNumberController: _streetNumberController,
            cityController: _cityController,
            postalCodeController: _postalCodeController,
            countryController: _countryController,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(
              labelText: 'Price',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Price is required';
              }
              if (double.tryParse(value) == null) {
                return 'Price must be a valid number';
              }
              if (double.parse(value) <= 0) {
                return 'Price must be greater than 0';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          PropertyRentingTypeDropdown(
            selected: _selectedRentingType,
            onChanged: (rt) {
              setState(() => _selectedRentingType = rt);
            },
          ),
          const SizedBox(height: 16),
          FutureBuilder<bool>(
            future: _hasTenant(widget.property),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              }
              final hasTenant = snapshot.data ?? false;
              return PropertyStatusTenantAwareDropdown(
                selected: _selectedStatus,
                hasTenant: hasTenant,
                onChanged: (status) {
                  setState(() => _selectedStatus = status);
                },
              );
            },
          ),
          const SizedBox(height: 16),
          PropertyUnavailableDateFields(
            property: widget.property,
            onDateChanged: (from, to) {
              setState(() {
                _unavailableFrom = from;
                _unavailableTo = to;
              });
            },
          ),
          const SizedBox(height: 16),
          AmenityManager(
            mode: AmenityManagerMode.edit,
            initialAmenityIds: _selectedAmenityIds,
            onAmenityIdsChanged: (ids) {
              _selectedAmenityIds = ids;
            },
          ),
        ],
      ),
    );
  }

  // Check if property has an active tenant
  Future<bool> _hasTenant(Property? property) async {
    // For new properties (id=0) or null, there's no tenant
    if (property == null || property.propertyId == 0) return false;
    
    try {
      final provider = Provider.of<PropertyProvider>(context, listen: false);
      final tenantSummary = await provider.fetchCurrentTenantSummary(property.propertyId);
      return tenantSummary != null;
    } catch (e) {
      // If we can't determine tenant status, default to false for safety
      return false;
    }
  }

  // Build a new Property using current field values, preserving unspecified fields from base
  Property buildUpdatedProperty({Property? base}) {
    final parsedPrice = double.tryParse(_priceController.text.trim()) ?? (base?.price ?? 0.0);
    
    // Build address from form fields
    final address = Address(
      streetLine1: _streetNameController.text.trim().isNotEmpty ? _streetNameController.text.trim() : null,
      streetLine2: _streetNumberController.text.trim().isNotEmpty ? _streetNumberController.text.trim() : null,
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      state: base?.address?.state, // State is not in the form, preserve from base if exists
      country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
      postalCode: _postalCodeController.text.trim().isNotEmpty ? _postalCodeController.text.trim() : null,
      latitude: base?.address?.latitude, // Latitude is not in the form, preserve from base if exists
      longitude: base?.address?.longitude, // Longitude is not in the form, preserve from base if exists
    );
    
    return Property(
      propertyId: base?.propertyId ?? 0,
      ownerId: base?.ownerId ?? 0,
      name: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: parsedPrice,
      currency: base?.currency ?? 'USD',
      facilities: base?.facilities,
      status: _selectedStatus,
      dateAdded: base?.dateAdded,
      averageRating: base?.averageRating,
      imageIds: base?.imageIds ?? const [],
      amenityIds: _selectedAmenityIds,
      address: address,
      propertyType: base?.propertyType,
      rentingType: _selectedRentingType,
      rooms: base?.rooms,
      area: base?.area,
      minimumStayDays: base?.minimumStayDays,
      requiresApproval: base?.requiresApproval ?? false,
      unavailableFrom: _unavailableFrom,
      unavailableTo: _unavailableTo,
      coverImageId: base?.coverImageId,
    );
  }
}
