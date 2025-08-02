import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/address.dart';

class MockPropertyService {
  // Mock data storage
  final List<Property> _properties = [
    Property(
      propertyId: 1,
      ownerId: 1,
      name: 'Luxury Apartment',
      description: 'Beautiful apartment with ocean view',
      price: 2500.0,
      status: 'Available',
      imageIds: [],
      amenityIds: [],
      address: Address(
        streetLine1: '123 Ocean Drive',
        city: 'Miami',
        state: 'FL',
        country: 'USA',
        postalCode: '33139',
      ),
    ),
    Property(
      propertyId: 2,
      ownerId: 1,
      name: 'Cozy Studio',
      description: 'Compact and comfortable studio apartment',
      price: 1200.0,
      status: 'Rented',
      imageIds: [],
      amenityIds: [],
      address: Address(
        streetLine1: '456 Broadway',
        city: 'New York',
        state: 'NY',
        country: 'USA',
        postalCode: '10001',
      ),
    ),
    Property(
      propertyId: 3,
      ownerId: 1,
      name: 'Family Home',
      description: 'Spacious family home with garden',
      price: 3500.0,
      status: 'Available',
      imageIds: [],
      amenityIds: [],
      address: Address(
        streetLine1: '789 Garden Lane',
        city: 'Austin',
        state: 'TX',
        country: 'USA',
        postalCode: '78701',
      ),
    ),
  ];

  // Get all properties
  Future<List<Property>> getAllProperties() async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    return List.from(_properties);
  }

  // Get property by ID
  Future<Property?> getPropertyById(String id) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    try {
      return _properties.firstWhere((property) => property.propertyId == (int.tryParse(id) ?? 0));
    } catch (e) {
      return null;
    }
  }

  // Create a new property
  Future<Property> createProperty(Property property) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    final newProperty = property.copyWith(
      propertyId: DateTime.now().millisecondsSinceEpoch,
    );
    _properties.add(newProperty);
    return newProperty;
  }

  // Update an existing property
  Future<Property?> updateProperty(Property property) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    try {
      final index = _properties.indexWhere((p) => p.propertyId == property.propertyId);
      if (index != -1) {
        _properties[index] = property;
        return property;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Delete a property by ID
  Future<bool> deleteProperty(String id) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    try {
      _properties.removeWhere((property) => property.propertyId == (int.tryParse(id) ?? 0));
      return true;
    } catch (e) {
      return false;
    }
  }

  // Search properties by title
  Future<List<Property>> searchProperties(String query) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate network delay
    return _properties
        .where((property) =>
            property.name.toLowerCase().contains(query.toLowerCase()) ||
            (property.description?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
  }
}