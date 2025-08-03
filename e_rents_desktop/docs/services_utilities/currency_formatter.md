# eRents Desktop Application Currency Formatter Documentation

## Overview

This document provides documentation for the currency formatter used in the eRents desktop application. The currency formatter provides a standardized way to format monetary values throughout the rental management system, specifically for Bosnian Marks (KM) as the primary currency.

## Utility Structure

The currency formatter is located in the `lib/utils/formatters.dart` file and provides:

1. Global currency formatting for Bosnian Marks (KM)
2. Locale-specific formatting using the Bosnian locale
3. Consistent currency symbol display

## Core Features

### Currency Formatting

Standardized currency formatting for monetary values:

- `kCurrencyFormat` - Global formatter for Bosnian Marks (KM)

## Implementation Details

### Global Formatter

```dart
import 'package:intl/intl.dart';

/// Global currency formatter for Bosnian Marks (KM).
final kCurrencyFormat = NumberFormat.currency(
  locale: 'bs_BA', // Bosnian locale
  symbol: 'KM', // Currency symbol
);
```

The formatter uses:
- **Locale**: `bs_BA` (Bosnian locale for Bosnia and Herzegovina)
- **Symbol**: `KM` (Bosnian Marks currency symbol)
- **Package**: `intl` for internationalization support

## Usage Examples

### Basic Currency Formatting

```dart
import 'package:e_rents_desktop/utils/formatters.dart';

// Format monetary values
final formatted1 = kCurrencyFormat.format(100); // "100.00 KM"
final formatted2 = kCurrencyFormat.format(1234.56); // "1,234.56 KM"
final formatted3 = kCurrencyFormat.format(0); // "0.00 KM"

// In widgets
Text(kCurrencyFormat.format(property.price));
Text(kCurrencyFormat.format(booking.totalAmount));
Text(kCurrencyFormat.format(payment.amount));
```

### Integration with Models

```dart
// In Property model
class Property {
  final double price;
  
  String get formattedPrice => kCurrencyFormat.format(price);
}

// In Booking model
class Booking {
  final double totalAmount;
  
  String get formattedTotal => kCurrencyFormat.format(totalAmount);
}

// In Payment model
class Payment {
  final double amount;
  
  String get formattedAmount => kCurrencyFormat.format(amount);
}
```

### Integration with Widgets

```dart
// In PropertyCardWidget
Text(
  property.formattedPrice,
  style: Theme.of(context).textTheme.titleMedium,
);

// In BookingSummaryWidget
Text(
  'Total: ${booking.formattedTotal}',
  style: Theme.of(context).textTheme.titleLarge,
);

// In PaymentHistoryWidget
Text(payment.formattedAmount);
```

## Integration with Providers

The currency formatter integrates with providers for consistent monetary value display:

```dart
// In PropertyProvider
class PropertyProvider extends BaseProvider {
  final ApiService _apiService;
  
  Future<List<Property>> loadProperties() async {
    return executeWithCache(
      'properties_list',
      () async {
        final response = await _apiService.get('/Property', authenticated: true);
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Property.fromJson(json)).toList();
      },
      cacheTtl: const Duration(minutes: 5),
    );
  }
  
  // Properties automatically use the formatter through their models
}

// In BookingProvider
class BookingProvider extends BaseProvider {
  final ApiService _apiService;
  
  String formatBookingTotal(double amount) {
    return kCurrencyFormat.format(amount);
  }
}
```

## Best Practices

1. **Consistency**: Use the global formatter throughout the application
2. **Model Integration**: Add formatted properties to models for easy access
3. **Null Safety**: Handle null monetary values gracefully
4. **Precision**: Maintain appropriate decimal precision for currency
5. **Localization**: Consider localization requirements for other currencies
6. **Performance**: Currency formatting is lightweight but avoid excessive calls
7. **Testing**: Test formatting with various monetary values
8. **Boundary Cases**: Handle edge cases like very large or very small values
9. **User Experience**: Ensure formatted values are user-friendly
10. **Documentation**: Document currency choices and formatting decisions

## Extensibility

The currency formatter supports easy extension:

1. **Multiple Currencies**: Add support for additional currencies
2. **Custom Locales**: Add formatters for different locales
3. **Format Configuration**: Add configurable formatting options
4. **Business Logic**: Add business-specific formatting rules
5. **Currency Conversion**: Add currency conversion capabilities
6. **Symbol Variants**: Add different symbol representations
7. **Decimal Control**: Add customizable decimal places
8. **Grouping Options**: Add different number grouping patterns

This currency formatter documentation ensures consistent implementation of monetary value formatting and provides a solid foundation for future development.
