# eRents Desktop Application Desktop Data Table Documentation

## Overview

This document provides detailed documentation for the `DesktopDataTable` widget used in the eRents desktop application. This widget is a reusable, desktop-optimized data table component that provides sorting, pagination, and error handling capabilities.

## Widget Structure

The `DesktopDataTable` widget is located in the `lib/base/widgets/desktop_data_table.dart` file and provides:

1. Desktop-optimized data table display
2. Column sorting capabilities
3. Loading and error states
4. Responsive design
5. Customizable styling

## Properties

### Required Properties

#### data

```dart
List<T> data
```

The list of data items to display in the table.

#### columns

```dart
List<DesktopDataColumn<T>> columns
```

The column definitions for the table.

#### onRowTap

```dart
void Function(T item)? onRowTap
```

Callback function when a row is tapped.

### Optional Properties

#### sortColumn

```dart
String? sortColumn
```

The currently sorted column.

#### sortAscending

```dart
bool sortAscending = true
```

Whether sorting is ascending.

#### onSort

```dart
void Function(String column)? onSort
```

Callback function when a column header is clicked for sorting.

#### isLoading

```dart
bool isLoading = false
```

Whether data is currently loading.

#### error

```dart
AppError? error
```

Current error state.

#### onRetry

```dart
VoidCallback? onRetry
```

Callback function when retry is clicked after an error.

#### emptyMessage

```dart
String emptyMessage = 'No data available'
```

Message to display when there is no data.

## DesktopDataColumn

The `DesktopDataColumn` class defines a column in the data table.

### Properties

#### label

```dart
String label
```

The display label for the column header.

#### property

```dart
String property
```

The property name used for sorting.

#### builder

```dart
Widget Function(T item) builder
```

Function to build the cell content for each item.

#### sortable

```dart
bool sortable = true
```

Whether the column is sortable.

#### width

```dart
double? width
```

Fixed width for the column.

#### alignment

```dart
TextAlign alignment = TextAlign.left
```

Text alignment for the column.

## Usage Examples

### Basic Usage

```dart
// Simple data table
DesktopDataTable<User>(
  data: users,
  columns: [
    DesktopDataColumn<User>(
      label: 'Name',
      property: 'name',
      builder: (user) => Text(user.name),
    ),
    DesktopDataColumn<User>(
      label: 'Email',
      property: 'email',
      builder: (user) => Text(user.email),
    ),
    DesktopDataColumn<User>(
      label: 'Role',
      property: 'role',
      builder: (user) => Text(user.role.toString()),
    ),
  ],
  onRowTap: (user) => _navigateToUserDetail(user),
)
```

### With Sorting

```dart
// Data table with sorting
DesktopDataTable<Property>(
  data: properties,
  columns: [
    DesktopDataColumn<Property>(
      label: 'Name',
      property: 'name',
      builder: (property) => Text(property.name),
      sortable: true,
    ),
    DesktopDataColumn<Property>(
      label: 'Type',
      property: 'propertyType',
      builder: (property) => Text(property.propertyType.toString()),
      sortable: true,
    ),
    DesktopDataColumn<Property>(
      label: 'Price',
      property: 'rentalPrice',
      builder: (property) => Text(
        kCurrencyFormat.format(property.rentalPrice),
        textAlign: TextAlign.right,
      ),
      sortable: true,
      alignment: TextAlign.right,
    ),
  ],
  sortColumn: sortColumn,
  sortAscending: sortAscending,
  onSort: (column) => _sortProperties(column),
  onRowTap: (property) => _navigateToPropertyDetail(property),
)
```

### With Loading and Error States

```dart
// Data table with loading and error handling
DesktopDataTable<Tenant>(
  data: tenants,
  columns: [
    DesktopDataColumn<Tenant>(
      label: 'Name',
      property: 'name',
      builder: (tenant) => Text(tenant.name),
    ),
    DesktopDataColumn<Tenant>(
      label: 'Email',
      property: 'email',
      builder: (tenant) => Text(tenant.email),
    ),
    DesktopDataColumn<Tenant>(
      label: 'Phone',
      property: 'phone',
      builder: (tenant) => Text(tenant.phone ?? ''),
    ),
  ],
  isLoading: isLoading,
  error: error,
  onRetry: _loadTenants,
  onRowTap: (tenant) => _navigateToTenantDetail(tenant),
)
```

