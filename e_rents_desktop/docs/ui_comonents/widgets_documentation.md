# eRents Desktop Application Widgets Documentation

## Overview

This document provides documentation for the key reusable widgets used in the eRents desktop application. These widgets provide consistent UI components and functionality across the application.

## Core Widgets

### DesktopDataTable

A reusable data table widget optimized for desktop applications with sorting, pagination, and error handling.

#### Features

1. **Generic Implementation**: Works with any data type T
2. **Loading States**: Built-in loading indicator
3. **Error Handling**: Displays error messages with retry option
4. **Empty States**: Customizable empty message
5. **Sorting**: Column sorting with callbacks
6. **Refresh**: Pull-to-refresh functionality
7. **Responsive Design**: Horizontal scrolling for wide tables

#### Usage

```dart
DesktopDataTable<MyModel>(
  items: myItems,
  columns: [
    DataColumn(label: Text('Name')),
    DataColumn(label: Text('Status')),
  ],
  rowsBuilder: (context, items) {
    return items.map((item) => DataRow(
      cells: [
        DataCell(Text(item.name)),
        DataCell(Text(item.status)),
      ],
    )).toList();
  },
  onRowTap: (item) => handleRowTap(item),
  loading: isLoading,
  errorMessage: error,
  onRefresh: () => refreshData(),
)
```

#### Parameters

- `items`: List of data items to display
- `columns`: List of DataColumn definitions
- `rowsBuilder`: Function to build DataRow objects
- `onRowTap`: Callback when a row is tapped
- `rowsPerPage`: Number of rows per page (default: 10)
- `sortAscending`: Sort direction (default: true)
- `sortColumnIndex`: Currently sorted column index
- `onSort`: Callback when column header is sorted
- `loading`: Loading state indicator
- `errorMessage`: Error message to display
- `onRefresh`: Refresh callback function
- `emptyMessage`: Message to show when no data
- `sortFieldNames`: Field names for API sorting

### AppNavigationBar

The main navigation bar widget that provides consistent navigation across the application.

#### Features

1. **Route-based Selection**: Highlights current route
2. **SVG Logo**: Custom logo display
3. **Profile Integration**: User profile access
4. **Logout Functionality**: Integrated logout
5. **Responsive Design**: Fixed width optimized for desktop
6. **Visual Feedback**: Hover and selection states

#### Structure

```dart
class NavigationItem {
  final String label;
  final IconData icon;
  final String path;
}

static const List<NavigationItem> navigationItems = [
  NavigationItem(label: 'Home', icon: Icons.home_rounded, path: '/'),
  NavigationItem(label: 'Chat', icon: Icons.chat_rounded, path: '/chat'),
  // ... other navigation items
];
```

#### Key Methods

- `_isItemSelected()`: Determines if navigation item is selected
- `_buildNavigationRail()`: Main navigation rail layout
- `_buildNavigationItems()`: Builds list of navigation items
- `_buildNavigationItem()`: Builds individual navigation item
- `_buildLogoutButton()`: Logout functionality
- `_buildHeader()`: Application logo header
- `_buildProfile()`: User profile access

### CustomButton

A reusable button widget with consistent styling and loading states.

#### Features

1. **Loading State**: Built-in loading indicator
2. **Icon Support**: Optional leading/trailing icons
3. **Size Variants**: Different button sizes
4. **Style Consistency**: Uses theme colors and styling
5. **Disabled State**: Proper disabled appearance

#### Usage

```dart
CustomButton(
  text: 'Save',
  onPressed: () => saveData(),
  isLoading: isSaving,
  icon: Icons.save,
)
```

### CustomAvatar

A reusable avatar widget with customizable styling.

#### Features

1. **Image Support**: Display user images
2. **Placeholder**: Default avatar when no image
3. **Border Customization**: Customizable border
4. **Size Variants**: Different avatar sizes

#### Usage

```dart
CustomAvatar(
  imageUrl: 'assets/images/user-image.png',
  size: 40,
  borderWidth: 2,
)
```

### LoadingOrErrorWidget

A utility widget for displaying loading or error states.

#### Features

1. **Loading Indicator**: Circular progress indicator
2. **Error Display**: Error message with retry option
3. **Empty State**: Customizable empty message
4. **Consistent Styling**: Uses theme-appropriate styling

#### Usage

```dart
LoadingOrErrorWidget(
  loading: isLoading,
  error: errorMessage,
  onRetry: () => retryOperation(),
  emptyMessage: 'No data found',
)
```

### StatusChip

A chip widget for displaying status information.

#### Features

1. **Color Coding**: Different colors for different statuses
2. **Icon Support**: Optional status icons
3. **Customizable Text**: Flexible label content
4. **Consistent Styling**: Theme-appropriate appearance

#### Usage

```dart
StatusChip(
  status: 'Active',
  color: Colors.green,
  icon: Icons.check_circle,
)
```

## Widget Organization

### Common Widgets

Located in `widgets/common/`:
- Reusable utility widgets
- Form components
- Layout helpers

### Input Widgets

Located in `widgets/inputs/`:
- Custom input fields
- Form controls
- Validation helpers

### Filter Widgets

Located in `widgets/filters/`:
- Data filtering components
- Search utilities
- Filter chips

### Table Widgets

Located in `widgets/table/`:
- Data table components
- Cell renderers
- Table utilities

### Dropdown Widgets

Located in `widgets/dropdowns/`:
- Custom dropdown components
- Selection utilities
- Multi-select components

## Best Practices

1. **Reusability**: Create generic widgets for common functionality
2. **Consistency**: Use theme colors and styling
3. **State Management**: Handle loading and error states in widgets
4. **Accessibility**: Ensure proper contrast and sizing
5. **Performance**: Optimize widget rebuilds
6. **Documentation**: Document widget parameters and usage
7. **Testing**: Create testable widget components
8. **Responsive Design**: Consider different screen sizes

## Extensibility

The widget architecture supports easy extension:

1. **New Widgets**: Create in appropriate subdirectories
2. **Widget Variants**: Extend existing widgets with new parameters
3. **Custom Styling**: Add new styling options
4. **Functionality Extensions**: Add new features to existing widgets
5. **Composition**: Combine widgets for complex UI components

This widget documentation ensures consistent UI components across the application and provides a solid foundation for future enhancements.
