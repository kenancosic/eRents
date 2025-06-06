import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/address_detail.dart';
import 'package:e_rents_mobile/core/models/geo_region.dart';
// Removed deprecated image_response import - using unified ImageModel
import 'dart:typed_data'; // For Uint8List
// import 'package:http/http.dart' as http; // Commenting out for mock implementation
// import 'dart:convert'; // Commenting out for mock implementation

class PropertyService {
  // final String _baseUrl = 'https://your-api-url.com/api'; // Commenting out for mock

  Future<Property> getPropertyById(int id) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Mock data store
    final Map<int, Property> mockProperties = {
      1: Property(
        propertyId: 1,
        ownerId: 5,
        name: 'Charming Cottage (Slider Mock)',
        price: 526.00,
        description:
            'A beautiful cottage with a great view, perfect for a relaxing getaway. Displayed from a slider.',
        averageRating: 4.8,
        imageIds: [6, 7],
        amenityIds: [1, 2, 3],
        addressDetail: AddressDetail(
          addressDetailId: 5,
          geoRegionId: 5,
          streetLine1: '100 Slider Lane',
          geoRegion: GeoRegion(
              geoRegionId: 5, city: 'Viewpoint', country: 'USA', state: 'NV'),
        ),
        facilities: "Garden, Patio, BBQ",
        status: PropertyStatus.available,
        dateAdded: DateTime.now().subtract(const Duration(days: 75)),
        rentalType: PropertyRentalType.daily,
        dailyRate: 75.0,
        minimumStayDays: 3,
      ),
      101: Property(
        propertyId: 101,
        ownerId: 1,
        name: 'Cozy Downtown Apartment (from Service)',
        price: 1250.00,
        description:
            'A lovely apartment in the heart of the city, ideal for long-term residence. Fetched via PropertyService.',
        averageRating: 4.7,
        imageIds: [1, 2],
        amenityIds: [1, 4, 5],
        addressDetail: AddressDetail(
          addressDetailId: 1,
          geoRegionId: 1,
          streetLine1: '123 Main St',
          geoRegion: GeoRegion(
              geoRegionId: 1, city: 'Metropolis', country: 'USA', state: 'NY'),
        ),
        // Ensure other potentially required fields are present for the Property model
        // Example: facilities, status, dateAdded, etc., if they are not nullable
        facilities: "Wi-Fi, Kitchen, Air Conditioning",
        status: PropertyStatus.available,
        dateAdded: DateTime.now().subtract(const Duration(days: 100)),
      ),
      201: Property(
        propertyId: 201,
        ownerId: 2,
        name: 'Sunny Beachside Condo (from Service)',
        price: 850.00,
        description:
            'Enjoy the sun and waves in this beautiful condo. Fetched via PropertyService.',
        averageRating: 4.9,
        imageIds: [3],
        amenityIds: [2, 6, 7],
        addressDetail: AddressDetail(
          addressDetailId: 2,
          geoRegionId: 2,
          streetLine1: '456 Ocean Drive',
          geoRegion: GeoRegion(
              geoRegionId: 2, city: 'Sunnyvale', country: 'USA', state: 'CA'),
        ),
        facilities: "Pool, Beach Access, Balcony",
        status: PropertyStatus.rented,
        dateAdded: DateTime.now().subtract(const Duration(days: 50)),
      ),
      202: Property(
        propertyId: 202,
        ownerId: 3,
        name: 'Mountain View Cabin Retreat (from Service)',
        price: 600.00,
        description:
            'Escape to this peaceful cabin with stunning mountain views. Fetched via PropertyService.',
        averageRating: 4.6,
        imageIds: [4],
        amenityIds: [8, 9, 10],
        addressDetail: AddressDetail(
          addressDetailId: 3,
          geoRegionId: 3,
          streetLine1: '789 Pine Trail',
          geoRegion: GeoRegion(
              geoRegionId: 3, city: 'Evergreen', country: 'USA', state: 'CO'),
        ),
        facilities: "Fireplace, Hiking Trails, Hot Tub",
        status: PropertyStatus.available,
        dateAdded: DateTime.now().subtract(const Duration(days: 200)),
      ),
      203: Property(
        propertyId: 203,
        ownerId: 4,
        name: 'Historic Downtown Studio (from Service)',
        price: 475.00,
        description:
            'Charming studio in a historic building, close to everything. Fetched via PropertyService.',
        averageRating: 4.3,
        imageIds: [5],
        amenityIds: [11, 12, 13],
        addressDetail: AddressDetail(
          addressDetailId: 4,
          geoRegionId: 4,
          streetLine1: '10 Park Avenue',
          geoRegion: GeoRegion(
              geoRegionId: 4, city: 'Oldtown', country: 'USA', state: 'MA'),
        ),
        facilities: "Exposed Brick, High Ceilings, Walkable",
        status: PropertyStatus.maintenance,
        dateAdded: DateTime.now().subtract(const Duration(days: 30)),
      ),
      102: Property(
        propertyId: 102,
        ownerId: 6,
        name: 'Beachside Villa Getaway (Service)',
        price: 1200.00,
        description:
            'A stunning villa right by the beach, perfect for your vacation. Mock data from PropertyService.',
        averageRating: 4.9,
        imageIds: [1021],
        amenityIds: [14, 15, 16],
        addressDetail: AddressDetail(
          addressDetailId: 102,
          geoRegionId: 102,
          streetLine1: '1 Beach Rd',
          geoRegion: GeoRegion(
              geoRegionId: 102,
              city: 'Paradise City',
              country: 'USA',
              state: 'FL'),
        ),
        facilities: "Private Pool, Direct Beach Access, Ocean View",
        status: PropertyStatus.available,
        dateAdded: DateTime.now().subtract(const Duration(days: 45)),
      ),
      103: Property(
        propertyId: 103,
        ownerId: 7,
        name: 'Mountain Cabin Retreat (Service)',
        price: 750.00,
        description:
            'Cozy cabin with breathtaking mountain views. Mock data from PropertyService.',
        averageRating: 4.7,
        imageIds: [1031],
        amenityIds: [17, 18, 19],
        addressDetail: AddressDetail(
          addressDetailId: 103,
          geoRegionId: 103,
          streetLine1: '5 Mountain Pass',
          geoRegion: GeoRegion(
              geoRegionId: 103,
              city: 'Peak Valley',
              country: 'USA',
              state: 'MT'),
        ),
        facilities: "Wood Stove, Mountain Hiking, Stargazing Deck",
        status: PropertyStatus.rented,
        dateAdded: DateTime.now().subtract(const Duration(days: 60)),
      ),
      108: Property(
        propertyId: 108,
        ownerId: 8,
        name: 'Starts Today City Pad (Service)',
        price: 250.00,
        description:
            'Modern and convenient pad in the city, available from today! Mock data from PropertyService.',
        averageRating: 4.5,
        imageIds: [1081],
        amenityIds: [20, 21, 22],
        addressDetail: AddressDetail(
          addressDetailId: 108,
          geoRegionId: 108,
          streetLine1: '200 Central Ave',
          geoRegion: GeoRegion(
              geoRegionId: 108, city: 'Downtown', country: 'USA', state: 'TX'),
        ),
        facilities: "Gym, Rooftop Terrace, Concierge",
        status: PropertyStatus.available,
        dateAdded: DateTime.now().subtract(const Duration(days: 10)),
      ),
      300: Property(
        propertyId: 300,
        ownerId: 9,
        name: 'Modern Downtown Apartment - Monthly Lease',
        price: 1850.00, // Monthly rent
        description:
            'Professional downtown apartment perfect for long-term residents. Features modern amenities, secure building, and convenient location. Ideal for professionals and students.',
        averageRating: 4.6,
        imageIds: [3001, 3002],
        amenityIds: [23, 24, 25],
        addressDetail: AddressDetail(
          addressDetailId: 300,
          geoRegionId: 300,
          streetLine1: '500 Main Street',
          geoRegion: GeoRegion(
              geoRegionId: 300, city: 'Downtown', country: 'USA', state: 'NY'),
        ),
        facilities: "In-unit Laundry, Dishwasher, AC/Heat, Parking, Elevator",
        status: PropertyStatus.available,
        dateAdded: DateTime.now().subtract(const Duration(days: 15)),
        rentalType: PropertyRentalType.monthly,
        minimumStayDays: 90, // 3-month minimum lease
      ),
    };

    if (mockProperties.containsKey(id)) {
      return mockProperties[id]!;
    } else {
      // Fallback for any other ID, or throw an error
      // For now, let's throw an exception for unmocked IDs
      throw Exception('Property with ID $id not found in mock service.');
    }
    /* Original HTTP call:
    final response = await http.get(Uri.parse('$_baseUrl/properties/$id'));
    if (response.statusCode == 200) {
      return Property.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to load property');
    }
    */
  }

  Future<List<Property>> getProperties() async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));
    // For now, return an empty list or a list of all mock properties
    // To keep it simple, let's return the values from our mock map
    final Property property101 =
        await getPropertyById(101); // Reuse existing mock data
    final Property property201 = await getPropertyById(201);
    final Property property202 = await getPropertyById(202);
    return [property101, property201, property202];
    /* Original HTTP call:
    final response = await http.get(Uri.parse('$_baseUrl/properties'));
    if (response.statusCode == 200) {
      Iterable list = json.decode(response.body);
      return list.map((model) => Property.fromJson(model)).toList();
    } else {
      throw Exception('Failed to load properties');
    }
    */
  }
}
