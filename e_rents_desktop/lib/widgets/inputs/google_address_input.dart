import 'package:flutter/material.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http; // Import http to make direct API calls
import 'dart:convert'; // For parsing JSON

// Enhanced class to hold detailed address information with administrative areas
class AddressDetails {
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String? streetNumber;
  final String? streetName;
  final String? city;
  final String? postalCode;
  final String? country;
  final String? countryCode;
  final String?
  administrativeAreaLevel1; // State/Entity level (e.g., "Republika Srpska")
  final String? administrativeAreaLevel2; // Sub-entity level
  final String? locality; // City/Town level
  final String? sublocality; // Neighborhood/District level
  final String? placeId;

  AddressDetails({
    required this.formattedAddress,
    required this.latitude,
    required this.longitude,
    this.streetNumber,
    this.streetName,
    this.city,
    this.postalCode,
    this.country,
    this.countryCode,
    this.administrativeAreaLevel1,
    this.administrativeAreaLevel2,
    this.locality,
    this.sublocality,
    this.placeId,
  });

  /// Helper method to get the best available city name
  String? get bestCityName => locality ?? city;

  /// Helper method to get the state/entity for Bosnia and Herzegovina
  String? get bosnianEntity => administrativeAreaLevel1;

  /// Helper method to get sub-entity information
  String? get bosnianSubEntity => administrativeAreaLevel2;
}

class GoogleAddressInput extends StatefulWidget {
  final String googleApiKey;
  final ValueChanged<AddressDetails?> onAddressSelected;
  final String? initialValue;
  final String labelText;
  final String hintText;
  final List<String>? countries; // Optional: Country filter
  final FormFieldValidator<String>? validator;

  const GoogleAddressInput({
    super.key,
    required this.googleApiKey,
    required this.onAddressSelected,
    this.initialValue,
    this.labelText = 'Address',
    this.hintText = 'Search Address',
    this.countries,
    this.validator,
  });

  @override
  State<GoogleAddressInput> createState() => _GoogleAddressInputState();
}

