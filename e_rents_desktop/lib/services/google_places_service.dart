import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

// Minimal DTOs compatible with existing widget usage
class AutocompletePrediction {
  final String fullText;
  final String placeId;
  AutocompletePrediction({required this.fullText, required this.placeId});
}

class AddressComponent {
  final String name;
  final String shortName;
  final List<String> types;
  AddressComponent({required this.name, required this.shortName, required this.types});
}

class Place {
  final String? formattedAddress;
  final List<AddressComponent>? addressComponents;
  final double? lat;
  final double? lng;
  Place({this.formattedAddress, this.addressComponents, this.lat, this.lng});
}

class GooglePlacesService {
  late final String _apiKey;

  GooglePlacesService() {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_MAPS_API_KEY not found in .env file');
    }
    _apiKey = apiKey;
  }

  Future<List<AutocompletePrediction>> getAutocompleteSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/autocomplete/json', {
      'input': query,
      'key': _apiKey,
      // You can add language or components filters here if needed.
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Places autocomplete failed: ${res.statusCode} ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final predictions = (data['predictions'] as List<dynamic>? ?? [])
        .map((p) => AutocompletePrediction(
              fullText: p['description'] as String? ?? '',
              placeId: p['place_id'] as String? ?? '',
            ))
        .where((p) => p.placeId.isNotEmpty)
        .toList();
    return predictions;
  }

  Future<Place?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;
    final uri = Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
      'place_id': placeId,
      'fields': 'address_component,formatted_address,geometry/location,name',
      'key': _apiKey,
    });
    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Place details failed: ${res.statusCode} ${res.body}');
    }
    final data = json.decode(res.body) as Map<String, dynamic>;
    final result = data['result'] as Map<String, dynamic>?;
    if (result == null) return null;

    final components = (result['address_components'] as List<dynamic>? ?? [])
        .map((c) => AddressComponent(
              name: c['long_name'] as String? ?? '',
              shortName: c['short_name'] as String? ?? '',
              types: (c['types'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
            ))
        .toList();
    final loc = ((result['geometry'] as Map<String, dynamic>?)?['location'] as Map<String, dynamic>?) ?? {};
    final lat = (loc['lat'] as num?)?.toDouble();
    final lng = (loc['lng'] as num?)?.toDouble();
    final formatted = result['formatted_address'] as String?;

    return Place(
      formattedAddress: formatted,
      addressComponents: components,
      lat: lat,
      lng: lng,
    );
  }
}
