import 'package:flutter/material.dart';
import 'package:e_rents_desktop/services/google_places_service.dart';

/// Callback with structured place details for city selection
class CityPlaceDetails {
  final String? city;
  final String? zipCode;
  final String? country;
  final String? state;
  final String formattedAddress;

  CityPlaceDetails({
    this.city,
    this.zipCode,
    this.country,
    this.state,
    required this.formattedAddress,
  });
}

/// A city autocomplete field that uses Google Places API
/// and auto-populates related address fields on selection.
class CityAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final Function(CityPlaceDetails? details) onPlaceSelected;
  final bool enabled;
  final String? Function(String?)? validator;

  const CityAutocompleteField({
    super.key,
    required this.controller,
    this.labelText = 'City',
    this.hintText = 'Search for a city...',
    required this.onPlaceSelected,
    this.enabled = true,
    this.validator,
  });

  @override
  State<CityAutocompleteField> createState() => _CityAutocompleteFieldState();
}

class _CityAutocompleteFieldState extends State<CityAutocompleteField> {
  late final GooglePlacesService _placesService;
  List<AutocompletePrediction> _predictions = [];
  bool _isLoading = false;
  bool _isSelecting = false;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _placesService = GooglePlacesService();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _hideOverlay();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus && _predictions.isNotEmpty) {
      _showOverlay();
    } else if (!_focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && mounted && !_isSelecting) {
          _hideOverlay();
        }
      });
    }
  }

  void _onTextChanged() async {
    if (_isSelecting) return;

    final query = widget.controller.text.trim();
    if (query.length < 2) {
      setState(() {
        _predictions = [];
        _isLoading = false;
      });
      _hideOverlay();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Add (cities) type filter for city-only results
      final results = await _placesService.getAutocompleteSuggestions(query);
      if (!mounted) return;

      setState(() {
        _predictions = results;
        _isLoading = false;
      });

      if (_predictions.isNotEmpty && _focusNode.hasFocus) {
        _showOverlay();
      } else {
        _hideOverlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _predictions = [];
          _isLoading = false;
        });
      }
      debugPrint('Error fetching city suggestions: $e');
    }
  }

  void _showOverlay() {
    if (_predictions.isEmpty) {
      _hideOverlay();
      return;
    }
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
    } else {
      // Rebuild existing overlay with new predictions
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 4),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: _buildSuggestionsList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_predictions.isEmpty) return const SizedBox.shrink();

    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        itemCount: _predictions.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final prediction = _predictions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.location_city, size: 20),
            title: Text(
              prediction.fullText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => _onSuggestionSelected(prediction),
          );
        },
      ),
    );
  }

  Future<void> _onSuggestionSelected(AutocompletePrediction prediction) async {
    _isSelecting = true;
    _hideOverlay();
    _focusNode.unfocus();

    setState(() {
      _predictions = [];
      _isLoading = true;
    });

    try {
      final details = await _placesService.getPlaceDetails(prediction.placeId);

      if (!mounted) {
        _isSelecting = false;
        return;
      }

      if (details != null) {
        // Extract address components
        String? city;
        String? zipCode;
        String? country;
        String? state;

        for (final component in details.addressComponents ?? <AddressComponent>[]) {
          if (component.types.contains('locality')) {
            city = component.name;
          } else if (component.types.contains('administrative_area_level_2') && city == null) {
            city = component.name;
          } else if (component.types.contains('postal_code')) {
            zipCode = component.name;
          } else if (component.types.contains('country')) {
            country = component.name;
          } else if (component.types.contains('administrative_area_level_1')) {
            state = component.name;
          }
        }

        // Update the city controller text
        widget.controller.text = city ?? prediction.fullText.split(',').first;

        // Notify parent with all extracted details
        widget.onPlaceSelected(CityPlaceDetails(
          city: city,
          zipCode: zipCode,
          country: country,
          state: state,
          formattedAddress: details.formattedAddress ?? prediction.fullText,
        ));
      } else {
        // Fallback: just use the prediction text
        widget.controller.text = prediction.fullText.split(',').first;
        widget.onPlaceSelected(null);
      }
    } catch (e) {
      debugPrint('Error getting place details: $e');
      widget.controller.text = prediction.fullText.split(',').first;
      widget.onPlaceSelected(null);
    } finally {
      setState(() => _isLoading = false);
      _isSelecting = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        enabled: widget.enabled,
        decoration: InputDecoration(
          labelText: widget.labelText,
          hintText: widget.hintText,
          prefixIcon: const Icon(Icons.search, size: 20),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: widget.enabled
                          ? () {
                              widget.controller.clear();
                              widget.onPlaceSelected(null);
                              _predictions = [];
                              _hideOverlay();
                              setState(() {});
                            }
                          : null,
                    )
                  : null,
        ),
        validator: widget.validator,
      ),
    );
  }
}