class _GoogleAddressInputState extends State<GoogleAddressInput> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  String? _selectedAddress;
  bool _isSearching = false;
  List<Prediction> _predictions = [];

  // This layer widget helps manage the focus and text input directly
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.initialValue;
    _textController = TextEditingController(text: widget.initialValue);

    // Listen to text changes
    _textController.addListener(_onSearchChanged);

    // Listen to focus changes
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _showOverlay();
      } else {
        // Add a small delay before hiding the overlay to allow tap events on suggestions
        Future.delayed(const Duration(milliseconds: 150), () {
          // Check focus again after delay before hiding
          if (!_focusNode.hasFocus) {
            _hideOverlay();
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _hideOverlay();
    _textController.removeListener(_onSearchChanged);
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final searchText = _textController.text;

    // If text is empty, clear predictions
    if (searchText.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    // Otherwise, show loading state and trigger search
    setState(() {
      _isSearching = true;
    });

    // Debounce search requests
    Future.delayed(const Duration(milliseconds: 500), () {
      if (searchText == _textController.text) {
        _performSearch(searchText);
      }
    });
  }

  Future<void> _performSearch(String query) async {
    // Create a proper implementation using Google Places API directly
    if (query.isEmpty) {
      setState(() {
        _predictions = [];
        _isSearching = false;
      });
      return;
    }

    try {
      // Since the GooglePlaces class isn't directly accessible, we'll make a direct API call to Google Places
      final apiKey = widget.googleApiKey;

      // Build the URL with proper parameters
      final Uri uri = Uri.https(
        'maps.googleapis.com',
        '/maps/api/place/autocomplete/json',
        {
          'input': query,
          'key': apiKey,
          if (widget.countries?.isNotEmpty == true)
            'components': 'country:${widget.countries!.join('|')}',
        },
      );

      // Make the HTTP request
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        // Parse response
        final Map<String, dynamic> data = json.decode(response.body);

        if (data['status'] == 'OK') {
          // Convert Google's predictions to the Prediction model from google_places_flutter
          final List<dynamic> predictions = data['predictions'];
          final List<Prediction> mappedPredictions =
              predictions.map((item) {
                return Prediction(
                  description: item['description'],
                  placeId: item['place_id'],
                  // Other fields can be mapped as needed
                );
              }).toList();

          setState(() {
            _predictions = mappedPredictions;
            _isSearching = false;
          });
        } else {
          print("API Error: ${data['status']}");
          setState(() {
            _predictions = [];
            _isSearching = false;
          });
        }
      } else {
        throw Exception('Failed to load predictions');
      }

      // Update overlay
      if (_overlayEntry != null) {
        _hideOverlay();
        _showOverlay();
      }
    } catch (e) {
      print("Error searching places: $e");
      setState(() {
        _isSearching = false;
        _predictions = [];
      });
    }
  }

  // Enhanced method to fetch place details with comprehensive address components
  Future<AddressDetails?> _getPlaceDetails(String placeId) async {
    final apiKey = widget.googleApiKey;
    final Uri uri =
        Uri.https('maps.googleapis.com', '/maps/api/place/details/json', {
          'place_id': placeId,
          'fields':
              'formatted_address,geometry/location,address_components,place_id',
          'key': apiKey,
        });

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final result = data['result'];
          final location = result['geometry']['location'];
          final List<dynamic> addressComponents =
              result['address_components'] ?? [];

          // Helper function to extract component by type
          String? getComponent(String type, {bool useShortName = false}) {
            final component = addressComponents.firstWhere(
              (c) => (c['types'] as List).contains(type),
              orElse: () => null,
            );
            return component?[useShortName ? 'short_name' : 'long_name'];
          }

          // Enhanced extraction for Bosnia and Herzegovina
          return AddressDetails(
            formattedAddress: result['formatted_address'] ?? '',
            latitude: location['lat'] as double? ?? 0.0,
            longitude: location['lng'] as double? ?? 0.0,
            streetNumber: getComponent('street_number'),
            streetName: getComponent('route'),
            city: getComponent('locality'),
            locality: getComponent('locality'),
            sublocality:
                getComponent('sublocality') ??
                getComponent('sublocality_level_1'),
            postalCode: getComponent('postal_code'),
            country: getComponent('country'),
            countryCode: getComponent('country', useShortName: true),
            administrativeAreaLevel1: getComponent(
              'administrative_area_level_1',
            ), // Main entity (Republika Srpska, Federation of BiH, etc.)
            administrativeAreaLevel2: getComponent(
              'administrative_area_level_2',
            ), // Sub-entity
            placeId: result['place_id'],
          );
        } else {
          print(
            "Place Details API Error: ${data['status']} - ${data['error_message']}",
          );
        }
      } else {
        throw Exception('Failed to load place details: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching place details: $e");
    }
    return null;
  }

  void _selectPrediction(Prediction prediction) async {
    // Make async
    if (prediction.placeId == null || prediction.description == null) {
      print("Prediction missing placeId or description");
      return;
    }

    // Show loading/indicator while fetching details if needed
    // setState(() { _isFetchingDetails = true; });

    final details = await _getPlaceDetails(prediction.placeId!);

    // setState(() { _isFetchingDetails = false; });

    if (details != null) {
      setState(() {
        _selectedAddress = details.formattedAddress; // Use detailed address
        _textController.text = details.formattedAddress;
        _predictions = [];
      });

      widget.onAddressSelected(details); // Pass details object
      _hideOverlay();
      _focusNode.unfocus();
    } else {
      // Handle error - maybe show a snackbar?
      print("Failed to get address details.");
      // Optionally, still set the text field with the description as fallback
      setState(() {
        _selectedAddress = prediction.description;
        _textController.text = prediction.description ?? '';
        _predictions = [];
      });
      widget.onAddressSelected(null); // Indicate failure
      _hideOverlay();
      _focusNode.unfocus();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) {
      return;
    }

    final overlay = Overlay.of(context);
    _overlayEntry = OverlayEntry(
      builder:
          (context) => Positioned(
            width: MediaQuery.of(context).size.width * 0.7,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(0, 40),
              child: Material(
                elevation: 4,
                child: _buildSuggestionsContainer(),
              ),
            ),
          ),
    );

    if (_overlayEntry != null) {
      overlay.insert(_overlayEntry!);
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionsContainer() {
    if (_predictions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      constraints: const BoxConstraints(maxHeight: 200),
      child:
          _isSearching
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                shrinkWrap: true,
                itemCount: _predictions.length,
                itemBuilder: (context, index) {
                  final prediction = _predictions[index];
                  return ListTile(
                    leading: Icon(
                      Icons.location_on,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(prediction.description ?? ""),
                    onTap: () => _selectPrediction(prediction),
                  );
                },
              ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: _selectedAddress,
      validator: widget.validator,
      builder: (FormFieldState<String> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CompositedTransformTarget(
              link: _layerLink,
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                onTap: () {
                  _showOverlay();
                },
                decoration: InputDecoration(
                  labelText: widget.labelText,
                  hintText: widget.hintText,
                  border: InputBorder.none,
                  isDense: true,
                  errorText: field.errorText,
                  suffixIcon:
                      _textController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _textController.clear();
                              setState(() {
                                _selectedAddress = null;
                                _predictions = [];
                              });
                              widget.onAddressSelected(null);
                              field.didChange(null);
                            },
                          )
                          : null,
                ),
              ),
            ),
            if (field.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 4),
                child: Text(
                  field.errorText!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
