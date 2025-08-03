# eRents Desktop Application API Service Documentation

## Overview

This document provides documentation for the API service used in the eRents desktop application. The API service is a centralized service for handling all HTTP requests to the backend API, providing features like authentication, retry logic, error handling, and image management.

## Service Structure

The API service is located in the `lib/services/api_service.dart` file and provides:

1. HTTP request methods (GET, POST, PUT, DELETE)
2. Authentication token management
3. Retry logic with exponential backoff
4. Error handling and status code mapping
5. Image handling utilities
6. URL construction and validation

## Core Features

### HTTP Request Methods

The API service provides standard HTTP methods with automatic JSON encoding/decoding:

- `get()` - GET requests
- `post()` - POST requests
- `put()` - PUT requests
- `delete()` - DELETE requests

### Authentication

Automatic handling of authentication tokens using SecureStorageService:

- Automatic inclusion of Bearer tokens in authenticated requests
- Client-Type header for desktop identification
- Custom header support for special cases

### Retry Logic

Built-in retry mechanism for handling transient network failures:

- Configurable maximum retries (default: 3)
- Fixed delay between retries (default: 1 second)
- Automatic retry on network failures
- Proper error propagation after max retries

### Error Handling

Centralized error handling with human-readable messages:

- HTTP status code mapping to user-friendly messages
- Automatic response validation
- Detailed error logging
- Exception rethrowing with context

### Image Handling

Specialized image handling utilities:

- Image widget creation from URLs
- Asset vs. network image detection
- Loading, placeholder, and error states
- Image provider creation
- URL validation and conversion

## Implementation Details

### Constructor

```dart
ApiService(this.baseUrl, this.secureStorageService);
```

The service requires:
- `baseUrl`: The base URL for the API
- `secureStorageService`: Service for secure token storage

### Header Management

```dart
Future<Map<String, String>> getHeaders({
  Map<String, String>? customHeaders,
}) async {
  final token = await secureStorageService.getToken();
  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'Client-Type': 'Desktop',
  };
  if (token != null) {
    headers['Authorization'] = 'Bearer $token';
  }
  if (customHeaders != null) {
    headers.addAll(customHeaders);
  }
  return headers;
}
```

### Request Method

```dart
Future<http.Response> _request(
  String endpoint,
  String method,
  Map<String, dynamic>? body, {
  bool authenticated = false,
  Map<String, String>? customHeaders,
}) async {
  int retryCount = 0;
  while (retryCount < maxRetries) {
    try {
      // URL construction
      final url = Uri.parse('${baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'}${endpoint.startsWith('/') ? endpoint.substring(1) : endpoint}');
      final headers = await getHeaders(customHeaders: customHeaders);

      // HTTP method handling
      http.Response response;
      switch (method) {
        case 'POST':
          response = await http.post(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'PUT':
          response = await http.put(
            url,
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          );
          break;
        case 'DELETE':
          response = await http.delete(url, headers: headers);
          break;
        default:
          response = await http.get(url, headers: headers);
      }

      _handleResponse(response);
      return response;
    } catch (e, stackTrace) {
      log.warning(
        'ApiService: Request failed (attempt ${retryCount + 1}/$maxRetries)', e, stackTrace
      );
      retryCount++;
      if (retryCount == maxRetries) {
        rethrow;
      }
      await Future.delayed(retryDelay);
    }
  }
  throw Exception('Failed to complete request after $maxRetries attempts');
}
```

### Response Handling

```dart
void _handleResponse(http.Response response) {
  if (response.statusCode >= 400) {
    String errorMessage;
    switch (response.statusCode) {
      case 400:
        errorMessage = 'Bad Request';
        break;
      case 401:
        errorMessage = 'Unauthorized';
        break;
      case 403:
        errorMessage = 'Forbidden';
        break;
      case 404:
        errorMessage = 'Not Found';
        break;
      case 500:
        errorMessage = 'Internal Server Error';
        break;
      case 502:
        errorMessage = 'Bad Gateway';
        break;
      case 503:
        errorMessage = 'Service Unavailable';
        break;
      default:
        errorMessage = 'HTTP ${response.statusCode}';
    }

    final errorDetails = response.body.isNotEmpty
        ? utf8.decode(response.bodyBytes)
        : 'No additional error details provided';

    throw Exception('$errorMessage: $errorDetails');
  }
}
```

