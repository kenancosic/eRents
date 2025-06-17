import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart'
    as picker;
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/base/lifecycle_mixin.dart';
import 'package:e_rents_desktop/repositories/property_repository.dart';
import 'package:e_rents_desktop/base/service_locator.dart';
import 'package:e_rents_desktop/services/property_service.dart';
import 'package:e_rents_desktop/services/image_service.dart';

class PropertyFormState extends ChangeNotifier with LifecycleMixin {
  final LookupProvider? lookupProvider;

  // Text controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController bedroomsController = TextEditingController();
  final TextEditingController bathroomsController = TextEditingController();
  final TextEditingController areaController = TextEditingController();

  final TextEditingController minimumStayDaysController =
      TextEditingController();
  final TextEditingController currencyController = TextEditingController(
    text: 'BAM',
  );

  // Address controllers for manual entry
  final TextEditingController streetNameController = TextEditingController();
  final TextEditingController streetNumberController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  // Form state - now using database IDs instead of enums
  int? _propertyTypeId;
  int? _propertyStatusId;
  int? _rentingTypeId;
  List<picker.ImageInfo> _images = [];
  List<String> _selectedAmenities = [];
  List<int> _selectedAmenityIds = [];

  // Unified address state - stores the complete address from Google or manual entry
  Address? _selectedAddress;
  String? _initialAddressString;

  // Loading and error state
  bool _isFetchingData = false;
  String? _fetchError;

  PropertyFormState({this.lookupProvider}) {
    // Initialize with default values if lookup data is available
    _initializeWithDefaults();
  }

  void _initializeWithDefaults() {
    if (lookupProvider?.hasData == true) {
      // Set defaults using the first available options
      final propertyTypes = lookupProvider!.propertyTypes;
      final rentingTypes = lookupProvider!.rentingTypes;
      final propertyStatuses = lookupProvider!.propertyStatuses;

      if (propertyTypes.isNotEmpty) {
        _propertyTypeId = propertyTypes.first.id;
      }
      if (rentingTypes.isNotEmpty) {
        _rentingTypeId = rentingTypes.first.id;
      }
      if (propertyStatuses.isNotEmpty) {
        _propertyStatusId = propertyStatuses.first.id;
      }
    }
  }

  // Getters for database IDs
  int? get propertyTypeId => _propertyTypeId;
  int? get propertyStatusId => _propertyStatusId;
  int? get rentingTypeId => _rentingTypeId;

  // Legacy getters for backward compatibility with enums
  PropertyType get type => _getPropertyTypeEnum();
  PropertyStatus get status => _getPropertyStatusEnum();
  RentingType get rentingType => _getRentingTypeEnum();

  // Other getters
  List<picker.ImageInfo> get images => _images;
  List<String> get selectedAmenities => _selectedAmenities;
  List<int> get selectedAmenityIds => _selectedAmenityIds;
  Address? get selectedAddress => _selectedAddress;
  String? get selectedFormattedAddress => _selectedAddress?.getFullAddress();
  String? get initialAddressString => _initialAddressString;
  double? get latitude => _selectedAddress?.latitude;
  double? get longitude => _selectedAddress?.longitude;
  bool get isFetchingData => _isFetchingData;
  String? get fetchError => _fetchError;

  // Setters for database IDs
  set propertyTypeId(int? value) {
    if (disposed) return;
    _propertyTypeId = value;
    safeNotifyListeners();
  }

  set propertyStatusId(int? value) {
    if (disposed) return;
    _propertyStatusId = value;
    safeNotifyListeners();
  }

  set rentingTypeId(int? value) {
    if (disposed) return;
    _rentingTypeId = value;
    safeNotifyListeners();
  }

  // Legacy setters for backward compatibility with enums
  set type(PropertyType value) {
    if (disposed) return;
    _propertyTypeId = _getPropertyTypeIdFromEnum(value);
    safeNotifyListeners();
  }

  set status(PropertyStatus value) {
    if (disposed) return;
    _propertyStatusId = _getPropertyStatusIdFromEnum(value);
    safeNotifyListeners();
  }

  set rentingType(RentingType value) {
    if (disposed) return;
    _rentingTypeId = _getRentingTypeIdFromEnum(value);
    safeNotifyListeners();
  }

  set images(List<picker.ImageInfo> value) {
    if (disposed) return;
    _images = List.from(value);
    safeNotifyListeners();
  }

