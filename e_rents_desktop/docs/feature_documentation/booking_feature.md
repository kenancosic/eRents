# eRents Desktop Application Booking Feature Documentation

## Overview

This document provides detailed documentation for the booking management feature in the eRents desktop application. This feature allows property managers to view, create, edit, and manage property bookings and reservations.

## Feature Structure

The booking feature is organized in the `lib/features/bookings/` directory with the following structure:

```
lib/features/bookings/
├── providers/
│   ├── booking_provider.dart
│   └── booking_form_provider.dart
├── screens/
│   ├── booking_list_screen.dart
│   ├── booking_detail_screen.dart
│   └── booking_form_screen.dart
├── widgets/
│   ├── booking_list_item.dart
│   ├── booking_detail_header.dart
│   └── booking_form_fields.dart
└── models/
    └── booking.dart
```

## Core Components

### Booking Model

The `Booking` model represents a property booking/reservation with the following key properties:

- `id`: Unique identifier
- `propertyId`: Associated property ID
- `tenantId`: Associated tenant ID
- `startDate`: Booking start date
- `endDate`: Booking end date
- `status`: Booking status (pending, confirmed, cancelled, completed)
- `totalAmount`: Total booking amount
- `paidAmount`: Amount paid
- `currency`: Currency code
- `notes`: Additional notes
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### Booking Provider

The `BookingProvider` extends `BaseProvider` and manages booking data with caching and state management:

#### Properties

- `bookings`: List of bookings
- `selectedBooking`: Currently selected booking
- `filter`: Current filter criteria
- `sortColumn`: Current sort column
- `sortAscending`: Sort direction

#### Methods

- `loadBookings()`: Load bookings with caching
- `loadBooking(int id)`: Load a specific booking
- `createBooking(Booking booking)`: Create a new booking
- `updateBooking(Booking booking)`: Update an existing booking
- `deleteBooking(int id)`: Delete a booking
- `applyFilter(String filter)`: Apply filter criteria
- `sortBookings(String column)`: Sort bookings by column

### Booking Form Provider

The `BookingFormProvider` extends `BaseProvider` and manages booking form state:

#### Properties

- `booking`: Booking being edited/created
- `isEditing`: Whether in edit mode
- `formKey`: Form validation key

#### Methods

- `initializeForm([Booking? booking])`: Initialize form with existing booking
- `updateBookingField(String field, dynamic value)`: Update a booking field
- `validateAndSave()`: Validate and save the form
- `resetForm()`: Reset form to initial state

## Screens

### Booking List Screen

Displays a paginated, sortable, and filterable list of bookings using the `DesktopDataTable` widget.

#### Features

- Desktop-optimized data table
- Column sorting
- Text filtering
- Pagination
- Loading and error states
- Create new booking button
- Booking detail navigation

#### Implementation

```dart
// BookingListScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<BookingProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Bookings'),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () => _navigateToForm(context),
            ),
          ],
        ),
        body: ContentWrapper(
          child: Column(
            children: [
              _buildFilterBar(),
              Expanded(
                child: DesktopDataTable<Booking>(
                  data: provider.bookings,
                  columns: _buildColumns(),
                  onRowTap: (booking) => _navigateToDetail(context, booking),
                  onSort: provider.sortBookings,
                  sortColumn: provider.sortColumn,
                  sortAscending: provider.sortAscending,
                  isLoading: provider.isLoading,
                  error: provider.error,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
```

### Booking Detail Screen

Displays detailed information about a specific booking using the generic `DetailScreen` template.

#### Features

- Booking information display
- Property and tenant information
- Date range and status
- Financial details
- Edit and delete actions
- Navigation back to list

#### Implementation

```dart
// BookingDetailScreen widget
@override
Widget build(BuildContext context) {
  return Consumer2<BookingProvider, BookingFormProvider>(
    builder: (context, bookingProvider, formProvider, child) {
      return DetailScreen<Booking>(
        title: 'Booking Details',
        item: bookingProvider.selectedBooking,
        onEdit: () => _navigateToForm(context, bookingProvider.selectedBooking),
        onDelete: () => _confirmDelete(context, bookingProvider.selectedBooking!),
        isLoading: bookingProvider.isLoading,
        error: bookingProvider.error,
        itemBuilder: (booking) => [
          _buildBookingHeader(booking),
          _buildBookingDetails(booking),
          _buildFinancialDetails(booking),
        ],
      );
    },
  );
}
```

### Booking Form Screen

Provides a form for creating or editing bookings using the generic `FormScreen` template.

#### Features

- Form validation
- Date range selection
- Property and tenant selection
- Financial information input
- Status management
- Save and cancel actions

#### Implementation

```dart
// BookingFormScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<BookingFormProvider>(
    builder: (context, provider, child) {
      return FormScreen(
        title: provider.isEditing ? 'Edit Booking' : 'New Booking',
        formKey: provider.formKey,
        onSave: _saveBooking,
        onCancel: _cancelForm,
        isLoading: provider.isLoading,
        error: provider.error,
        children: [
          _buildPropertyTenantFields(),
          _buildDateFields(),
          _buildFinancialFields(),
          _buildStatusNotesFields(),
        ],
      );
    },
  );
}
```

## Widgets

