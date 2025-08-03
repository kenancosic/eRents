# eRents Desktop Application Payment Feature Documentation

## Overview

This document provides detailed documentation for the payment management feature in the eRents desktop application. This feature allows property managers to view, process, and manage rental payments and financial transactions.

## Feature Structure

The payment feature is organized in the `lib/features/payments/` directory with the following structure:

```
lib/features/payments/
├── providers/
│   ├── payment_provider.dart
│   └── payment_form_provider.dart
├── screens/
│   ├── payment_list_screen.dart
│   ├── payment_detail_screen.dart
│   └── payment_form_screen.dart
├── widgets/
│   ├── payment_list_item.dart
│   ├── payment_detail_header.dart
│   └── payment_form_fields.dart
└── models/
    └── payment.dart
```

## Core Components

### Payment Model

The `Payment` model represents a rental payment transaction with the following key properties:

- `id`: Unique identifier
- `bookingId`: Associated booking ID
- `tenantId`: Associated tenant ID
- `propertyId`: Associated property ID
- `amount`: Payment amount
- `currency`: Currency code
- `paymentMethod`: Payment method used
- `paymentDate`: Date of payment
- `status`: Payment status (pending, completed, failed, refunded)
- `transactionId`: External transaction ID
- `notes`: Additional notes
- `createdAt`: Creation timestamp
- `updatedAt`: Last update timestamp

### Payment Provider

The `PaymentProvider` extends `BaseProvider` and manages payment data with caching and state management:

#### Properties

- `payments`: List of payments
- `selectedPayment`: Currently selected payment
- `filter`: Current filter criteria
- `sortColumn`: Current sort column
- `sortAscending`: Sort direction

#### Methods

- `loadPayments()`: Load payments with caching
- `loadPayment(int id)`: Load a specific payment
- `createPayment(Payment payment)`: Create a new payment
- `updatePayment(Payment payment)`: Update an existing payment
- `deletePayment(int id)`: Delete a payment
- `applyFilter(String filter)`: Apply filter criteria
- `sortPayments(String column)`: Sort payments by column

### Payment Form Provider

The `PaymentFormProvider` extends `BaseProvider` and manages payment form state:

#### Properties

- `payment`: Payment being edited/created
- `isEditing`: Whether in edit mode
- `formKey`: Form validation key

#### Methods

- `initializeForm([Payment? payment])`: Initialize form with existing payment
- `updatePaymentField(String field, dynamic value)`: Update a payment field
- `validateAndSave()`: Validate and save the form
- `resetForm()`: Reset form to initial state

## Screens

### Payment List Screen

Displays a paginated, sortable, and filterable list of payments using the `DesktopDataTable` widget.

#### Features

- Desktop-optimized data table
- Column sorting
- Text filtering
- Pagination
- Loading and error states
- Create new payment button
- Payment detail navigation

#### Implementation

```dart
// PaymentListScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<PaymentProvider>(
    builder: (context, provider, child) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Payments'),
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
                child: DesktopDataTable<Payment>(
                  data: provider.payments,
                  columns: _buildColumns(),
                  onRowTap: (payment) => _navigateToDetail(context, payment),
                  onSort: provider.sortPayments,
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

### Payment Detail Screen

Displays detailed information about a specific payment using the generic `DetailScreen` template.

#### Features

- Payment information display
- Booking and tenant information
- Financial details
- Transaction information
- Edit and delete actions
- Navigation back to list

#### Implementation

```dart
// PaymentDetailScreen widget
@override
Widget build(BuildContext context) {
  return Consumer2<PaymentProvider, PaymentFormProvider>(
    builder: (context, paymentProvider, formProvider, child) {
      return DetailScreen<Payment>(
        title: 'Payment Details',
        item: paymentProvider.selectedPayment,
        onEdit: () => _navigateToForm(context, paymentProvider.selectedPayment),
        onDelete: () => _confirmDelete(context, paymentProvider.selectedPayment!),
        isLoading: paymentProvider.isLoading,
        error: paymentProvider.error,
        itemBuilder: (payment) => [
          _buildPaymentHeader(payment),
          _buildPaymentDetails(payment),
          _buildTransactionDetails(payment),
        ],
      );
    },
  );
}
```

### Payment Form Screen

Provides a form for creating or editing payments using the generic `FormScreen` template.

#### Features

- Form validation
- Amount and currency input
- Payment method selection
- Date selection
- Status management
- Save and cancel actions

#### Implementation

```dart
// PaymentFormScreen widget
@override
Widget build(BuildContext context) {
  return Consumer<PaymentFormProvider>(
    builder: (context, provider, child) {
      return FormScreen(
        title: provider.isEditing ? 'Edit Payment' : 'New Payment',
        formKey: provider.formKey,
        onSave: _savePayment,
        onCancel: _cancelForm,
        isLoading: provider.isLoading,
        error: provider.error,
        children: [
          _buildBookingTenantFields(),
          _buildFinancialFields(),
          _buildPaymentMethodFields(),
          _buildStatusNotesFields(),
        ],
      );
    },
  );
}
```

## Widgets

### Payment List Item

A custom widget for displaying payment information in the list view.

### Payment Detail Header

A custom widget for displaying the payment header in the detail view with basic info.

### Payment Form Fields

Custom form field widgets for payment-specific inputs like financial information and payment methods.

## Integration with Base Provider Architecture

The payment feature fully leverages the base provider architecture:

```dart
// PaymentProvider using base provider features
class PaymentProvider extends BaseProvider<PaymentProvider> {
  final ApiService _apiService;
  List<Payment>? _payments;
  Payment? _selectedPayment;
  