  set selectedAmenities(List<String> value) {
    if (disposed) return;
    _selectedAmenities = List.from(value);
    safeNotifyListeners();
  }

  set selectedAmenityIds(List<int> value) {
    if (disposed) return;
    _selectedAmenityIds = List.from(value);
    safeNotifyListeners();
  }

  /// Update address from Google Places API selection
  void updateAddressFromGoogle(Address? address) {
    if (disposed) return;

    _selectedAddress = address;

    if (address != null) {
      // Populate manual fields with Google data for editing
      _populateManualFieldsFromAddress(address);
    }

    safeNotifyListeners();
  }

  /// Update address data from manual input or legacy method
  void updateAddressData({
    String? formattedAddress,
    double? lat,
    double? lng,
    String? streetNumber,
    String? streetName,
    String? city,
    String? postalCode,
    String? country,
  }) {
    // Update manual fields
    if (streetNumber != null) streetNumberController.text = streetNumber;
    if (streetName != null) streetNameController.text = streetName;
    if (city != null) cityController.text = city;
    if (postalCode != null) postalCodeController.text = postalCode;
    if (country != null) countryController.text = country;

    // Create unified address from the data
    _selectedAddress = _createAddressFromManualFields();

    safeNotifyListeners();
  }

  /// Populate manual address fields from Address object
  void _populateManualFieldsFromAddress(Address address) {
    // Parse street line 1 to extract number and name
    if (address.streetLine1?.isNotEmpty == true) {
      final streetParts = address.streetLine1!.split(' ');
      if (streetParts.length > 1) {
        // Try to parse first part as number
        final firstPart = streetParts.first;
        if (int.tryParse(firstPart) != null) {
          streetNumberController.text = firstPart;
          streetNameController.text = streetParts.skip(1).join(' ');
        } else {
          streetNameController.text = address.streetLine1!;
          streetNumberController.text = '';
        }
      } else {
        streetNameController.text = address.streetLine1!;
        streetNumberController.text = '';
      }
    }

    cityController.text = address.city ?? '';
    countryController.text = address.country ?? 'Bosnia and Herzegovina';
    postalCodeController.text = address.postalCode ?? '';
  }

  /// Create Address object from manual field inputs
  Address? _createAddressFromManualFields() {
    final streetName = streetNameController.text.trim();
    final streetNumber = streetNumberController.text.trim();
    final city = cityController.text.trim();

    if (streetName.isEmpty && city.isEmpty) {
      return null; // No meaningful address data
    }

    // Combine street number and name properly
    String? streetLine1;
    if (streetNumber.isNotEmpty && streetName.isNotEmpty) {
      streetLine1 = '$streetNumber $streetName';
    } else if (streetName.isNotEmpty) {
      streetLine1 = streetName;
    } else if (streetNumber.isNotEmpty) {
      streetLine1 = streetNumber;
    }

    return Address(
      streetLine1: streetLine1,
      streetLine2: null,
      city: city.isNotEmpty ? city : null,
      state: null, // Can be added later if needed
      country:
          countryController.text.trim().isNotEmpty
              ? countryController.text.trim()
              : 'Bosnia and Herzegovina',
      postalCode:
          postalCodeController.text.trim().isNotEmpty
              ? postalCodeController.text.trim()
              : null,
      latitude: _selectedAddress?.latitude,
      longitude: _selectedAddress?.longitude,
    );
  }

  /// Update address from manual field changes
  void updateAddressFromManualFields() {
    if (disposed) return;

    _selectedAddress = _createAddressFromManualFields();
    safeNotifyListeners();
  }

  void setFetchingState(bool loading, [String? error]) {
    if (disposed) return;

    _isFetchingData = loading;
    _fetchError = error;
    safeNotifyListeners();
  }

