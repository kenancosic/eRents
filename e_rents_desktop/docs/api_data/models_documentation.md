# eRents Desktop Application Models Documentation

## Overview

This document provides documentation for the core data models used in the eRents desktop application. These models represent the entities that are exchanged between the frontend and backend APIs, and are designed to be robust, flexible, and aligned with the backend data structures.

## Core Models

### Property Model

The `Property` model represents a rental property in the system.

#### Key Features

1. **Flexible ID Handling**: Supports multiple ID field names from backend (`propertyId`, `id`)
2. **Comprehensive Fields**: Includes all relevant property information
3. **Address Integration**: Embedded address object for location data
4. **Amenity Support**: List of amenity IDs for property features
5. **Image Support**: List of image IDs for property photos
6. **Renting Type Integration**: Converts numeric renting type ID to enum
7. **Copy With Pattern**: Immutable updates through copyWith method
8. **JSON Serialization**: Full serialization support for API communication

#### Fields

- `propertyId` (int, required): Unique identifier
- `ownerId` (int, required): Property owner's user ID
- `name` (String, required): Property name/title
- `description` (String, optional): Detailed description
- `price` (double, required): Rental price
- `currency` (String, default: "BAM"): Currency code
- `facilities` (String, optional): Facilities description
- `status` (String, required): Property status
- `dateAdded` (DateTime, optional): When property was added
- `averageRating` (double, optional): Average user rating
- `imageIds` (List<int>, required): Associated image IDs
- `amenityIds` (List<int>, required): Associated amenity IDs
- `address` (Address, optional): Property location
- `propertyTypeId` (int, optional): Property type reference
- `rentingTypeId` (int, optional): Renting type reference
- `bedrooms` (int, optional): Number of bedrooms
- `bathrooms` (int, optional): Number of bathrooms
- `area` (double, optional): Property area in square meters
- `minimumStayDays` (int, optional): Minimum rental period
- `requiresApproval` (bool, default: false): Approval requirement
- `coverImageId` (int, optional): Primary image ID

#### Special Features

- **Renting Type Getter**: Converts numeric ID to `RentingType` enum
- **Flexible Parsing**: Handles various backend response formats
- **Immutable Updates**: Uses copyWith for safe updates

### User Model

The `User` model represents a user in the system, supporting both landlord and tenant roles.

#### Key Features

1. **Role Management**: UserType enum for role differentiation
2. **Address Integration**: Embedded address object
3. **PayPal Integration**: Properties for PayPal linking
4. **Flexible Parsing**: Handles various backend field names
5. **Date Handling**: Robust date parsing with fallbacks
6. **Full Name Computation**: Computed property for display
7. **JSON Serialization**: Complete serialization support

#### Fields

- `id` (int, required): Unique user identifier
- `email` (String, required): User email address
- `username` (String, required): Username
- `firstName` (String, required): First name
- `lastName` (String, required): Last name
- `phone` (String, optional): Phone number
- `role` (UserType, required): User role (landlord/tenant)
- `profileImageId` (int, optional): Profile image reference
- `dateOfBirth` (DateTime, optional): User's birth date
- `createdAt` (DateTime, required): Account creation date
- `updatedAt` (DateTime, required): Last update date
- `address` (Address, optional): User's address
- `isPaypalLinked` (bool, default: false): PayPal link status
- `paypalUserIdentifier` (String, optional): PayPal identifier

#### Special Features

- **UserType Enum**: Strongly-typed role management
- **Full Name Getter**: Computed display name
- **Flexible Backend Mapping**: Handles various backend field names
- **Address Parsing**: Constructs Address from flattened fields

### Address Model

The `Address` model represents a physical address with geolocation data.

#### Key Features

1. **Comprehensive Fields**: All standard address components
2. **Geolocation Support**: Latitude and longitude coordinates
3. **Display Formatting**: Helper methods for address formatting
4. **Empty State Handling**: Proper empty address representation
5. **Equality Support**: Value-based equality comparison

#### Fields

- `streetLine1` (String, optional): Primary street address
- `streetLine2` (String, optional): Secondary street address
- `city` (String, optional): City name
- `state` (String, optional): State/region
- `country` (String, optional): Country name
- `postalCode` (String, optional): Postal/ZIP code
- `latitude` (double, optional): Geographic latitude
- `longitude` (double, optional): Geographic longitude

#### Special Features

- **Empty Address Factory**: Creates properly initialized empty addresses
- **Display Methods**: 
  - `getFullAddress()`: Complete formatted address
  - `getStreetAddress()`: Street portion only
  - `getCityStateCountry()`: City/state/country only
- **Empty State Check**: `isEmpty` and `isNotEmpty` getters
- **Value Equality**: Proper equality and hash code implementation

### Lookup Data Models

Lookup data models represent reference data used throughout the application.

#### LookupItem

Represents a simple ID-Name pair for reference data.

##### Fields
- `id` (int, required): Unique identifier
- `name` (String, required): Display name

##### Features
- **Flexible ID Parsing**: Handles various backend ID field names
- **JSON Serialization**: Complete serialization support
- **Value Equality**: Proper equality and hash code implementation

#### LookupData

Container for all lookup data collections.

##### Fields
- `propertyTypes` (List<LookupItem>): Property type references
- `rentingTypes` (List<LookupItem>): Renting type references
- `userTypes` (List<LookupItem>): User type references
- `bookingStatuses` (List<LookupItem>): Booking status references
- `issuePriorities` (List<LookupItem>): Maintenance issue priorities
- `issueStatuses` (List<LookupItem>): Maintenance issue statuses
- `propertyStatuses` (List<LookupItem>): Property status references
- `amenities` (List<LookupItem>): Amenity references

##### Features
- **Helper Methods**: Quick lookup by ID or name
- `getAmenitiesByIds()`: Retrieve multiple amenities
- **JSON Serialization**: Complete serialization support

### RentingType Enum

Simple enum for property renting types.

#### Values
- `daily`: Daily rental
- `monthly`: Monthly rental

#### Features
- **Display Name Extension**: Human-readable names
- `displayName`: Returns "Daily" or "Monthly"

## Design Patterns

### JSON Serialization

All models implement robust JSON serialization with:

1. **Flexible Field Mapping**: Handles various backend field names
2. **Type Safety**: Proper type conversion with fallbacks
3. **Null Safety**: Graceful handling of missing fields
4. **Error Handling**: Robust parsing with default values

### Immutable Updates

Models use the copyWith pattern for safe updates:

```dart
final updatedProperty = property.copyWith(
  price: newPrice,
  status: newStatus,
);
```

### Value Equality

Models implement proper equality comparison based on identity:

```dart
// Properties are equal if they have the same ID
final isEqual = property1 == property2;
```

## Best Practices

1. **Flexible Parsing**: Models handle various backend response formats
2. **Default Values**: Sensible defaults for missing data
3. **Null Safety**: Proper null handling throughout
4. **Immutable Design**: Safe updates through copyWith pattern
5. **Comprehensive Testing**: Models are designed for easy testing
6. **Backend Alignment**: Closely aligned with backend data structures

## Extensibility

The model architecture supports easy extension:

1. **New Fields**: Add fields with appropriate defaults
2. **New Models**: Follow established patterns
3. **Enum Extensions**: Add new enum values with display names
4. **Helper Methods**: Add convenience methods for common operations

This model documentation ensures consistent data handling across the application and provides a solid foundation for future enhancements.
