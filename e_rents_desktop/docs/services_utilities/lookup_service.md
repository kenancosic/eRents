# eRents Desktop Application Lookup Service Documentation

## Overview

This document provides documentation for the lookup service used in the eRents desktop application. The lookup service is responsible for managing lookup data such as property types, renting types, property statuses, and other reference data that is used throughout the application. It extends the API service and provides caching, enum mapping, and data synchronization capabilities.

## Service Structure

The lookup service is located in the `lib/services/lookup_service.dart` file and provides:

1. Lookup data fetching and caching
2. Enum mapping between frontend enums and backend IDs
3. Cache management with TTL (Time To Live)
4. Data synchronization with backend
5. Error handling with fallback mechanisms

## Core Features

### Lookup Data Management

Centralized management of all lookup data:

- `getAllLookupData()` - Fetch all lookup data
- `getPropertyTypes()` - Fetch property types
- `getRentingTypes()` - Fetch renting types
- `getPropertyStatuses()` - Fetch property statuses
- `getUserTypes()` - Fetch user types
- `getBookingStatuses()` - Fetch booking statuses
- `getAmenities()` - Fetch amenities

### Enum Mapping

Bidirectional mapping between frontend enums and backend IDs:

- `getPropertyTypeId()` / `getPropertyTypeEnum()` - Property type mapping
- `getRentingTypeId()` / `getRentingTypeEnum()` - Renting type mapping
- `getPropertyStatusId()` / `getPropertyStatusEnum()` - Property status mapping
- `getUserTypeId()` / `getUserTypeEnum()` - User type mapping
- `getBookingStatusId()` / `getBookingStatusEnum()` - Booking status mapping


### Data Synchronization

Support for both legacy and new enum endpoints:

- Legacy lookup data endpoint support
- New enum endpoint support
- Automatic data synchronization
- Error handling with logging

## Implementation Details

### Constructor

```dart
class LookupService extends ApiService {
  LookupService(super.baseUrl, super.storageService);
  // ...
}
```

The service extends ApiService to inherit HTTP capabilities.

### Data Fetching

```dart
/// Fetch all lookup data from backend
Future<LookupData> getAllLookupData() async {

  log.info('LookupService: Fetching fresh lookup data from backend');

  try {
    final response = await get('/Lookup/all', authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return LookupData.fromJson(jsonResponse);
  } catch (e, stackTrace) {
    log.severe('LookupService: Error fetching lookup data', e, stackTrace);
    rethrow;
  }
}
```

### Enum Mapping

```dart
/// Convert PropertyType enum to backend ID
Future<int> getPropertyTypeId(PropertyType propertyType) async {
  final lookupData = await getAllLookupData();

  // Map enum to expected name
  String typeName = switch (propertyType) {
    PropertyType.apartment => 'Apartment',
    PropertyType.house => 'House',
    PropertyType.condo => 'Condo',
    PropertyType.townhouse => 'Townhouse',
    PropertyType.studio => 'Studio',
  };

  final id = lookupData.getPropertyTypeIdByName(typeName);
  if (id == null) {
    log.warning(
      'LookupService: PropertyType $typeName not found, defaulting to Apartment',
    );
    return lookupData.getPropertyTypeIdByName('Apartment') ?? 1;
  }
  return id;
}

/// Convert backend ID to PropertyType enum
Future<PropertyType> getPropertyTypeEnum(int id) async {
  final lookupData = await getAllLookupData();
  final item = lookupData.getPropertyTypeById(id);

  if (item == null) {
    log.warning(
      'LookupService: PropertyType ID $id not found, defaulting to apartment',
    );
    return PropertyType.apartment;
  }

  return switch (item.name.toLowerCase()) {
    'apartment' => PropertyType.apartment,
    'house' => PropertyType.house,
    'condo' => PropertyType.condo,
    'townhouse' => PropertyType.townhouse,
    'studio' => PropertyType.studio,
    _ => PropertyType.apartment,
  };
}
```


## Usage Examples

### Basic Lookup Data Usage

```dart
final lookupService = LookupService('https://api.example.com', secureStorageService);

// Fetch all lookup data
final lookupData = await lookupService.getAllLookupData();

// Fetch specific lookup data
final propertyTypes = await lookupService.getPropertyTypes();
final rentingTypes = await lookupService.getRentingTypes();
final propertyStatuses = await lookupService.getPropertyStatuses();
```

### Enum Mapping Usage

```dart
// Convert frontend enum to backend ID
final propertyTypeId = await lookupService.getPropertyTypeId(PropertyType.house);
final rentingTypeId = await lookupService.getRentingTypeId(RentingType.monthly);
final propertyStatusId = await lookupService.getPropertyStatusId(PropertyStatus.available);

// Convert backend ID to frontend enum
final propertyType = await lookupService.getPropertyTypeEnum(propertyTypeId);
final rentingType = await lookupService.getRentingTypeEnum(rentingTypeId);
final propertyStatus = await lookupService.getPropertyStatusEnum(propertyStatusId);
```

## Integration with Providers

The lookup service integrates with the LookupProvider:

```dart
// In LookupProvider
Future<List<LookupItem>?> loadPropertyTypes() async {
  return executeWithCache(
    'property_types',
    () => lookupService.getPropertyTypes(),
    cacheTtl: const Duration(hours: 1),
  );
}

Future<PropertyType> getPropertyTypeEnum(int id) async {
  return await lookupService.getPropertyTypeEnum(id);
}

Future<int> getPropertyTypeId(PropertyType type) async {
  return await lookupService.getPropertyTypeId(type);
}
```

## Integration with Models

Models use the lookup service for enum mapping:

```dart
// In Property model
Future<PropertyType> getPropertyTypeEnum(LookupService lookupService) async {
  return await lookupService.getPropertyTypeEnum(propertyTypeId);
}

Future<int> getPropertyTypeId(PropertyType type, LookupService lookupService) async {
  return await lookupService.getPropertyTypeId(type);
}
```

## Error Handling

The lookup service implements robust error handling:

1. **Network Errors**: Fallback to cached data when available
2. **Data Validation**: Validation of lookup data integrity
3. **Enum Mapping**: Default values for unknown enum mappings
4. **Logging**: Comprehensive error logging
5. **Recovery**: Graceful recovery from errors

## Best Practices

1. **Caching**: Leverage built-in caching for performance
2. **Enum Mapping**: Use enum mapping for type safety
3. **Error Handling**: Handle network errors gracefully
4. **Cache Management**: Clear cache when needed
5. **Data Synchronization**: Use appropriate endpoints for data types
6. **Logging**: Enable logging for debugging
7. **Fallback**: Implement fallback mechanisms
8. **Validation**: Validate data after retrieval
9. **Performance**: Use selective data fetching
10. **Testing**: Test with various network conditions

## Extensibility

The lookup service supports easy extension:

1. **New Lookup Types**: Add support for new lookup data types
2. **Custom Endpoints**: Add support for custom lookup endpoints
3. **Cache Policies**: Customize cache duration and policies
4. **Enum Mappings**: Add new enum mapping methods
5. **Data Processing**: Add custom data processing logic
6. **Error Handling**: Extend error handling for specific cases
7. **Logging**: Add custom logging for specific operations
8. **Validation**: Add data validation rules

This lookup service documentation ensures consistent implementation of lookup data management and provides a solid foundation for future development.
