import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/models/enums/renting_type.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart' as img;

/// Immutable state class for property form data.
/// Separates form state from UI to enable predictable state transitions.
class PropertyFormState {
  final int propertyId;
  final int ownerId;
  final String name;
  final String description;
  final double price;
  final String currency;
  final PropertyStatus status;
  final RentingType rentingType;
  final Address? address;
  final List<int> amenityIds;
  final List<img.ImageInfo> images;
  final int? coverImageId;
  final DateTime? unavailableFrom;
  final DateTime? unavailableTo;
  final bool hasTenant;
  
  // Form metadata
  final bool isEditMode;
  final bool isDirty;
  final List<int> originalImageIds;
  final bool isSubmitting;
  final String? errorMessage;
  final Map<String, String?> fieldErrors;

  const PropertyFormState({
    this.propertyId = 0,
    this.ownerId = 0,
    this.name = '',
    this.description = '',
    this.price = 0.0,
    this.currency = 'USD',
    this.status = PropertyStatus.available,
    this.rentingType = RentingType.daily,
    this.address,
    this.amenityIds = const [],
    this.images = const [],
    this.coverImageId,
    this.unavailableFrom,
    this.unavailableTo,
    this.hasTenant = false,
    this.isEditMode = false,
    this.isDirty = false,
    this.originalImageIds = const [],
    this.isSubmitting = false,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  /// Create form state from existing Property (edit mode)
  factory PropertyFormState.fromProperty(Property property, {List<img.ImageInfo>? initialImages}) {
    final images = initialImages ?? [];
    // Extract original image IDs from the initial images (since property.imageIds is empty from backend)
    final originalIds = images
        .where((i) => !i.isNew && i.id != null)
        .map((i) => i.id!)
        .toList();
    
    return PropertyFormState(
      propertyId: property.propertyId,
      ownerId: property.ownerId,
      name: property.name,
      description: property.description ?? '',
      price: property.price,
      currency: property.currency,
      status: property.status,
      rentingType: property.rentingType ?? RentingType.daily,
      address: property.address,
      amenityIds: List.from(property.amenityIds),
      images: images,
      coverImageId: property.coverImageId,
      unavailableFrom: property.unavailableFrom,
      unavailableTo: property.unavailableTo,
      hasTenant: property.status == PropertyStatus.occupied,
      isEditMode: true,
      originalImageIds: originalIds,
    );
  }

  /// Create empty form state (create mode)
  factory PropertyFormState.empty() => const PropertyFormState();

  PropertyFormState copyWith({
    int? propertyId,
    int? ownerId,
    String? name,
    String? description,
    double? price,
    String? currency,
    PropertyStatus? status,
    RentingType? rentingType,
    Address? address,
    List<int>? amenityIds,
    List<img.ImageInfo>? images,
    int? coverImageId,
    DateTime? unavailableFrom,
    DateTime? unavailableTo,
    bool? hasTenant,
    bool? isEditMode,
    bool? isDirty,
    List<int>? originalImageIds,
    bool? isSubmitting,
    String? errorMessage,
    Map<String, String?>? fieldErrors,
    bool clearError = false,
    bool clearUnavailableFrom = false,
    bool clearUnavailableTo = false,
  }) {
    return PropertyFormState(
      propertyId: propertyId ?? this.propertyId,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      isDirty: isDirty ?? this.isDirty,
      originalImageIds: originalImageIds ?? this.originalImageIds,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      rentingType: rentingType ?? this.rentingType,
      address: address ?? this.address,
      amenityIds: amenityIds ?? this.amenityIds,
      images: images ?? this.images,
      coverImageId: coverImageId ?? this.coverImageId,
      unavailableFrom: clearUnavailableFrom ? null : (unavailableFrom ?? this.unavailableFrom),
      unavailableTo: clearUnavailableTo ? null : (unavailableTo ?? this.unavailableTo),
      hasTenant: hasTenant ?? this.hasTenant,
      isEditMode: isEditMode ?? this.isEditMode,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  /// Convert form state to Property model for API submission
  Property toProperty() {
    return Property(
      propertyId: propertyId,
      ownerId: ownerId,
      name: name,
      description: description,
      price: price,
      currency: currency,
      status: status,
      rentingType: rentingType,
      address: address,
      amenityIds: amenityIds,
      imageIds: images.where((i) => !i.isNew && i.id != null).map((i) => i.id!).toList(),
      coverImageId: coverImageId,
      unavailableFrom: unavailableFrom,
      unavailableTo: unavailableTo,
    );
  }

  /// Validate form state and return error messages
  Map<String, String?> validate() {
    final errors = <String, String?>{};
    
    if (name.trim().isEmpty) {
      errors['name'] = 'Property name is required';
    }
    
    if (price <= 0) {
      errors['price'] = 'Price must be greater than 0';
    }
    
    if (address == null || 
        (address!.streetLine1?.isEmpty ?? true) || 
        (address!.city?.isEmpty ?? true)) {
      errors['address'] = 'Street and city are required';
    }
    
    return errors;
  }

  bool get isValid => validate().isEmpty;

  /// Get new images that need to be uploaded
  List<img.ImageInfo> get newImages => images.where((i) => i.isNew && i.data != null).toList();

  /// Get existing image IDs
  List<int> get existingImageIds => images.where((i) => !i.isNew && i.id != null).map((i) => i.id!).toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PropertyFormState &&
          runtimeType == other.runtimeType &&
          propertyId == other.propertyId &&
          name == other.name &&
          description == other.description &&
          price == other.price &&
          status == other.status;

  @override
  int get hashCode => Object.hash(propertyId, name, description, price, status);
}
