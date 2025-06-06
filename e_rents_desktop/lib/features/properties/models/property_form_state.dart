import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart'
    as picker;

class PropertyFormState extends ChangeNotifier {
  // Text controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController bedroomsController = TextEditingController();
  final TextEditingController bathroomsController = TextEditingController();
  final TextEditingController areaController = TextEditingController();
  final TextEditingController dailyRateController = TextEditingController();
  final TextEditingController minimumStayDaysController =
      TextEditingController();
  final TextEditingController currencyController = TextEditingController(
    text: 'BAM',
  );

  // Address controllers
  final TextEditingController streetNameController = TextEditingController();
  final TextEditingController streetNumberController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController countryController = TextEditingController();

  // Form state
  PropertyType _type = PropertyType.apartment;
  PropertyStatus _status = PropertyStatus.available;
  RentingType _rentingType = RentingType.monthly;
  List<picker.ImageInfo> _images = [];
  List<String> _selectedAmenities = [];
  List<int> _selectedAmenityIds = [];

  // Address state
  String? _selectedFormattedAddress;
  String? _initialAddressString;
  double? _latitude;
  double? _longitude;

  // Loading and error state
  bool _isFetchingData = false;
  String? _fetchError;

  // Getters
  PropertyType get type => _type;
  PropertyStatus get status => _status;
  RentingType get rentingType => _rentingType;
  List<picker.ImageInfo> get images => _images;
  List<String> get selectedAmenities => _selectedAmenities;
  List<int> get selectedAmenityIds => _selectedAmenityIds;
  String? get selectedFormattedAddress => _selectedFormattedAddress;
  String? get initialAddressString => _initialAddressString;
  double? get latitude => _latitude;
  double? get longitude => _longitude;
  bool get isFetchingData => _isFetchingData;
  String? get fetchError => _fetchError;

  // Setters
  set type(PropertyType value) {
    _type = value;
    notifyListeners();
  }

  set status(PropertyStatus value) {
    _status = value;
    notifyListeners();
  }

  set rentingType(RentingType value) {
    _rentingType = value;
    notifyListeners();
  }

  set images(List<picker.ImageInfo> value) {
    _images = List.from(value);
    notifyListeners();
  }

  set selectedAmenities(List<String> value) {
    _selectedAmenities = List.from(value);
    notifyListeners();
  }

  set selectedAmenityIds(List<int> value) {
    _selectedAmenityIds = List.from(value);
    notifyListeners();
  }

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
    _selectedFormattedAddress = formattedAddress;
    _latitude = lat;
    _longitude = lng;

    if (streetNumber != null) streetNumberController.text = streetNumber;
    if (streetName != null) streetNameController.text = streetName;
    if (city != null) cityController.text = city;
    if (postalCode != null) postalCodeController.text = postalCode;
    if (country != null) countryController.text = country;

    notifyListeners();
  }

  void setFetchingState(bool loading, [String? error]) {
    _isFetchingData = loading;
    _fetchError = error;
    notifyListeners();
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

    dailyRateController.text = property.dailyRate?.toString() ?? '';
    minimumStayDaysController.text = property.minimumStayDays?.toString() ?? '';

    _type = property.type;
    _rentingType = property.rentingType;
    _status = property.status;

    // Populate address fields if available
    if (property.address != null) {
      final address = property.address!;

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
          }
        } else {
          streetNameController.text = address.streetLine1!;
        }
      }

      cityController.text = address.city ?? '';
      countryController.text = address.country ?? 'Bosnia and Herzegovina';
      postalCodeController.text = address.postalCode ?? '';

      _latitude = address.latitude;
      _longitude = address.longitude;
      _selectedFormattedAddress = address.streetLine2;
    }

    _selectedAmenityIds = property.amenityIds;
    // Note: property.images no longer exists, images are fetched via imageIds from ImageController

    notifyListeners();
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

    return Property(
      propertyId: initialProperty?.propertyId ?? 0,
      ownerId: initialProperty?.ownerId ?? currentUserId,
      name: titleController.text,
      description: descriptionController.text,
      type: _type,
      price: double.parse(priceController.text),
      rentingType: _rentingType,
      status: _status,
      imageIds:
          _images.map((img) => img.id ?? 0).where((id) => id > 0).toList(),
      address: _createAddress(),
      bedrooms: bedrooms > 0 ? bedrooms : 1, // Ensure minimum 1 bedroom
      bathrooms: bathrooms > 0 ? bathrooms : 1, // Ensure minimum 1 bathroom
      area: double.parse(areaController.text),
      maintenanceIssues: initialProperty?.maintenanceIssues ?? [],
      amenityIds: _selectedAmenityIds,
      currency: _sanitizeCurrency(currencyController.text),
      dailyRate:
          dailyRateController.text.isNotEmpty
              ? double.tryParse(dailyRateController.text)
              : null,
      minimumStayDays:
          minimumStayDaysController.text.isNotEmpty
              ? int.tryParse(minimumStayDaysController.text)
              : null,
      dateAdded: initialProperty?.dateAdded ?? DateTime.now(),
    );
  }

  Address? _createAddress() {
    // Only create address if we have meaningful data
    final streetName = streetNameController.text.trim();
    final streetNumber = streetNumberController.text.trim();
    final city = cityController.text.trim();

    if (streetName.isEmpty && city.isEmpty) {
      return null; // No meaningful address data
    }

    // Combine street number and name properly
    String streetLine1;
    if (streetNumber.isNotEmpty && streetName.isNotEmpty) {
      streetLine1 = '$streetNumber $streetName';
    } else if (streetName.isNotEmpty) {
      streetLine1 = streetName;
    } else if (streetNumber.isNotEmpty) {
      streetLine1 = streetNumber;
    } else {
      streetLine1 = city; // Fallback to city if no street info
    }

    return Address(
      streetLine1: streetLine1,
      streetLine2:
          _selectedFormattedAddress?.isNotEmpty == true
              ? _selectedFormattedAddress
              : null,
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
      latitude: _latitude,
      longitude: _longitude,
    );
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
    dailyRateController.dispose();
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
