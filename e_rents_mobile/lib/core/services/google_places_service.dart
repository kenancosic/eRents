import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
// TODO: Consider using flutter_dotenv to load API key from .env file
// import 'package:flutter_dotenv/flutter_dotenv.dart';

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
    // It's good practice to check if the API key is loaded, though for this example it's hardcoded.
    if (_apiKey == '') {
      print(
          'WARNING: Google Places API Key is not set. Please configure it in google_places_service.dart');
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
  Future<List<dynamic>> getAutocompleteSuggestions(
    String input,
    String sessionToken, {
    String? types, // e.g., '(cities)' to search for cities
    String? language,
    String? components, // e.g., 'country:us'
  }) async {
    if (input.isEmpty) {
      return [];
    }

    String url =
        '$_autocompleteBaseUrl?input=$input&key=$_apiKey&sessiontoken=$sessionToken';
    if (types != null) url += '&types=$types';
    if (language != null) url += '&language=$language';
    if (components != null) url += '&components=$components';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['predictions'] as List<dynamic>;
        }
        // Handle other statuses like ZERO_RESULTS, REQUEST_DENIED, etc.
        print(
            'Google Places Autocomplete API Error: ${data['status']} - ${data['error_message']}');
        return [];
      } else {
        // Handle HTTP error
        print('HTTP Error fetching autocomplete: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Exception fetching autocomplete: $e');
      return [];
    }
  }

  /// Fetches detailed information about a place from the Google Places API.
  ///
  /// [placeId] The place_id of the place for which details are being requested.
  /// [sessionToken] A random string which identifies an autocomplete session for billing purposes.
  /// [fields] A comma-separated list of place data types to return (e.g., 'address_component,geometry,formatted_address').
  /// [language] The language code, indicating in which language the results should be returned, if possible.
  Future<Map<String, dynamic>?> getPlaceDetails(
    String placeId,
    String sessionToken, {
    String?
        fields, // e.g., 'address_component,name,geometry,formatted_address,type'
    String? language,
  }) async {
    String url =
        '$_detailsBaseUrl?place_id=$placeId&key=$_apiKey&sessiontoken=$sessionToken';
    if (fields != null) url += '&fields=$fields';
    if (language != null) url += '&language=$language';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'] as Map<String, dynamic>;
        }
        // Handle other statuses
        print(
            'Google Places Details API Error: ${data['status']} - ${data['error_message']}');
        return null;
      } else {
        // Handle HTTP error
        print('HTTP Error fetching place details: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Exception fetching place details: $e');
      return null;
    }
  }
}

// Example of a simple Place Prediction model (you might want to make this more robust)
class PlacePrediction {
  final String description;
  final String placeId;

  PlacePrediction({required this.description, required this.placeId});

  factory PlacePrediction.fromJson(Map<String, dynamic> json) {
    return PlacePrediction(
      description: json['description'] as String,
      placeId: json['place_id'] as String,
    );
  }
}

// Example of a simple Place Details model (you might want to make this more robust)
// This should be expanded based on the fields you request and need.
class PlaceDetails {
  final String formattedAddress;
  final List<AddressComponent> addressComponents;
  final Geometry geometry;
  // Add other fields as needed based on your 'fields' parameter in getPlaceDetails

  PlaceDetails({
    required this.formattedAddress,
    required this.addressComponents,
    required this.geometry,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    return PlaceDetails(
      formattedAddress: json['formatted_address'] as String,
      addressComponents: (json['address_components'] as List<dynamic>)
          .map((e) => AddressComponent.fromJson(e as Map<String, dynamic>))
          .toList(),
      geometry: Geometry.fromJson(json['geometry'] as Map<String, dynamic>),
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