## Integration with Providers

The `DesktopDataTable` works seamlessly with providers:

```dart
// In a widget using a provider
@override
Widget build(BuildContext context) {
  return Consumer<PropertyProvider>(
    builder: (context, provider, child) {
      return DesktopDataTable<Property>(
        data: provider.properties ?? [],
        columns: [
          // Column definitions
        ],
        sortColumn: provider.sortColumn,
        sortAscending: provider.sortAscending,
        onSort: provider.sortProperties,
        isLoading: provider.isLoading,
        error: provider.error,
        onRetry: provider.loadProperties,
        onRowTap: (property) => _navigateToPropertyDetail(context, property),
      );
    },
  );
}
```

## Customization

### Custom Styling

```dart
// Custom styled data table
DesktopDataTable<Booking>(
  data: bookings,
  columns: [
    // Column definitions
  ],
  onRowTap: (booking) => _navigateToBookingDetail(booking),
  emptyMessage: 'No bookings found',
  // Custom styling can be applied through theme
)
```

### Fixed Width Columns

```dart
// Data table with fixed width columns
DesktopDataTable<Payment>(
  data: payments,
  columns: [
    DesktopDataColumn<Payment>(
      label: 'Date',
      property: 'paymentDate',
      builder: (payment) => Text(
        AppDateUtils.formatDate(payment.paymentDate),
      ),
      width: 120,
    ),
    DesktopDataColumn<Payment>(
      label: 'Amount',
      property: 'amount',
      builder: (payment) => Text(
        kCurrencyFormat.format(payment.amount),
        textAlign: TextAlign.right,
      ),
      width: 100,
      alignment: TextAlign.right,
    ),
    DesktopDataColumn<Payment>(
      label: 'Status',
      property: 'status',
      builder: (payment) => Text(payment.status.toString()),
      width: 100,
    ),
  ],
  onRowTap: (payment) => _showPaymentDetail(payment),
)
```

## Best Practices

1. **Use Appropriate Column Types**: Match column builders to data types
2. **Enable Sorting Selectively**: Only make sortable columns that users will actually sort
3. **Handle Loading States**: Show loading indicators during data fetch
4. **Error Handling**: Provide retry mechanisms for error states
5. **Empty States**: Provide meaningful empty state messages
6. **Responsive Design**: Ensure tables work well on different screen sizes
7. **Performance**: Use efficient builders for large datasets
8. **Accessibility**: Ensure proper contrast and keyboard navigation

## Testing

When testing the `DesktopDataTable` widget:

```dart
// Test the DesktopDataTable widget
void main() {
  testWidgets('DesktopDataTable displays data correctly', (WidgetTester tester) async {
    final properties = [
      Property(id: 1, name: 'Property 1', propertyType: PropertyType.Apartment),
      Property(id: 2, name: 'Property 2', propertyType: PropertyType.House),
    ];
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopDataTable<Property>(
            data: properties,
            columns: [
              DesktopDataColumn<Property>(
                label: 'Name',
                property: 'name',
                builder: (property) => Text(property.name),
              ),
              DesktopDataColumn<Property>(
                label: 'Type',
                property: 'propertyType',
                builder: (property) => Text(property.propertyType.toString()),
              ),
            ],
          ),
        ),
      ),
    );
    
    // Verify data is displayed
    expect(find.text('Property 1'), findsOneWidget);
    expect(find.text('Property 2'), findsOneWidget);
    expect(find.text('Apartment'), findsOneWidget);
    expect(find.text('House'), findsOneWidget);
  });
  
  testWidgets('DesktopDataTable handles loading state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopDataTable<Property>(
            data: [],
            columns: [
              // Column definitions
            ],
            isLoading: true,
          ),
        ),
      ),
    );
    
    // Verify loading indicator is shown
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
  
  testWidgets('DesktopDataTable handles empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DesktopDataTable<Property>(
            data: [],
            columns: [
              // Column definitions
            ],
            emptyMessage: 'No properties found',
          ),
        ),
      ),
    );
    
    // Verify empty message is shown
    expect(find.text('No properties found'), findsOneWidget);
  });
}
```

This documentation ensures consistent implementation of the `DesktopDataTable` widget and provides a solid foundation for future development.
