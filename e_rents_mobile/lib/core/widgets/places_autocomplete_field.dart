import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/services/google_places_service.dart';
import 'package:uuid/uuid.dart'; // For generating session tokens

// TODO: Import GooglePlacesService and Place model/details class

class PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  // Updated to expect PlaceDetails for more structured data, or null if error/no selection
  final Function(PlaceDetails? placeDetails) onPlaceSelected;
  final String?
      searchType; // e.g., '(cities)', 'geocode', 'address', 'establishment'
  final String? countryRestrictions; // e.g., 'us' or 'country:us|country:ca'

  const PlacesAutocompleteField({
    Key? key,
    required this.controller,
    this.hintText = 'Search for a place',
    required this.onPlaceSelected,
    this.searchType, // Default is null (all place types)
    this.countryRestrictions,
  }) : super(key: key);

  @override
  _PlacesAutocompleteFieldState createState() =>
      _PlacesAutocompleteFieldState();
}

class _PlacesAutocompleteFieldState extends State<PlacesAutocompleteField> {
  late final GooglePlacesService _placesService;
  List<PlacePrediction> _predictions = [];
  String? _sessionToken;
  final Uuid _uuid = const Uuid();
  bool _isLoading = false;
  bool _isMounted = false; // To prevent setState calls after dispose
  bool _isSelecting = false; // Flag to indicate a selection is in progress

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _placesService = GooglePlacesService();
    widget.controller.addListener(_onTextChanged);
    // Generate initial session token when the field is ready or gains focus
    // For simplicity, we'll generate it when text changes or field is tapped
  }

  void _generateNewSessionToken() {
    _sessionToken = _uuid.v4();
    print("Generated new session token: $_sessionToken");
  }

  @override
  void dispose() {
    _isMounted = false;
    widget.controller.removeListener(_onTextChanged);
    // Consider cancelling any ongoing API calls here
    super.dispose();
  }

  void _onTextChanged() async {
    if (!_isMounted || _isSelecting) return; // Prevent fetch if selecting

    final query = widget.controller.text;

    if (_sessionToken == null && query.isNotEmpty) {
      _generateNewSessionToken();
    }

    if (query.isNotEmpty && _sessionToken != null) {
      if (!_isLoading) {
        setState(() {
          _isLoading = true;
        });
      }

      final rawPredictions = await _placesService.getAutocompleteSuggestions(
        query,
        _sessionToken!,
        types: widget.searchType,
        components: widget.countryRestrictions != null &&
                !widget.countryRestrictions!.contains(":")
            ? 'country:${widget.countryRestrictions}'
            : widget
                .countryRestrictions, // Ensure 'country:' prefix if not already there for single country
      );

      if (!_isMounted) return;

      setState(() {
        _predictions = rawPredictions
            .map((p) => PlacePrediction.fromJson(p as Map<String, dynamic>))
            .toList();
        _isLoading = false;
      });
    } else {
      if (_predictions.isNotEmpty || _isLoading) {
        setState(() {
          _predictions = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onSuggestionSelected(PlacePrediction suggestion) async {
    if (!_isMounted || _sessionToken == null) return;

    _isSelecting = true; // Set flag

    FocusScope.of(context).unfocus(); // Dismiss keyboard

    if (_isMounted) {
      setState(() {
        _predictions = []; // Clear predictions immediately
        _isLoading = true; // Show loading for place details fetch
      });
    }

    final placeDetailsMap = await _placesService.getPlaceDetails(
      suggestion.placeId,
      _sessionToken!,
      fields:
          'address_component,formatted_address,geometry,name,type,place_id', // Ensure comprehensive fields
    );

    if (!_isMounted) {
      _isSelecting = false; // Reset flag if unmounted during await
      return;
    }

    PlaceDetails? placeDetails;
    String textForController = suggestion.description; // Fallback

    if (placeDetailsMap != null) {
      placeDetails = PlaceDetails.fromJson(placeDetailsMap);
      textForController = placeDetails.formattedAddress;
    } else {
      // Handle error or no details, perhaps keep the suggestion description
      // textForController is already suggestion.description
      print("Failed to get place details for ${suggestion.description}");
    }

    widget.controller.text =
        textForController; // This might trigger _onTextChanged, but _isSelecting will prevent re-fetch

    widget.onPlaceSelected(placeDetails);

    if (_isMounted) {
      setState(() {
        // _predictions is already empty
        _isLoading = false; // Done with loading details
      });
    }
    _generateNewSessionToken(); // Generate a new token for the next session
    _isSelecting = false; // Reset flag
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: widget.controller,
          onTap: () {
            // Generate a session token if one doesn't exist or if the input is empty
            // This helps if the user taps into an empty field.
            if (_sessionToken == null || widget.controller.text.isEmpty) {
              _generateNewSessionToken();
            }
          },
          decoration: InputDecoration(
            hintText: widget.hintText,
            suffixIcon: _isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    ))
                : widget.controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          if (!_isMounted) return;
                          widget.controller
                              .clear(); // This will trigger _onTextChanged
                          // Explicitly call onPlaceSelected with null to signal clearing
                          widget.onPlaceSelected(null);
                          setState(() {
                            _predictions = [];
                            _isLoading = false;
                          });
                          _generateNewSessionToken(); // New session as input is cleared
                        },
                      )
                    : null,
          ),
        ),
        if (_predictions.isNotEmpty)
          Material(
            // Wrap with Material for proper theming of ListTiles
            elevation: 4.0, // Optional: add some shadow
            child: SizedBox(
              height: 200, // Adjust height as needed
              child: ListView.builder(
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final suggestion = _predictions[index];
                  return ListTile(
                    title: Text(suggestion.description),
                    onTap: () => _onSuggestionSelected(suggestion),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}
