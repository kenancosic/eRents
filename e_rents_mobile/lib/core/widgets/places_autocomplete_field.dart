import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/services/google_places_service.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:uuid/uuid.dart';

class PlacesAutocompleteField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  // Updated to expect PlaceDetails for more structured data, or null if error/no selection
  final Function(PlaceDetails? placeDetails) onPlaceSelected;
  final String?
      searchType; // e.g., '(cities)', 'geocode', 'address', 'establishment'
  final String? countryRestrictions; // e.g., 'us' or 'country:us|country:ca'

  const PlacesAutocompleteField({
    super.key,
    required this.controller,
    this.hintText = 'Search for a place',
    required this.onPlaceSelected,
    this.searchType, // Default is null (all place types)
    this.countryRestrictions,
  });

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
  bool _isMounted = false;
  bool _isSelecting = false;
  String? _errorMessage;

  // Overlay positioning
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isMounted = true;
    _placesService = GooglePlacesService();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay hiding to allow tap on suggestion to be processed first
      // This prevents the race condition where focus loss hides overlay before tap is handled
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_focusNode.hasFocus && _isMounted && !_isSelecting) {
          _hideOverlay();
        }
      });
    }
  }

  void _generateNewSessionToken() {
    _sessionToken = _uuid.v4();
    debugPrint("Generated new session token: $_sessionToken");
  }

  @override
  void dispose() {
    _isMounted = false;
    _hideOverlay();
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
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
            borderRadius: BorderRadius.circular(12),
            shadowColor: Colors.black26,
            child: _buildSuggestionsList(),
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestionsList() {
    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.errorLight),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 16, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(fontSize: 12, color: Colors.redAccent),
              ),
            ),
          ],
        ),
      );
    }

    if (_predictions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      constraints: const BoxConstraints(maxHeight: 240),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.zero,
          itemCount: _predictions.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final suggestion = _predictions[index];
            return _buildSuggestionTile(suggestion);
          },
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(PlacePrediction suggestion) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        // Set selecting flag immediately on tap down to prevent overlay from hiding
        _isSelecting = true;
      },
      onTap: () => _onSuggestionSelected(suggestion),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.location_on_outlined,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.mainText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (suggestion.secondaryText.isNotEmpty)
                    Text(
                      suggestion.secondaryText,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(
              Icons.north_west,
              size: 14,
              color: AppColors.textTertiary,
            ),
          ],
        ),
      ),
    );
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

      final result = await _placesService.getAutocompleteSuggestions(
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
        if (result.status == 'OK') {
          _predictions = result.predictions
              .map((p) => PlacePrediction.fromJson(p as Map<String, dynamic>))
              .toList();
          _errorMessage = null;
        } else if (result.status == 'ZERO_RESULTS' || result.predictions.isEmpty) {
          _predictions = [];
          _errorMessage = null;
        } else {
          _predictions = [];
          final status = result.status;
          if (status == 'REQUEST_DENIED') {
            _errorMessage = 'Place suggestions unavailable. Check API key.';
          } else if (status.startsWith('HTTP_')) {
            _errorMessage = 'Unable to reach Places service.';
          } else if (status == 'EXCEPTION') {
            _errorMessage = 'Error contacting Places service.';
          } else {
            _errorMessage = 'Suggestions unavailable.';
          }
        }
        _isLoading = false;
      });
      _updateOverlay();
    } else {
      if (_predictions.isNotEmpty || _isLoading) {
        _predictions = [];
        _isLoading = false;
        _errorMessage = null;
        setState(() {});
        _updateOverlay();
      }
    }
  }

  void _onSuggestionSelected(PlacePrediction suggestion) async {
    debugPrint('PlacesAutocomplete: Suggestion selected - ${suggestion.description} (placeId: ${suggestion.placeId})');
    
    if (!_isMounted || _sessionToken == null) {
      debugPrint('PlacesAutocomplete: Early return - mounted: $_isMounted, token: $_sessionToken');
      return;
    }

    _isSelecting = true;
    _hideOverlay();
    _focusNode.unfocus();

    _predictions = [];
    _isLoading = true;
    _errorMessage = null;
    setState(() {});

    debugPrint('PlacesAutocomplete: Fetching place details...');
    final placeDetailsMap = await _placesService.getPlaceDetails(
      suggestion.placeId,
      _sessionToken!,
      fields:
          'address_component,formatted_address,geometry,name,type,place_id', // Ensure comprehensive fields
    );

    if (!_isMounted) {
      _isSelecting = false; // Reset flag if unmounted during await
      debugPrint('PlacesAutocomplete: Widget unmounted during fetch');
      return;
    }

    PlaceDetails? placeDetails;
    String textForController = suggestion.description; // Fallback

    if (placeDetailsMap != null) {
      placeDetails = PlaceDetails.fromJson(placeDetailsMap);
      textForController = placeDetails.formattedAddress;
      debugPrint('PlacesAutocomplete: Got place details - city: ${placeDetails.city}, bestCityName: ${placeDetails.bestCityName}, lat: ${placeDetails.geometry.location.lat}, lng: ${placeDetails.geometry.location.lng}');
    } else {
      // Handle error or no details, perhaps keep the suggestion description
      // textForController is already suggestion.description
      debugPrint("PlacesAutocomplete: Failed to get place details for ${suggestion.description}");
    }

    widget.controller.text =
        textForController; // This might trigger _onTextChanged, but _isSelecting will prevent re-fetch

    debugPrint('PlacesAutocomplete: Calling onPlaceSelected callback with placeDetails: ${placeDetails != null}');
    widget.onPlaceSelected(placeDetails);

    _isLoading = false;
    _errorMessage = null;
    setState(() {});
    
    _generateNewSessionToken();
    _isSelecting = false;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: widget.controller,
        focusNode: _focusNode,
        onTap: () {
          if (_sessionToken == null || widget.controller.text.isEmpty) {
            _generateNewSessionToken();
          }
        },
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: Icon(
            Icons.search,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: _isLoading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                    ),
                  ),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () {
                        if (!_isMounted) return;
                        widget.controller.clear();
                        widget.onPlaceSelected(null);
                        _predictions = [];
                        _isLoading = false;
                        _errorMessage = null;
                        setState(() {});
                        _hideOverlay();
                        _generateNewSessionToken();
                      },
                    )
                  : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderMedium),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.borderMedium),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
      ),
    );
  }
}