### Image Handling

```dart
Widget buildImage(
  String? imageUrl, {
  BoxFit fit = BoxFit.cover,
  double? width,
  double? height,
  Widget? errorWidget,
}) {
  if (imageUrl == null || imageUrl.isEmpty) {
    return _buildPlaceholderImage(width, height, 'No Image');
  }

  final fullUrl = makeAbsoluteUrl(imageUrl);

  if (isAssetPath(imageUrl)) {
    return Image.asset(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildErrorImage(width, height, 'Image Error');
      },
    );
  } else {
    return Image.network(
      fullUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _buildLoadingImage(width, height);
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? _buildErrorImage(width, height, 'Load Failed');
      },
    );
  }
}
```

## Usage Examples

### Basic API Calls

```dart
final apiService = ApiService('https://api.example.com', secureStorageService);

// GET request
final response = await apiService.get('/properties');
final properties = jsonDecode(response.body);

// POST request
final newProperty = {
  'name': 'New Property',
  'price': 1000,
};
final postResponse = await apiService.post('/properties', newProperty);

// PUT request
final updatedProperty = {
  'id': 1,
  'name': 'Updated Property',
  'price': 1500,
};
final putResponse = await apiService.put('/properties/1', updatedProperty);

// DELETE request
final deleteResponse = await apiService.delete('/properties/1');
```

### Authenticated Requests

```dart
// Authenticated GET request
final userResponse = await apiService.get('/user/profile', authenticated: true);

// Authenticated POST request
final bookingData = {
  'propertyId': 1,
  'startDate': '2023-01-01',
  'endDate': '2023-01-07',
};
final bookingResponse = await apiService.post(
  '/bookings', 
  bookingData, 
  authenticated: true
);
```

### Image Handling

```dart
// Display an image from URL
final imageWidget = apiService.buildImage(
  'https://example.com/image.jpg',
  width: 200,
  height: 150,
  fit: BoxFit.cover,
);

// Display an asset image
final assetImageWidget = apiService.buildImage(
  'assets/images/placeholder.png',
  width: 100,
  height: 100,
);

// Get an image provider
final imageProvider = apiService.buildImageProvider('https://example.com/image.jpg');
```

## Integration with Providers

The API service integrates with providers through ApiServiceExtensions:

```dart
// In a provider
Future<List<Property>?> loadProperties() async {
  return executeWithCache(
    'properties_list',
    () => api.getListAndDecode('/api/properties', Property.fromJson),
    cacheTtl: const Duration(minutes: 5),
  );
}

Future<Property?> createProperty(Property property) async {
  return executeWithState(() async {
    return await api.postAndDecode(
      '/api/properties',
      property.toJson(),
      Property.fromJson,
    );
  });
}
```

## Best Practices

1. **Error Handling**: Always handle API errors appropriately
2. **Authentication**: Use authenticated requests for protected endpoints
3. **Retry Logic**: Leverage built-in retry mechanisms for transient failures
4. **Image Handling**: Use provided image utilities for consistent UI
5. **URL Construction**: Use makeAbsoluteUrl for proper URL handling
6. **Headers**: Use custom headers only when necessary
7. **Logging**: Enable logging for debugging network issues
8. **Security**: Never log sensitive data like tokens
9. **Performance**: Use appropriate timeouts and caching
10. **Testing**: Test API calls with various network conditions

## Extensibility

The API service supports easy extension:

1. **New HTTP Methods**: Add support for other HTTP methods
2. **Custom Headers**: Extend header management for special cases
3. **Response Processing**: Add custom response processing logic
4. **Error Handling**: Extend error handling for specific cases
5. **Image Utilities**: Add new image handling features
6. **URL Management**: Extend URL construction logic
7. **Retry Logic**: Customize retry behavior for specific endpoints
8. **Authentication**: Add support for different auth mechanisms

This API service documentation ensures consistent implementation of HTTP requests and provides a solid foundation for future development.