### Booking List Item

A custom widget for displaying booking information in the list view.

### Booking Detail Header

A custom widget for displaying the booking header in the detail view with basic info.

### Booking Form Fields

Custom form field widgets for booking-specific inputs like date ranges and financial information.

## Integration with Base Provider Architecture

The booking feature fully leverages the base provider architecture:

```dart
// BookingProvider using base provider features
class BookingProvider extends BaseProvider<BookingProvider> {
  final ApiService _apiService;
  List<Booking>? _bookings;
  Booking? _selectedBooking;
  
  BookingProvider(this._apiService);
  
  // Cached booking list
  Future<void> loadBookings() async {
    _bookings = await executeWithCache(
      'bookings_list',
      () => executeWithState(() async {
        return await _apiService.getListAndDecode<Booking>(
          '/api/bookings',
          Booking.fromJson,
        );
      }),
      ttl: const Duration(minutes: 5),
    );
    notifyListeners();
  }
  
  // Uncached booking detail
  Future<void> loadBooking(int bookingId) async {
    _selectedBooking = await executeWithState(() async {
      return await _apiService.getAndDecode<Booking>(
        '/api/bookings/$bookingId',
        Booking.fromJson,
      );
    });
    notifyListeners();
  }
  
  // Create with cache invalidation
  Future<Booking?> createBooking(Booking booking) async {
    final createdBooking = await executeWithState(() async {
      return await _apiService.postAndDecode<Booking>(
        '/api/bookings',
        booking.toJson(),
        Booking.fromJson,
      );
    });
    
    if (createdBooking != null) {
      // Invalidate cache after creation
      invalidateCache('bookings_list');
    }
    
    notifyListeners();
    return createdBooking;
  }
  
  // Update with cache invalidation
  Future<Booking?> updateBooking(Booking booking) async {
    final updatedBooking = await executeWithState(() async {
      return await _apiService.putAndDecode<Booking>(
        '/api/bookings/${booking.id}',
        booking.toJson(),
        Booking.fromJson,
      );
    });
    
    if (updatedBooking != null) {
      // Invalidate relevant caches
      invalidateCache('bookings_list');
      invalidateCache('booking_${booking.id}');
    }
    
    notifyListeners();
    return updatedBooking;
  }
  
  // Delete with cache invalidation
  Future<bool> deleteBooking(int bookingId) async {
    final success = await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/bookings/$bookingId');
      // Invalidate relevant caches
      invalidateCache('bookings_list');
      invalidateCache('booking_$bookingId');
    });
    
    if (success) {
      // Clear selected booking if it's the one being deleted
      if (_selectedBooking?.id == bookingId) {
        _selectedBooking = null;
      }
    }
    
    notifyListeners();
    return success;
  }
}
```

## Best Practices

1. **Use Caching Strategically**: Cache list data with shorter TTL, detail data with longer TTL
2. **Invalidate Cache Appropriately**: Clear relevant cache entries after create/update/delete operations
3. **Handle Loading States**: Show loading indicators during API operations
4. **Error Handling**: Use AppError for structured error handling
5. **Form Validation**: Implement comprehensive form validation
6. **Date Validation**: Ensure booking date ranges are valid
7. **Financial Accuracy**: Handle currency and financial calculations properly
8. **Status Management**: Implement proper booking status transitions

## Testing

When testing the booking feature:

```dart
// Test booking provider
void main() {
  late BookingProvider provider;
  late MockApiService mockApiService;
  
  setUp(() {
    mockApiService = MockApiService();
    provider = BookingProvider(mockApiService);
  });
  
  test('loadBookings uses caching', () async {
    final bookings = [
      Booking(id: 1, propertyId: 1, tenantId: 1, startDate: DateTime.now(), endDate: DateTime.now().add(Duration(days: 7))),
      Booking(id: 2, propertyId: 2, tenantId: 2, startDate: DateTime.now().add(Duration(days: 1)), endDate: DateTime.now().add(Duration(days: 8))),
    ];
    
    when(() => mockApiService.getListAndDecode<Booking>(
      any(),
      any(),
    )).thenAnswer((_) async => bookings);
    
    // First call should hit the API
    await provider.loadBookings();
    verify(() => mockApiService.getListAndDecode<Booking>(
      '/api/bookings',
      any(),
    )).called(1);
    
    // Second call should use cache
    await provider.loadBookings();
    // API should still only be called once
    verify(() => mockApiService.getListAndDecode<Booking>(
      '/api/bookings',
      any(),
    )).called(1);
    
    expect(provider.bookings, equals(bookings));
  });
  
  test('createBooking invalidates cache', () async {
    final newBooking = Booking(id: 1, propertyId: 1, tenantId: 1, startDate: DateTime.now(), endDate: DateTime.now().add(Duration(days: 7)));
    
    when(() => mockApiService.postAndDecode<Booking>(
      any(),
      any(),
      any(),
    )).thenAnswer((_) async => newBooking);
    
    await provider.createBooking(newBooking);
    
    // Cache should be invalidated
    final stats = provider.getCacheStats();
    expect(stats['bookings_list']?.invalidationCount, equals(1));
  });
}
```

This documentation ensures consistent implementation of the booking feature and provides a solid foundation for future development.
