import 'package:flutter/foundation.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/models/enums/renting_type.dart';
import 'package:e_rents_desktop/models/property_status_update_request.dart';
import 'package:e_rents_desktop/features/properties/models/property_form_state.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/services/image_service.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart' as img;
import 'package:e_rents_desktop/utils/logger.dart';

/// Provider for property form state management.
/// Separates business logic from UI, enabling testability and clean architecture.
class PropertyFormProvider extends ChangeNotifier {
  final PropertyProvider _propertyProvider;
  final ImageService _imageService;

  PropertyFormState _state = PropertyFormState.empty();
  PropertyFormState get state => _state;

  // Expose individual state properties for granular rebuilds
  bool get isLoading => _propertyProvider.isLoading;
  bool get isSubmitting => _state.isSubmitting;
  bool get isEditMode => _state.isEditMode;
  bool get isDirty => _state.isDirty;
  String? get errorMessage => _state.errorMessage;
  Map<String, String?> get fieldErrors => _state.fieldErrors;

  PropertyFormProvider({
    required PropertyProvider propertyProvider,
    required ImageService imageService,
  })  : _propertyProvider = propertyProvider,
        _imageService = imageService;

  /// Initialize form for creating a new property
  void initializeForCreate() {
    _state = PropertyFormState.empty();
    notifyListeners();
  }

  /// Initialize form for editing an existing property
  Future<bool> initializeForEdit(int propertyId) async {
    try {
      final property = await _propertyProvider.loadProperty(propertyId);
      if (property == null) {
        _state = _state.copyWith(
          errorMessage: 'Failed to load property',
        );
        notifyListeners();
        return false;
      }

      // Convert existing images to ImageInfo format
      final initialImages = _buildInitialImages(property);
      
      _state = PropertyFormState.fromProperty(property, initialImages: initialImages);
      notifyListeners();
      return true;
    } catch (e) {
      log.severe('Error loading property for edit: $e');
      _state = _state.copyWith(errorMessage: e.toString());
      notifyListeners();
      return false;
    }
  }

