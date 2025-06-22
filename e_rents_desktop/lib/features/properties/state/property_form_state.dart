import 'dart:typed_data';

import 'package:e_rents_desktop/base/lifecycle_mixin.dart';
import 'package:e_rents_desktop/features/auth/providers/auth_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_collection_provider.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/services/property_service.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart'
    as picker;
import 'package:flutter/material.dart';

class PropertyFormState extends ChangeNotifier with LifecycleMixin {
  final PropertyService _propertyService;
  final AuthProvider _authProvider;
  final LookupProvider? lookupProvider;
  final PropertyCollectionProvider _collectionProvider;

  late Property _property;
  late List<picker.ImageInfo> _images;

  Property get property => _property;
  List<picker.ImageInfo> get images => _images;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? _initialAddressString;
  String? get initialAddressString => _initialAddressString;

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // Text Controllers
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final priceController = TextEditingController();
  final areaController = TextEditingController();
  final bedroomsController = TextEditingController();
  final bathroomsController = TextEditingController();
  final minimumStayDaysController = TextEditingController();
  final currencyController = TextEditingController();

  final streetNameController = TextEditingController();
  final streetNumberController = TextEditingController();
  final cityController = TextEditingController();
  final postalCodeController = TextEditingController();
  final countryController = TextEditingController();

  PropertyFormState({
    required PropertyService propertyService,
    required AuthProvider authProvider,
    required this.lookupProvider,
    required PropertyCollectionProvider collectionProvider,
    Property? initialProperty,
  }) : _propertyService = propertyService,
       _authProvider = authProvider,
       _collectionProvider = collectionProvider {
    if (initialProperty != null) {
      _property = initialProperty;
      _initialAddressString = initialProperty.address?.getFullAddress();
    } else {
      _property = Property.empty().copyWith(
        propertyTypeId: lookupProvider?.propertyTypes.first.id,
        rentingTypeId: lookupProvider?.rentingTypes.first.id,
      );
    }
    _images = [];
    _initializeControllers();
    _addListeners();
  }

  void _initializeControllers() {
    nameController.text = _property.name;
    descriptionController.text = _property.description;
    priceController.text = _property.price.toString();
    areaController.text = _property.area.toString();
    bedroomsController.text = _property.bedrooms.toString();
    bathroomsController.text = _property.bathrooms.toString();
    minimumStayDaysController.text =
        _property.minimumStayDays?.toString() ?? '';
    currencyController.text = _property.currency;

    final address = _property.address;
    if (address != null) {
      streetNameController.text = address.streetLine1 ?? '';
      streetNumberController.text = address.streetLine2 ?? '';
      cityController.text = address.city ?? '';
      postalCodeController.text = address.postalCode ?? '';
      countryController.text = address.country ?? '';
    }
  }

  void _addListeners() {
    nameController.addListener(() {
      _property = _property.copyWith(name: nameController.text);
    });
    descriptionController.addListener(() {
      _property = _property.copyWith(description: descriptionController.text);
    });
    priceController.addListener(() {
      _property = _property.copyWith(
        price: double.tryParse(priceController.text) ?? 0.0,
      );
    });
    areaController.addListener(() {
      _property = _property.copyWith(
        area: double.tryParse(areaController.text) ?? 0.0,
      );
    });
    bedroomsController.addListener(() {
      _property = _property.copyWith(
        bedrooms: int.tryParse(bedroomsController.text) ?? 0,
      );
    });
    bathroomsController.addListener(() {
      _property = _property.copyWith(
        bathrooms: int.tryParse(bathroomsController.text) ?? 0,
      );
    });
    minimumStayDaysController.addListener(() {
      _property = _property.copyWith(
        minimumStayDays: int.tryParse(minimumStayDaysController.text),
      );
    });
    currencyController.addListener(() {
      _property = _property.copyWith(currency: currencyController.text);
    });

    void updateAddress() {
      _property = _property.copyWith(
        address: (_property.address ?? Address()).copyWith(
          streetLine1: streetNameController.text,
          streetLine2: streetNumberController.text,
          city: cityController.text,
          postalCode: postalCodeController.text,
          country: countryController.text,
        ),
      );
    }

    streetNameController.addListener(updateAddress);
    streetNumberController.addListener(updateAddress);
    cityController.addListener(updateAddress);
    postalCodeController.addListener(updateAddress);
    countryController.addListener(updateAddress);
  }

  void setPropertyTypeId(int? id) {
    _property = _property.copyWith(propertyTypeId: id);
    safeNotifyListeners();
  }

  void setRentingTypeId(int? id) {
    _property = _property.copyWith(rentingTypeId: id);
    safeNotifyListeners();
  }

  void setAmenityIds(List<int> ids) {
    _property = _property.copyWith(amenityIds: ids);
    safeNotifyListeners();
  }

  void setImages(List<picker.ImageInfo> images) {
    _images = images;
    safeNotifyListeners();
  }

  void updateAddressFromGoogle(Address? address) {
    if (address == null) return;

    _property = _property.copyWith(address: address);

    streetNameController.text = address.streetLine1 ?? '';
    streetNumberController.text = address.streetLine2 ?? '';
    cityController.text = address.city ?? '';
    postalCodeController.text = address.postalCode ?? '';
    countryController.text = address.country ?? '';

    safeNotifyListeners();
  }

  List<picker.ImageInfo> get imagesToUpload =>
      _images.where((img) => img.id == null || img.id == 0).toList();

  List<int> get uploadedImageIds =>
      _images
          .where((img) => img.id != null && img.id! > 0)
          .map((img) => img.id!)
          .toList();

  Future<bool> saveProperty() async {
    if (!formKey.currentState!.validate()) {
      _errorMessage = "Please fix the errors above.";
      safeNotifyListeners();
      return false;
    }
    formKey.currentState!.save();

    _isLoading = true;
    _errorMessage = null;
    safeNotifyListeners();

    try {
      final user = _authProvider.currentUser;
      if (user == null) throw Exception('User not authenticated.');

      final propertyToSave = _property.copyWith(ownerId: user.id);

      final imagesToUpload = this.imagesToUpload;
      final imageData = <Uint8List>[];
      final imageFileNames = <String>[];

      for (final image in imagesToUpload) {
        if (image.data != null) {
          imageData.add(image.data!);
          imageFileNames.add(image.fileName ?? 'image.jpg');
        }
      }

      final isEditMode = propertyToSave.propertyId > 0;

      if (isEditMode) {
        await _propertyService.updateProperty(
          propertyToSave.propertyId,
          propertyToSave,
          newImageData: imageData.isNotEmpty ? imageData : null,
          newImageFileNames: imageFileNames.isNotEmpty ? imageFileNames : null,
          existingImageIds:
              uploadedImageIds.isNotEmpty ? uploadedImageIds : null,
        );
      } else {
        await _propertyService.createProperty(
          propertyToSave,
          newImageData: imageData.isNotEmpty ? imageData : null,
          newImageFileNames: imageFileNames.isNotEmpty ? imageFileNames : null,
        );
      }

      await _collectionProvider.clearCacheAndRefresh();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save property: $e';
      return false;
    } finally {
      _isLoading = false;
      safeNotifyListeners();
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    priceController.dispose();
    areaController.dispose();
    bedroomsController.dispose();
    bathroomsController.dispose();
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
