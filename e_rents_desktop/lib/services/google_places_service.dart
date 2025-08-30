import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart';

class GooglePlacesService {
  late final FlutterGooglePlacesSdk _places;

  GooglePlacesService() {
    final apiKey = dotenv.env['GOOGLE_MAPS_API_KEY'];
    if (apiKey == null) {
      throw Exception('GOOGLE_MAPS_API_KEY not found in .env file');
    }
    _places = FlutterGooglePlacesSdk(apiKey);
    _places.isInitialized().then((_) {});
  }

  Future<List<AutocompletePrediction>> getAutocompleteSuggestions(String query) async {
    if (query.isEmpty) {
      return [];
    }
    final response = await _places.findAutocompletePredictions(query);
    return response.predictions;
  }

  Future<Place?> getPlaceDetails(String placeId) async {
    final response = await _places.fetchPlace(placeId, fields: [
      PlaceField.Address,
      PlaceField.AddressComponents,
      PlaceField.Location,
      PlaceField.Name,
    ]);
    return response.place;
  }
}
