import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
// TODO: Consider using flutter_dotenv to load API key from .env file
// import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Result wrapper for Places Autocomplete to carry both predictions and error context
class PlacesAutocompleteResult {
  final List<dynamic> predictions;
  final String status;
  final String? errorMessage;

  const PlacesAutocompleteResult({
    required this.predictions,
    required this.status,
    this.errorMessage,
  });
}

class GooglePlacesService {
  // TODO: Load API key securely, e.g., from environment variables
  // final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 'YOUR_API_KEY_FALLBACK';
  // For now, using a placeholder. Replace this with your actual key loading mechanism.
  final String _apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? '';

  final String _autocompleteBaseUrl =
      'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  final String _detailsBaseUrl =
      'https://maps.googleapis.com/maps/api/place/details/json';

  GooglePlacesService() {
    // Debug: Check if the API key is loaded correctly
    if (_apiKey.isEmpty) {
      debugPrint(
          'WARNING: Google Places API Key is not set. Please configure it in .env file');
    } else {
      final maskedKey = '${_apiKey.substring(0, 8)}...${_apiKey.substring(_apiKey.length - 4)}';
      debugPrint('GooglePlacesService: API Key loaded: $maskedKey');
    }
  }

 

  /// Fetches place autocomplete suggestions from the Google Places API.
  ///
  /// [input] The text string on which to search.
  /// [sessionToken] A random string which identifies an autocomplete session for billing purposes.
  ///                It should be generated for each session.
  /// [types] Restricts the results to places matching the specified type (e.g., 'geocode', '(cities)').
  /// [language] The language code, indicating in which language the results should be returned, if possible.
  /// [components] A grouping of places to which you would like to restrict your results.
  ///              Currently, you can use components to filter by up to 5 countries (e.g., "country:us|country:ca").
  Future<PlacesAutocompleteResult> getAutocompleteSuggestions(
    String input,
    String sessionToken, {
    String? types, // e.g., '(cities)' to search for cities
    String? language,
    String? components, // e.g., 'country:us'
  }) async {
    if (input.isEmpty) {
      return PlacesAutocompleteResult(predictions: const [], status: 'NO_INPUT');
    }

    String url =
        '$_autocompleteBaseUrl?input=$input&key=$_apiKey&sessiontoken=$sessionToken';
    if (types != null) url += '&types=$types';
    if (language != null) url += '&language=$language';
    if (components != null) url += '&components=$components';

    try {
      debugPrint('GooglePlaces: Requesting autocomplete for "$input"');
      final response = await http.get(Uri.parse(url));
      debugPrint('GooglePlaces: Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('GooglePlaces: API status: ${data['status']}');
        
        if (data['status'] == 'OK') {
          final predictions = data['predictions'] as List<dynamic>;
          debugPrint('GooglePlaces: Found ${predictions.length} predictions');
          return PlacesAutocompleteResult(
            predictions: predictions,
            status: 'OK',
          );
        }
        // Handle other statuses like ZERO_RESULTS, REQUEST_DENIED, etc.
        debugPrint(
            'Google Places Autocomplete API Error: ${data['status']} - ${data['error_message']}');
        return PlacesAutocompleteResult(
          predictions: const [],
          status: (data['status'] as String?) ?? 'ERROR',
          errorMessage: (data['error_message'] as String?) ?? 'Autocomplete failed',
        );
      } else {
        // Handle HTTP error
        debugPrint('HTTP Error fetching autocomplete: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        return PlacesAutocompleteResult(
          predictions: const [],
          status: 'HTTP_${response.statusCode}',
          errorMessage: 'HTTP ${response.statusCode} while fetching autocomplete',
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Exception fetching autocomplete: $e');
      debugPrint('Stack trace: $stackTrace');
      return PlacesAutocompleteResult(
        predictions: const [],
        status: 'EXCEPTION',
        errorMessage: e.toString(),
      );
    }
  }

  /// Fetches detailed information about a place from the Google Places API.
  /// Enhanced for Bosnia and Herzegovina administrative areas.
  ///
  /// [placeId] The place_id of the place for which details are being requested.
  /// [sessionToken] A random string which identifies an autocomplete session for billing purposes.
  /// [fields] A comma-separated list of place data types to return (e.g., 'address_component,geometry,formatted_address').
  /// [language] The language code, indicating in which language the results should be returned, if possible.
  Future<Map<String, dynamic>?> getPlaceDetails(
    String placeId,
    String sessionToken, {
    String? fields,
    String? language,
  }) async {
    // Enhanced fields to include all administrative levels for Bosnia and Herzegovina
    final enhancedFields = fields ??
        'address_component,name,geometry,formatted_address,type,place_id';

    String url =
        '$_detailsBaseUrl?place_id=$placeId&key=$_apiKey&sessiontoken=$sessionToken';
    url += '&fields=$enhancedFields';
    if (language != null) url += '&language=$language';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'] as Map<String, dynamic>;
        }
        // Handle other statuses
        debugPrint(
            'Google Places Details API Error: ${data['status']} - ${data['error_message']}');
        return null;
      } else {
        // Handle HTTP error
        debugPrint('HTTP Error fetching place details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception fetching place details: $e');
      return null;
    }
  }