  void populateFromProperty(Property property) {
    titleController.text = property.name;
    descriptionController.text = property.description;
    priceController.text = property.price.toString();
    currencyController.text = _sanitizeCurrency(property.currency);

    // Ensure minimum valid values for bedrooms and bathrooms
    bedroomsController.text =
        (property.bedrooms > 0 ? property.bedrooms : 1).toString();
    bathroomsController.text =
        (property.bathrooms > 0 ? property.bathrooms : 1).toString();
    areaController.text = property.area.toString();

    minimumStayDaysController.text = property.minimumStayDays?.toString() ?? '';

    // Set IDs based on property enums
    _propertyTypeId = _getPropertyTypeIdFromEnum(property.type);
    _rentingTypeId = _getRentingTypeIdFromEnum(property.rentingType);
    _propertyStatusId = _getPropertyStatusIdFromEnum(property.propertyStatus);

    // Populate address
    if (property.address != null) {
      _selectedAddress = property.address;
      _initialAddressString = property.address!.getFullAddress();
      _populateManualFieldsFromAddress(property.address!);
    }

    _selectedAmenityIds = property.amenityIds;

    // Load existing images when editing
    if (property.imageIds.isNotEmpty) {
      _images =
          property.imageIds
              .map(
                (id) => picker.ImageInfo(
                  id: id,
                  url: '/Image/$id', // Provide the API endpoint URL
                  fileName: 'Property Image $id.jpg',
                  isNew: false,
                ),
              )
              .toList();
    }

    safeNotifyListeners();
  }

  /// Sanitize currency to ensure it meets database constraints:
  /// - Only ASCII characters (no Unicode symbols)
  /// - Maximum 10 characters
  /// - Fallback to "BAM" if invalid
  String _sanitizeCurrency(String currency) {
    if (currency.isEmpty) return 'BAM';

    // Remove any non-ASCII characters and trim to max 10 characters
    final sanitized =
        currency.runes
            .where(
              (rune) => rune >= 32 && rune <= 126,
            ) // ASCII printable characters
            .map((rune) => String.fromCharCode(rune))
            .join()
            .trim()
            .toUpperCase();

    if (sanitized.isEmpty || sanitized.length > 10) {
      return 'BAM'; // Fallback to default
    }

    return sanitized;
  }

  Property createProperty(int currentUserId, Property? initialProperty) {
    // Ensure minimum values for bedrooms and bathrooms
    final bedrooms = int.tryParse(bedroomsController.text) ?? 0;
    final bathrooms = int.tryParse(bathroomsController.text) ?? 0;

    // Ensure we have the latest address data from manual fields
    _selectedAddress ??= _createAddressFromManualFields();

    return Property(
      propertyId: initialProperty?.propertyId ?? 0,
      ownerId: initialProperty?.ownerId ?? currentUserId,
      name: titleController.text,
      description: descriptionController.text,
      propertyTypeId: _propertyTypeId,
      price: double.parse(priceController.text),
      rentingTypeId: _rentingTypeId,
      status: _getPropertyStatusEnum().name,
      imageIds:
          _images.map((img) => img.id ?? 0).where((id) => id > 0).toList(),
      address: _selectedAddress,
      bedrooms: bedrooms > 0 ? bedrooms : 1, // Ensure minimum 1 bedroom
      bathrooms: bathrooms > 0 ? bathrooms : 1, // Ensure minimum 1 bathroom
      area: double.parse(areaController.text),
      maintenanceIssues: initialProperty?.maintenanceIssues ?? [],
      amenityIds: _selectedAmenityIds,
      currency: _sanitizeCurrency(currencyController.text),

      minimumStayDays:
          minimumStayDaysController.text.isNotEmpty
              ? int.tryParse(minimumStayDaysController.text)
              : null,
      dateAdded: initialProperty?.dateAdded ?? DateTime.now(),
    );
  }

  /// Get images that need to be uploaded (new images with data but no ID)
  List<picker.ImageInfo> get imagesToUpload {
    return _images
        .where((img) => img.isNew && img.data != null && img.id == null)
        .toList();
  }

  /// Get images that already have IDs (uploaded or existing)
  List<int> get uploadedImageIds {
    return _images
        .where((img) => img.id != null && img.id! > 0)
        .map((img) => img.id!)
        .toList();
  }

  /// Update an image with a new ID after upload
  void updateImageId(picker.ImageInfo oldImage, int newId) {
    final index = _images.indexOf(oldImage);
    if (index != -1) {
      _images[index] = oldImage.copyWith(id: newId, isNew: false);
      safeNotifyListeners();
    }
  }