  PaymentProvider(this._apiService);
  
  // Cached payment list
  Future<void> loadPayments() async {
    _payments = await executeWithCache(
      'payments_list',
      () => executeWithState(() async {
        return await _apiService.getListAndDecode<Payment>(
          '/api/payments',
          Payment.fromJson,
        );
      }),
      ttl: const Duration(minutes: 5),
    );
    notifyListeners();
  }
  
  // Uncached payment detail
  Future<void> loadPayment(int paymentId) async {
    _selectedPayment = await executeWithState(() async {
      return await _apiService.getAndDecode<Payment>(
        '/api/payments/$paymentId',
        Payment.fromJson,
      );
    });
    notifyListeners();
  }
  
  // Create with cache invalidation
  Future<Payment?> createPayment(Payment payment) async {
    final createdPayment = await executeWithState(() async {
      return await _apiService.postAndDecode<Payment>(
        '/api/payments',
        payment.toJson(),
        Payment.fromJson,
      );
    });
    
    if (createdPayment != null) {
      // Invalidate cache after creation
      invalidateCache('payments_list');
    }
    
    notifyListeners();
    return createdPayment;
  }
  
  // Update with cache invalidation
  Future<Payment?> updatePayment(Payment payment) async {
    final updatedPayment = await executeWithState(() async {
      return await _apiService.putAndDecode<Payment>(
        '/api/payments/${payment.id}',
        payment.toJson(),
        Payment.fromJson,
      );
    });
    
    if (updatedPayment != null) {
      // Invalidate relevant caches
      invalidateCache('payments_list');
      invalidateCache('payment_${payment.id}');
    }
    
    notifyListeners();
    return updatedPayment;
  }
  
  // Delete with cache invalidation
  Future<bool> deletePayment(int paymentId) async {
    final success = await executeWithStateForSuccess(() async {
      await _apiService.delete('/api/payments/$paymentId');
      // Invalidate relevant caches
      invalidateCache('payments_list');
      invalidateCache('payment_$paymentId');
    });
    
    if (success) {
      // Clear selected payment if it's the one being deleted
      if (_selectedPayment?.id == paymentId) {
        _selectedPayment = null;
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
6. **Financial Accuracy**: Handle currency and financial calculations properly
7. **Transaction Integrity**: Ensure payment transaction data integrity
8. **Status Management**: Implement proper payment status transitions

## Testing

When testing the payment feature:

```dart
// Test payment provider
void main() {
  late PaymentProvider provider;
  late MockApiService mockApiService;
  
  setUp(() {
    mockApiService = MockApiService();
    provider = PaymentProvider(mockApiService);
  });
  
  test('loadPayments uses caching', () async {
    final payments = [
      Payment(id: 1, bookingId: 1, tenantId: 1, amount: 1000, currency: 'USD', paymentDate: DateTime.now()),
      Payment(id: 2, bookingId: 2, tenantId: 2, amount: 1500, currency: 'USD', paymentDate: DateTime.now()),
    ];
    
    when(() => mockApiService.getListAndDecode<Payment>(
      any(),
      any(),
    )).thenAnswer((_) async => payments);
    
    // First call should hit the API
    await provider.loadPayments();
    verify(() => mockApiService.getListAndDecode<Payment>(
      '/api/payments',
      any(),
    )).called(1);
    
    // Second call should use cache
    await provider.loadPayments();
    // API should still only be called once
    verify(() => mockApiService.getListAndDecode<Payment>(
      '/api/payments',
      any(),
    )).called(1);
    
    expect(provider.payments, equals(payments));
  });
  
  test('createPayment invalidates cache', () async {
    final newPayment = Payment(id: 1, bookingId: 1, tenantId: 1, amount: 1000, currency: 'USD', paymentDate: DateTime.now());
    
    when(() => mockApiService.postAndDecode<Payment>(
      any(),
      any(),
      any(),
    )).thenAnswer((_) async => newPayment);
    
    await provider.createPayment(newPayment);
    
    // Cache should be invalidated
    final stats = provider.getCacheStats();
    expect(stats['payments_list']?.invalidationCount, equals(1));
  });
}
```

This documentation ensures consistent implementation of the payment feature and provides a solid foundation for future development.