  /// Helper method to determine Bosnia and Herzegovina entity from administrative area
  static String? getBosnianEntityFromAdministrativeArea(String? adminArea) {
    if (adminArea == null) return null;

    final normalized = adminArea.toLowerCase().trim();

    // Common variations of entity names in Google Places API
    if (normalized.contains('federation') ||
        normalized.contains('federacija') ||
        normalized == 'fbih' ||
        normalized == 'federation of bosnia and herzegovina') {
      return 'Federation of Bosnia and Herzegovina';
    }

    if (normalized.contains('republika srpska') ||
        normalized.contains('rs') ||
        normalized == 'republika srpska') {
      return 'Republika Srpska';
    }

    if (normalized.contains('brčko') ||
        normalized.contains('brcko') ||
        normalized.contains('brčko district')) {
      return 'Brčko District';
    }

    return adminArea; // Return as-is if no match found
  }
}

/// Place Prediction model with structured formatting support
class PlacePrediction {
  final String description;
  final String placeId;
  final String mainText;
  final String secondaryText;

  PlacePrediction({
    required this.description,
    required this.placeId,
    required this.mainText,
    required this.secondaryText,
  });

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    final structuredFormatting = json['structured_formatting'] as Map<String, dynamic>?;
    
    return PlacePrediction(
      description: json['description'] as String? ?? '',
      placeId: json['place_id'] as String? ?? '',
      mainText: structuredFormatting?['main_text'] as String? ?? json['description'] as String? ?? '',
      secondaryText: structuredFormatting?['secondary_text'] as String? ?? '',
    );
  }
}

// Enhanced Place Details model for Bosnia and Herzegovina administrative areas
class PlaceDetails {
  final String formattedAddress;
  final List<AddressComponent> addressComponents;
  final Geometry geometry;
  final String? placeId;

  PlaceDetails({
    required this.formattedAddress,
    required this.addressComponents,
    required this.geometry,
    this.placeId,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      formattedAddress: json['formatted_address'] as String,
      addressComponents: (json['address_components'] as List<dynamic>)
          .map((e) => AddressComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      geometry: Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
      placeId: json['place_id'] as String?,
    );
  }

  // Helper to find a specific address component (e.g., city, country)
  String? getAddressComponent(String type) {
    try {
      return addressComponents
          .firstWhere((c) => c.types.contains(type))
          .longName;
    } catch (e) {
      return null; // Component not found
    }
  }

  // Enhanced helpers for Bosnia and Herzegovina
  String? get city => getAddressComponent('locality');
  String? get country => getAddressComponent('country');
  String? get countryCode => addressComponents
      .firstWhere((c) => c.types.contains('country'),
          orElse: () =>
              AddressComponent(longName: '', shortName: '', types: []))
      .shortName;
  String? get postalCode => getAddressComponent('postal_code');
  String? get streetNumber => getAddressComponent('street_number');
  String? get streetName => getAddressComponent('route');

  // Administrative areas for Bosnia and Herzegovina entities
  String? get administrativeAreaLevel1 =>
      getAddressComponent('administrative_area_level_1');
  String? get administrativeAreaLevel2 =>
      getAddressComponent('administrative_area_level_2');

  // Helper to get the best available city name
  String? get bestCityName => city ?? getAddressComponent('sublocality');

  // Helper to get Bosnia and Herzegovina entity
  String? get bosnianEntity =>
      GooglePlacesService.getBosnianEntityFromAdministrativeArea(
          administrativeAreaLevel1);

  // Helper to get sub-entity information
  String? get bosnianSubEntity => administrativeAreaLevel2;
}

class AddressComponent {
  final String longName;
  final String shortName;
  final List<String> types;

  AddressComponent({
    required this.longName,
    required this.shortName,
    required this.types,
  });

  factory AddressComponent.fromJson(Map<String, dynamic> json) {
    return AddressComponent(
      longName: json['long_name'] as String,
      shortName: json['short_name'] as String,
      types: (json['types'] as List<dynamic>).map((t) => t as String).toList(),
    );
  }
}

class Geometry {
  final LocationPoint location;

  Geometry({required this.location});

  factory Geometry.fromJson(Map<String, dynamic> json) {
    return Geometry(
      location:
          LocationPoint.fromJson(json['location'] as Map<String, dynamic>),
    );
  }
}

class LocationPoint {
  final double lat;
  final double lng;

  LocationPoint({required this.lat, required this.lng});

  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
    );
  }
}