  /// Upload all new images for a property
  /// Returns a list of image IDs (including both uploaded and existing)
  Future<List<int>> uploadNewImages({int? propertyId}) async {
    final imageService = ServiceLocator().get<ImageService>();
    final imagesToUpload = this.imagesToUpload;
    final uploadedIds = <int>[];

    // Add existing image IDs first
    uploadedIds.addAll(uploadedImageIds);

    // Upload new images
    for (final image in imagesToUpload) {
      if (image.data != null) {
        try {
          print(
            'PropertyFormState: Uploading image ${image.fileName} for property ID: $propertyId',
          );
          final response = await imageService.uploadPropertyImage(
            imageData: image.data!,
            fileName: image.fileName ?? 'image.jpg',
            propertyId: propertyId,
            isCover: image.isCover,
          );
          print('PropertyFormState: Upload response: $response');

          final uploadedImageId = response['imageId'] as int?;
          if (uploadedImageId != null) {
            uploadedIds.add(uploadedImageId);
            // Update the image in our list with the new ID
            updateImageId(image, uploadedImageId);
          }
        } catch (e) {
          print('Failed to upload image ${image.fileName}: $e');
          // Don't throw here - we want to continue uploading other images
          // The caller can check which images failed by comparing counts
        }
      }
    }

    return uploadedIds;
  }

  // Helper methods for enum conversions
  PropertyType _getPropertyTypeEnum() {
    if (_propertyTypeId == null || lookupProvider == null) {
      return PropertyType.apartment; // Default fallback
    }

    final item = lookupProvider!.lookupData?.getPropertyTypeById(
      _propertyTypeId!,
    );
    if (item == null) return PropertyType.apartment;

    return switch (item.name.toLowerCase()) {
      'apartment' => PropertyType.apartment,
      'house' => PropertyType.house,
      'condo' => PropertyType.condo,
      'townhouse' => PropertyType.townhouse,
      'studio' => PropertyType.studio,
      _ => PropertyType.apartment,
    };
  }

  PropertyStatus _getPropertyStatusEnum() {
    if (_propertyStatusId == null || lookupProvider == null) {
      return PropertyStatus.available; // Default fallback
    }

    final item = lookupProvider!.lookupData?.getPropertyStatusById(
      _propertyStatusId!,
    );
    if (item == null) return PropertyStatus.available;

    return switch (item.name.toLowerCase()) {
      'available' => PropertyStatus.available,
      'rented' => PropertyStatus.rented,
      'maintenance' => PropertyStatus.maintenance,
      'unavailable' => PropertyStatus.unavailable,
      _ => PropertyStatus.available,
    };
  }

  RentingType _getRentingTypeEnum() {
    if (_rentingTypeId == null || lookupProvider == null) {
      return RentingType.monthly; // Default fallback
    }

    final item = lookupProvider!.lookupData?.getRentingTypeById(
      _rentingTypeId!,
    );
    if (item == null) return RentingType.monthly;

    return switch (item.name.toLowerCase()) {
      'daily' => RentingType.daily,
      'monthly' => RentingType.monthly,
      _ => RentingType.monthly,
    };
  }

  int? _getPropertyTypeIdFromEnum(PropertyType type) {
    if (lookupProvider == null) return null;

    final typeName = switch (type) {
      PropertyType.apartment => 'Apartment',
      PropertyType.house => 'House',
      PropertyType.condo => 'Condo',
      PropertyType.townhouse => 'Townhouse',
      PropertyType.studio => 'Studio',
    };

    return lookupProvider!.lookupData?.getPropertyTypeIdByName(typeName);
  }

  int? _getPropertyStatusIdFromEnum(PropertyStatus status) {
    if (lookupProvider == null) return null;

    final statusName = switch (status) {
      PropertyStatus.available => 'Available',
      PropertyStatus.rented => 'Rented',
      PropertyStatus.maintenance => 'Maintenance',
      PropertyStatus.unavailable => 'Unavailable',
    };

    return lookupProvider!.lookupData?.getPropertyStatusIdByName(statusName);
  }

  int? _getRentingTypeIdFromEnum(RentingType type) {
    if (lookupProvider == null) return null;

    final typeName = switch (type) {
      RentingType.daily => 'Daily',
      RentingType.monthly => 'Monthly',
    };

    return lookupProvider!.lookupData?.getRentingTypeIdByName(typeName);
  }

  @override
  void dispose() {
    // Dispose all controllers
    titleController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    bedroomsController.dispose();
    bathroomsController.dispose();
    areaController.dispose();

    minimumStayDaysController.dispose();
    currencyController.dispose();
    streetNameController.dispose();
    streetNumberController.dispose();
    cityController.dispose();
    postalCodeController.dispose();
    countryController.dispose();
    super.dispose();
  }
}