  List<img.ImageInfo> _buildInitialImages(Property property) {
    final images = <img.ImageInfo>[];
    for (final id in property.imageIds) {
      images.add(img.ImageInfo(
        id: id,
        fileName: 'image_$id.jpg',
        isCover: id == property.coverImageId,
        isNew: false,
      ));
    }
    return images;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Field Update Methods - Called by individual form sections
  // ═══════════════════════════════════════════════════════════════════════════

  void updateName(String value) {
    if (_state.name != value) {
      _state = _state.copyWith(name: value, isDirty: true, clearError: true);
      _clearFieldError('name');
      notifyListeners();
    }
  }

  void updateDescription(String value) {
    if (_state.description != value) {
      _state = _state.copyWith(description: value, isDirty: true);
      notifyListeners();
    }
  }

  void updatePrice(double value) {
    if (_state.price != value) {
      _state = _state.copyWith(price: value, isDirty: true, clearError: true);
      _clearFieldError('price');
      notifyListeners();
    }
  }

  void updateStatus(PropertyStatus value) {
    if (_state.status != value) {
      _state = _state.copyWith(status: value, isDirty: true);
      notifyListeners();
    }
  }

  void updateRentingType(RentingType value) {
    if (_state.rentingType != value) {
      _state = _state.copyWith(rentingType: value, isDirty: true);
      notifyListeners();
    }
  }

  void updateAddress(Address? address) {
    _state = _state.copyWith(address: address, isDirty: true, clearError: true);
    _clearFieldError('address');
    notifyListeners();
  }

  void updateAmenities(List<int> amenityIds) {
    _state = _state.copyWith(amenityIds: amenityIds, isDirty: true);
    notifyListeners();
  }

  void updateImages(List<img.ImageInfo> images) {
    _state = _state.copyWith(images: images, isDirty: true);
    notifyListeners();
  }

  void updateUnavailableDates(DateTime? from, DateTime? to) {
    _state = _state.copyWith(
      unavailableFrom: from,
      unavailableTo: to,
      isDirty: true,
      clearUnavailableFrom: from == null,
      clearUnavailableTo: to == null,
    );
    notifyListeners();
  }

  void _clearFieldError(String field) {
    if (_state.fieldErrors.containsKey(field)) {
      final newErrors = Map<String, String?>.from(_state.fieldErrors);
      newErrors.remove(field);
      _state = _state.copyWith(fieldErrors: newErrors);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Validation
  // ═══════════════════════════════════════════════════════════════════════════

  bool validate() {
    final errors = _state.validate();
    if (errors.isNotEmpty) {
      _state = _state.copyWith(fieldErrors: errors);
      notifyListeners();
      return false;
    }
    return true;
  }

  String? getFieldError(String field) => _state.fieldErrors[field];

  // ═══════════════════════════════════════════════════════════════════════════
  // Submission - Orchestrates save, image upload, status update
  // ═══════════════════════════════════════════════════════════════════════════

  Future<bool> submit() async {
    if (!validate()) {
      return false;
    }

    _state = _state.copyWith(isSubmitting: true, clearError: true);
    notifyListeners();

    try {
      log.info('=== PROPERTY FORM SUBMIT STARTED ===');
      log.info('Form state address BEFORE save: ${_state.address?.streetLine1}, ${_state.address?.city}');
      
      // Step 1: Save property (create or update)
      final property = _state.toProperty();
      
      final requestJson = property.toRequestJson();
      log.info('API request address fields: streetLine1=${requestJson['streetLine1']}, city=${requestJson['city']}');
      
      Property? saved;
      final originalStatus = _state.isEditMode ? _state.status : null;

      if (_state.isEditMode) {
        log.info('Updating existing property ${property.propertyId}');
        saved = await _propertyProvider.updateProperty(property);
      } else {
        log.info('Creating new property');
        saved = await _propertyProvider.createProperty(property);
      }

      if (saved == null) {
        throw Exception('Failed to save property');
      }

      log.info('Property saved: ${saved.propertyId}');
      log.info('SAVED property address from backend: ${saved.address?.streetLine1}, ${saved.address?.city}');

      // IMPORTANT: Preserve user's images when updating state
      // Backend response has old state, so we keep what the user currently has
      final currentImages = _state.images;
      
      // Keep: new images from user + existing images user still has (not removed)
      final imagesToKeep = <img.ImageInfo>[
        ...currentImages.where((i) => i.isNew), // New images being added
        ...currentImages.where((i) => !i.isNew && i.id != null), // Existing images user kept
      ];

      // Update state with saved property data but preserve user's image selections
      _state = PropertyFormState.fromProperty(saved, initialImages: imagesToKeep).copyWith(
        originalImageIds: _state.originalImageIds, // Keep original for deletion tracking
      );
      log.info('Form state updated after save - address: ${_state.address?.streetLine1}, ${_state.address?.city}');

      // Step 2: Handle status change (edit mode only)
      if (_state.isEditMode && originalStatus != _state.status) {
        await _handleStatusUpdate(saved.propertyId);
      }

      // Step 3: Handle image changes
      await _handleImageChanges(saved);

      _state = _state.copyWith(isSubmitting: false, isDirty: false);
      notifyListeners();
      
      log.info('=== PROPERTY FORM SUBMIT COMPLETED ===');
      return true;
    } catch (e) {
      log.severe('Property save failed: $e');
      _state = _state.copyWith(
        isSubmitting: false,
        errorMessage: e.toString(),
      );
      notifyListeners();
      return false;
    }
  }

  Future<void> _handleStatusUpdate(int propertyId) async {
    try {
      final request = PropertyStatusUpdateRequest(
        status: _state.status,
        unavailableFrom: _state.unavailableFrom,
        unavailableTo: _state.unavailableTo,
      );
      await _propertyProvider.updatePropertyStatus(propertyId, request);
    } catch (e) {
      log.warning('Status update failed (non-blocking): $e');
    }
  }

  Future<void> _handleImageChanges(Property saved) async {
    // Use originalImageIds from form state (images that existed when form loaded)
    final originalImageIds = _state.originalImageIds;
    final currentImageIds = _state.existingImageIds;
    final newImages = _state.newImages;

    log.info('_handleImageChanges: originalImageIds from form state: $originalImageIds');
    log.info('_handleImageChanges: currentImageIds from state: $currentImageIds');
    log.info('_handleImageChanges: newImages count: ${newImages.length}');

    // Find removed images (in original but not in current)
    final removedIds = originalImageIds
        .where((id) => !currentImageIds.contains(id))
        .toList();
    
    log.info('_handleImageChanges: removedIds to delete: $removedIds');

    // Delete removed images
    for (final imageId in removedIds) {
      try {
        await _imageService.deleteImage(imageId);
        log.info('Deleted image $imageId');
      } catch (e) {
        log.warning('Failed to delete image $imageId: $e');
      }
    }

    // Upload new images
    List<int> uploadedIds = [];
    if (newImages.isNotEmpty) {
      try {
        // Sort to ensure cover image is first
        final sortedNew = List<img.ImageInfo>.from(newImages)
          ..sort((a, b) => a.isCover ? -1 : (b.isCover ? 1 : 0));
        
        final bytesList = sortedNew
            .where((i) => i.data != null)
            .map((i) => i.data!)
            .toList();

        final uploaded = await _imageService.uploadImagesForProperty(
          saved.propertyId,
          bytesList,
        );
        uploadedIds = uploaded.map((img) => img.imageId).toList();
        log.info('Uploaded ${uploadedIds.length} images');
      } catch (e) {
        log.warning('Image upload failed (non-blocking): $e');
      }
    }

    // Update property with final image configuration
    final finalImageIds = [...currentImageIds, ...uploadedIds];
    final coverImage = _state.images.firstWhere(
      (i) => i.isCover,
      orElse: () => _state.images.isNotEmpty ? _state.images.first : img.ImageInfo(),
    );
    final coverImageId = coverImage.id ?? 
        (uploadedIds.isNotEmpty ? uploadedIds.first : saved.coverImageId);

    if (finalImageIds.length != originalImageIds.length ||
        !finalImageIds.every((id) => originalImageIds.contains(id)) ||
        coverImageId != saved.coverImageId) {
      
      final updatedProperty = Property(
        propertyId: saved.propertyId,
        ownerId: saved.ownerId,
        name: saved.name,
        description: saved.description,
        price: saved.price,
        currency: saved.currency,
        facilities: saved.facilities,
        status: saved.status,
        dateAdded: saved.dateAdded,
        averageRating: saved.averageRating,
        imageIds: finalImageIds,
        amenityIds: saved.amenityIds,
        address: saved.address,
        propertyType: saved.propertyType,
        rentingType: saved.rentingType,
        rooms: saved.rooms,
        area: saved.area,
        minimumStayDays: saved.minimumStayDays,
        requiresApproval: saved.requiresApproval,
        unavailableFrom: saved.unavailableFrom,
        unavailableTo: saved.unavailableTo,
        coverImageId: coverImageId,
      );
      
      await _propertyProvider.updateProperty(updatedProperty);
      await _propertyProvider.fetchPropertyImages(saved.propertyId, maxImages: 10);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Utilities
  // ═══════════════════════════════════════════════════════════════════════════

  void clearError() {
    _state = _state.copyWith(clearError: true);
    notifyListeners();
  }

  void reset() {
    _state = PropertyFormState.empty();
    notifyListeners();
  }

}
