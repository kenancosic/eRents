# eRents Desktop Application Logger Documentation

## Overview

This document provides documentation for the logging system used in the eRents desktop application. The logger provides a centralized logging mechanism for debugging, error tracking, and application monitoring throughout the rental management system.

## Utility Structure

The logger is located in the `lib/utils/logger.dart` file and provides:

1. Global logger instance for the application
2. Centralized logging setup and configuration
3. Consistent logging format across the application
4. Error and stack trace logging

## Core Features

### Logger Instance

Global logger instance for the application:

- `log` - Global Logger instance named 'ERentsApp'

### Logging Setup

Centralized logging configuration:

- `setupLogging()` - Configure logging levels and output

## Implementation Details

### Global Logger

```dart
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

final log = Logger('ERentsApp');
```

The global logger uses:
- **Package**: `logging` for structured logging
- **Name**: 'ERentsApp' for application identification
- **Scope**: Global access throughout the application

### Logging Setup

```dart
void setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((rec) {
    debugPrint('${rec.level.name}: ${rec.time}: ${rec.message}');
    if (rec.error != null) {
      debugPrint('ERROR: ${rec.error}');
    }
    if (rec.stackTrace != null) {
      debugPrint(rec.stackTrace.toString());
    }
  });
}
```

The setup configures:
- **Level**: `Level.ALL` to capture all log levels
- **Output**: `debugPrint` for console output
- **Format**: Consistent format with level, time, and message
- **Error Handling**: Special handling for errors and stack traces

## Usage Examples

### Basic Logging Setup

```dart
// In main.dart
import 'package:e_rents_desktop/utils/logger.dart';

void main() {
  setupLogging();
  // ...
  runApp(MyApp());
}
```

### Logging in Providers

```dart
import 'package:e_rents_desktop/utils/logger.dart';

// In PropertyProvider
class PropertyProvider extends BaseProvider {
  final ApiService _apiService;
  
  Future<List<Property>> loadProperties() async {
    log.info('Loading properties from API');
    
    try {
      final response = await _apiService.get('/Property', authenticated: true);
      log.info('Properties loaded successfully, count: ${data.length}');
      // ...
    } catch (e, stackTrace) {
      log.severe('Failed to load properties', e, stackTrace);
      rethrow;
    }
  }
  
  Future<Property?> loadProperty(int id) async {
    log.info('Loading property with id: $id');
    
    try {
      final response = await _apiService.get('/Property/$id', authenticated: true);
      log.info('Property loaded successfully: $id');
      // ...
    } catch (e, stackTrace) {
      log.severe('Failed to load property: $id', e, stackTrace);
      rethrow;
    }
  }
}
```

### Logging in Services

```dart
import 'package:e_rents_desktop/utils/logger.dart';

// In ApiService
class ApiService {
  final String baseUrl;
  final SecureStorageService secureStorageService;
  
  Future<http.Response> get(String endpoint, {bool authenticated = false}) async {
    log.fine('Making GET request to: $endpoint');
    
    try {
      final url = Uri.parse('$baseUrl$endpoint');
      final headers = <String, String>{};
      
      if (authenticated) {
        final token = await secureStorageService.getToken();
        if (token != null) {
          headers['Authorization'] = 'Bearer $token';
        }
      }
      
      final response = await http.get(url, headers: headers);
      log.fine('GET request completed with status: ${response.statusCode}');
      
      return response;
    } catch (e, stackTrace) {
      log.severe('GET request failed for endpoint: $endpoint', e, stackTrace);
      rethrow;
    }
  }
}
```

### Logging in Widgets

```dart
import 'package:e_rents_desktop/utils/logger.dart';

// In PropertyListWidget
class PropertyListWidget extends StatefulWidget {
  @override
  _PropertyListWidgetState createState() => _PropertyListWidgetState();
}

class _PropertyListWidgetState extends State<PropertyListWidget> {
  @override
  void initState() {
    super.initState();
    log.info('PropertyListWidget initialized');
  }
  
  @override
  Widget build(BuildContext context) {
    log.fine('Building PropertyListWidget');
    
    return Consumer<PropertyProvider>(
      builder: (context, provider, child) {
        if (provider.hasError) {
          log.warning('PropertyListWidget showing error state');
          return ErrorDisplay(provider.errorMessage);
        }
        
        if (provider.isLoading) {
          log.fine('PropertyListWidget showing loading state');
          return LoadingIndicator();
        }
        
        log.fine('PropertyListWidget showing ${provider.properties.length} properties');
        return PropertyListView(properties: provider.properties);
      },
    );
  }
}
```

## Integration with Error Handling

The logger integrates with the error handling system:

```dart
// In AppError
class AppError implements Exception {
  final String message;
  final String? debugMessage;
  final int? statusCode;
  final StackTrace? stackTrace;
  
  AppError.fromException(Object e, [StackTrace? stackTrace])
      : message = e.toString(),
        debugMessage = e.toString(),
        statusCode = null,
        stackTrace = stackTrace ?? StackTrace.current {
    log.severe('AppError created from exception: $message', e, stackTrace);
  }
  
  AppError.fromHttpResponse(int statusCode, String response)
      : message = _getMessageFromStatusCode(statusCode),
        debugMessage = response,
        statusCode = statusCode,
        stackTrace = StackTrace.current {
    log.severe('AppError created from HTTP response: $statusCode - $response');
  }
}
```

## Best Practices

1. **Consistent Usage**: Use the global logger throughout the application
2. **Appropriate Levels**: Use appropriate log levels (fine, info, warning, severe)
3. **Context Information**: Include relevant context in log messages
4. **Error Logging**: Always log errors with stack traces
5. **Performance**: Avoid excessive logging in performance-critical code
6. **Security**: Avoid logging sensitive information
7. **Debugging**: Use fine-level logging for detailed debugging
8. **Monitoring**: Use info-level logging for important events
9. **Warnings**: Use warning-level logging for recoverable issues
10. **Errors**: Use severe-level logging for critical errors

## Log Levels

The logger supports standard logging levels:

1. **FINE**: Detailed information for debugging
2. **INFO**: General information about application flow
3. **WARNING**: Warning conditions that may indicate problems
4. **SEVERE**: Error events that may cause the application to fail

## Extensibility

The logger supports easy extension:

1. **Custom Levels**: Add custom log levels for specific needs
2. **Multiple Outputs**: Add support for file logging or remote logging
3. **Filtering**: Add log filtering based on categories or levels
4. **Formatting**: Add custom log formatting options
5. **Performance Monitoring**: Add performance tracking to logs
6. **Analytics Integration**: Add integration with analytics platforms
7. **Structured Logging**: Add support for structured log data
8. **Log Rotation**: Add log file rotation capabilities

This logger documentation ensures consistent implementation of logging throughout the application and provides a solid foundation for debugging and monitoring.
