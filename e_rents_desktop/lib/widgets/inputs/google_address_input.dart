import 'package:flutter/material.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:http/http.dart' as http; // Import http to make direct API calls
import 'dart:convert'; // For parsing JSON
import 'package:e_rents_desktop/models/address.dart'; // Use the unified Address model

class GoogleAddressInput extends StatefulWidget {
  final String googleApiKey;
  final ValueChanged<Address?> onAddressSelected;
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

  // Enhanced method to fetch place details and convert to Address model
  Future<Address?> _getPlaceDetails(String placeId) async {
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

          // Extract street information
          final streetNumber = getComponent('street_number');
          final streetName = getComponent('route');
          String? streetLine1;

          if (streetNumber != null && streetName != null) {
            streetLine1 = '$streetNumber $streetName';
          } else if (streetName != null) {
            streetLine1 = streetName;
          } else if (streetNumber != null) {
            streetLine1 = streetNumber;
          }

          // Create Address using the unified model
          return Address(
            streetLine1: streetLine1,
            streetLine2: null, // Can be set by user if needed
            city:
                getComponent('locality') ??
                getComponent('administrative_area_level_2'),
            state: getComponent('administrative_area_level_1'),
            country: getComponent('country'),
            postalCode: getComponent('postal_code'),
            latitude: (location['lat'] as num?)?.toDouble(),
            longitude: (location['lng'] as num?)?.toDouble(),
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
    if (prediction.placeId == null || prediction.description == null) {
      print("Prediction missing placeId or description");
      return;
    }

    final address = await _getPlaceDetails(prediction.placeId!);

    if (address != null) {
      setState(() {
        _selectedAddress = address.getFullAddress();
        _textController.text = address.getFullAddress();
        _predictions = [];
      });

      widget.onAddressSelected(address);
      _hideOverlay();
      _focusNode.unfocus();
    } else {
      // Handle error - fallback to description
      setState(() {
        _selectedAddress = prediction.description;
        _textController.text = prediction.description ?? '';
        _predictions = [];
      });
      widget.onAddressSelected(null);
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
