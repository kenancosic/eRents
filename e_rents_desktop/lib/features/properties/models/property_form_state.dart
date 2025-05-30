import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/models/address_detail.dart';
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
  List<String> _images = [];
  List<String> _selectedAmenities = [];

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
  List<String> get images => _images;
  List<String> get selectedAmenities => _selectedAmenities;
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

  set images(List<String> value) {
    _images = List.from(value);
    notifyListeners();
  }

  set selectedAmenities(List<String> value) {
    _selectedAmenities = List.from(value);
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
    dailyRateController.text = property.dailyRate?.toString() ?? '';
    minimumStayDaysController.text = property.minimumStayDays?.toString() ?? '';
    currencyController.text = property.currency;
    bedroomsController.text = property.bedrooms.toString();
    bathroomsController.text = property.bathrooms.toString();
    areaController.text = property.area.toString();

    _type = property.type;
    _status = property.status;
    _rentingType = property.rentingType;
    _images = property.images.map((imageInfo) => imageInfo.url!).toList();
    _selectedAmenities = property.amenities ?? [];

    if (property.addressDetail != null) {
      _initialAddressString = property.addressDetail!.streetLine1;
      _selectedFormattedAddress = property.addressDetail!.streetLine1;
      _latitude = property.addressDetail!.latitude;
      _longitude = property.addressDetail!.longitude;

      streetNumberController.text = property.addressDetail!.streetLine1 ?? '';
      streetNameController.text = property.addressDetail!.streetLine2 ?? '';
      cityController.text = property.addressDetail!.geoRegion?.city ?? '';
      postalCodeController.text =
          property.addressDetail!.geoRegion?.postalCode ?? '';
      countryController.text = property.addressDetail!.geoRegion?.country ?? '';
    }

    notifyListeners();
  }

  Property createProperty(int currentUserId, Property? initialProperty) {
    return Property(
      id: initialProperty?.id ?? 0,
      ownerId: initialProperty?.ownerId ?? currentUserId,
      title: titleController.text,
      description: descriptionController.text,
      type: _type,
      price: double.parse(priceController.text),
      rentingType: _rentingType,
      status: _status,
      images: _images.map((img) => erents.ImageInfo(id: 0, url: img)).toList(),
      addressDetail: AddressDetail(
        addressDetailId: initialProperty?.addressDetail?.addressDetailId ?? 0,
        streetLine1:
            streetNumberController.text.trim().isNotEmpty
                ? '${streetNumberController.text.trim()} ${streetNameController.text.trim()}'
                : streetNameController.text.trim(),
        geoRegionId: initialProperty?.addressDetail?.geoRegionId ?? 0,
        geoRegion: initialProperty?.addressDetail?.geoRegion,
        streetLine2:
            _selectedFormattedAddress?.isNotEmpty == true
                ? _selectedFormattedAddress
                : null,
        latitude: _latitude,
        longitude: _longitude,
      ),
      bedrooms: int.parse(bedroomsController.text),
      bathrooms: int.parse(bathroomsController.text),
      area: double.parse(areaController.text),
      maintenanceIssues: initialProperty?.maintenanceIssues ?? [],
      amenities: _selectedAmenities,
      currency: currencyController.text,
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
