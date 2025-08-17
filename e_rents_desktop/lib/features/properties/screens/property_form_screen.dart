import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/enums/property_status.dart';
import 'package:e_rents_desktop/base/crud/form_screen.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/widgets/inputs/image_picker_input.dart' as img_input;
import 'package:e_rents_desktop/services/image_service.dart';
import 'package:provider/provider.dart';

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
                _PropertyFormFields(property: property),
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
      validator: (property) {
        if (property.name.isEmpty) {
          return 'Title is required';
        }
        if (property.address?.getCityStateCountry().isEmpty ?? true) {
          return 'Location is required';
        }
        if (property.price <= 0) {
          return 'Price must be greater than 0';
        }
        return null;
      },
      onSubmit: (property) async {
        // Use PropertyProvider instead of mock save operation
        try {
          Property? saved;
          if (property.propertyId == 0) {
            saved = await propertyProvider.createProperty(property);
          } else {
            saved = await propertyProvider.updateProperty(property);
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
  
  const _PropertyFormFields({required this.property});

  @override
  State<_PropertyFormFields> createState() => _PropertyFormFieldsState();
}

class _PropertyFormFieldsState extends State<_PropertyFormFields> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _priceController;
  late TextEditingController _statusController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.property?.name ?? '');
    _descriptionController = TextEditingController(text: widget.property?.description ?? '');
    _locationController = TextEditingController(text: widget.property?.address?.getCityStateCountry() ?? '');
    _priceController = TextEditingController(text: widget.property?.price.toString() ?? '');
    _statusController = TextEditingController(text: widget.property?.status.displayName ?? 'Available');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _statusController.dispose();
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
          TextFormField(
            controller: _locationController,
            decoration: const InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Location is required';
              }
              return null;
            },
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
          TextFormField(
            controller: _statusController,
            decoration: const InputDecoration(
              labelText: 'Status',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}