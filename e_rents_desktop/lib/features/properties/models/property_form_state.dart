import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/models/address_detail.dart';
import 'package:e_rents_desktop/models/geo_region.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart'
    as picker;
import 'package:e_rents_desktop/models/image_info.dart' as erents;

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
    titleController.text = property.title;
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
    if (property.addressDetail != null) {
      final address = property.addressDetail!;

      // Parse street line 1 to extract number and name
      final streetParts = address.streetLine1.split(' ');
      if (streetParts.length > 1) {
        // Try to parse first part as number
        final firstPart = streetParts.first;
        if (int.tryParse(firstPart) != null) {
          streetNumberController.text = firstPart;
          streetNameController.text = streetParts.skip(1).join(' ');
        } else {
          streetNameController.text = address.streetLine1;
        }
      } else {
        streetNameController.text = address.streetLine1;
      }

      if (address.geoRegion != null) {
        cityController.text = address.geoRegion!.city;
        countryController.text =
            address.geoRegion!.country ?? 'Bosnia and Herzegovina';
        postalCodeController.text = address.geoRegion!.postalCode ?? '';
      }

      _latitude = address.latitude;
      _longitude = address.longitude;
      _selectedFormattedAddress = address.streetLine2;
    }

    _selectedAmenities = property.amenities ?? [];
    _selectedAmenityIds = property.amenityIds ?? [];
    _images =
        property.images
            .where((img) => img.url?.isNotEmpty == true)
            .map(
              (img) => picker.ImageInfo(
                id: img.id,
                fileName: img.fileName,
                url: img.url,
                isCover: img.isCover,
                isNew: false,
              ),
            )
            .toList();

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
      id: initialProperty?.id ?? 0,
      ownerId: initialProperty?.ownerId ?? currentUserId,
      title: titleController.text,
      description: descriptionController.text,
      type: _type,
      price: double.parse(priceController.text),
      rentingType: _rentingType,
      status: _status,
      images:
          _images
              .map(
                (img) => erents.ImageInfo(
                  id: img.id ?? 0,
                  url: img.url,
                  fileName: img.fileName,
                  isCover: img.isCover,
                ),
              )
              .toList(),
      addressDetail: _createAddressDetail(initialProperty),
      bedrooms: bedrooms > 0 ? bedrooms : 1, // Ensure minimum 1 bedroom
      bathrooms: bathrooms > 0 ? bathrooms : 1, // Ensure minimum 1 bathroom
      area: double.parse(areaController.text),
      maintenanceIssues: initialProperty?.maintenanceIssues ?? [],
      amenities: _selectedAmenities, // Keep for backward compatibility
      amenityIds: _selectedAmenityIds, // NEW: Efficient backend communication
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

  AddressDetail? _createAddressDetail(Property? initialProperty) {
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

    return AddressDetail(
      addressDetailId: initialProperty?.addressDetail?.addressDetailId,
      streetLine1: streetLine1,
      geoRegionId: initialProperty?.addressDetail?.geoRegionId,
      geoRegion: _createGeoRegion(initialProperty),
      streetLine2:
          _selectedFormattedAddress?.isNotEmpty == true
              ? _selectedFormattedAddress
              : null,
      latitude: _latitude,
      longitude: _longitude,
    );
  }

  GeoRegion? _createGeoRegion(Property? initialProperty) {
    final city = cityController.text.trim();
    final country = countryController.text.trim();
    final postalCode = postalCodeController.text.trim();

    if (city.isEmpty && country.isEmpty) {
      return initialProperty
          ?.addressDetail
          ?.geoRegion; // Keep existing if no new data
    }

    return GeoRegion(
      geoRegionId: initialProperty?.addressDetail?.geoRegion?.geoRegionId,
      city:
          city.isNotEmpty
              ? city
              : (initialProperty?.addressDetail?.geoRegion?.city ?? ''),
      state: initialProperty?.addressDetail?.geoRegion?.state,
      country:
          country.isNotEmpty
              ? country
              : (initialProperty?.addressDetail?.geoRegion?.country ??
                  'Bosnia and Herzegovina'),
      postalCode:
          postalCode.isNotEmpty
              ? postalCode
              : initialProperty?.addressDetail?.geoRegion?.postalCode,
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
