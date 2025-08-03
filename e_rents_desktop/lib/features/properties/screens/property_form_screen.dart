import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/base/crud/form_screen.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPropertyIfNeeded();
  }

  Future<void> _loadPropertyIfNeeded() async {
    if (widget.propertyId != null) {
      final propertyProvider = Provider.of<PropertyProvider>(context, listen: false);
      try {
        _initialProperty = await propertyProvider.loadProperty(widget.propertyId!);
      } catch (e) {
        // Handle error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load property')),
        );
      }
    }
    setState(() {
      _isLoading = false;
    });
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
        status: 'Available',
        imageIds: [],
        amenityIds: [],
      ),
      formBuilder: (context, property, formKey) {
        return _PropertyFormFields(property: property);
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
          if (property.propertyId == 0) {
            // Create new property
            final result = await propertyProvider.createProperty(property);
            return result != null;
          } else {
            // Update existing property
            final result = await propertyProvider.updateProperty(property);
            return result != null;
          }
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
    _statusController = TextEditingController(text: widget.property?.status ?? 'Available');
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