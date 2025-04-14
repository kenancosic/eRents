# BaseProvider

## Overview

`BaseProvider<T>` is a foundational abstract class that provides generic state management functionality for the eRents application. It serves as the base for all other providers in the application, implementing common functionality like CRUD operations, state tracking, error handling, and mock data support.

## Class Definition

```dart
abstract class BaseProvider<T> extends ChangeNotifier {
  // Properties and methods
}
```

## Key Properties

| Property | Type | Description |
|----------|------|-------------|
| `state` | `ViewState` | Current loading state (Idle, Busy, Error) |
| `errorMessage` | `String?` | Current error message, if any |
| `items_` | `List<T>` | Internal list of items |
| `items` | `List<T>` | Public getter for items (unmodifiable) |
| `useMockData_` | `bool` | Whether to use mock data instead of API |

## Key Methods

### State Management

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `setState` | `ViewState state` | `void` | Updates the provider state and notifies listeners |
| `setError` | `String message` | `void` | Sets error message and error state |
| `clearError` | - | `void` | Clears any error message |

### Data Operations

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `fetchItems` | - | `Future<void>` | Fetches items from API or mock data |
| `addItem` | `T item` | `Future<void>` | Adds a new item to the collection |
| `updateItem` | `T item` | `Future<void>` | Updates an existing item |
| `deleteItem` | `T item` | `Future<void>` | Deletes an item from the collection |
| `execute` | `Function action` | `Future<void>` | Executes an action with proper state handling |

### Data Conversion

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `fromJson` | `Map<String, dynamic> json` | `T` | Abstract method to convert JSON to item type |
| `toJson` | `T item` | `Map<String, dynamic>` | Abstract method to convert item to JSON |

### Mock Data Support

| Method | Parameters | Return Type | Description |
|--------|------------|-------------|-------------|
| `enableMockData` | - | `void` | Enables use of mock data |
| `disableMockData` | - | `void` | Disables use of mock data |
| `getMockItems` | - | `List<T>` | Abstract method to get mock items |

## Implementation Details

### State Management

The provider implements a simple state management system:

```dart
enum ViewState { Idle, Busy, Error }
```

This allows components to show appropriate UI based on the current state:
- **Idle**: Data is loaded and ready
- **Busy**: Loading operation in progress
- **Error**: An error occurred

### Error Handling

Error handling is centralized through the `setError` and `clearError` methods:

```dart
void setError(String message) {
  errorMessage = message;
  setState(ViewState.Error);
}

void clearError() {
  errorMessage = null;
}
```

### Execution Pattern

The `execute` method implements a common pattern for async operations:

```dart
Future<void> execute(Function action) async {
  try {
    setState(ViewState.Busy);
    clearError();
    await action();
    setState(ViewState.Idle);
  } catch (e) {
    setError(e.toString());
  }
}
```

This ensures consistent state transitions and error handling across all provider operations.

### Mock Data Support

Mock data is supported through the `useMockData_` flag and the `getMockItems` abstract method:

```dart
Future<void> fetchItems() async {
  await execute(() async {
    if (useMockData_) {
      items_ = getMockItems();
      return;
    }
    
    // API call implementation
    // ...
  });
}
```

## Usage Example

Concrete providers must implement the abstract methods:

```dart
class UserProvider extends BaseProvider<User> {
  @override
  User fromJson(Map<String, dynamic> json) {
    return User.fromJson(json);
  }
  
  @override
  Map<String, dynamic> toJson(User item) {
    return item.toJson();
  }
  
  @override
  List<User> getMockItems() {
    return [
      User(id: '1', name: 'John Doe'),
      User(id: '2', name: 'Jane Smith'),
    ];
  }
  
  @override
  String get endpoint => 'api/users';
}
```

## Design Considerations

1. **Generic Type Parameter**: The class uses a generic type parameter `<T>` to ensure type safety throughout the provider.

2. **ChangeNotifier**: Extending ChangeNotifier allows the provider to use Flutter's built-in observer pattern for UI updates.

3. **Abstract Methods**: Key methods are made abstract to enforce proper implementation in concrete classes.

4. **Error Handling**: Centralized error handling simplifies error management throughout the application.

5. **Mock Data Support**: Built-in support for mock data makes development and testing easier. 