import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/address.dart';
import 'package:e_rents_desktop/services/google_places_service.dart';

class ModernAddressInput extends StatefulWidget {
  final Address? initialAddress;
  final Function(Address?) onAddressChanged;
  final bool enabled;

  const ModernAddressInput({
    super.key,
    this.initialAddress,
    required this.onAddressChanged,
    this.enabled = true,
  });

  @override
  State<ModernAddressInput> createState() => _ModernAddressInputState();
}

class _ModernAddressInputState extends State<ModernAddressInput> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _streetNumberController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  
  final _placesService = GooglePlacesService();
  List<AutocompletePrediction> _predictions = [];
  bool _isLoading = false;
  bool _showManualEntry = false;

  @override
  void initState() {
    super.initState();
    _initializeFields();
    _searchController.addListener(_onSearchChanged);
  }

  void _initializeFields() {
    if (widget.initialAddress != null) {
      final address = widget.initialAddress!;
      _searchController.text = _formatAddressForSearch(address);
      _streetController.text = address.streetLine1 ?? '';
      _streetNumberController.text = address.streetLine2 ?? '';
      _cityController.text = address.city ?? '';
      _postalCodeController.text = address.postalCode ?? '';
      _countryController.text = address.country ?? '';
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text;
    if (query.length >= 2 && widget.enabled) {
      _searchPlaces(query);
    } else {
      setState(() => _predictions = []);
    }
  }

  String _formatAddressForSearch(Address address) {
    final parts = [
      address.streetLine1,
      address.streetLine2,
      address.city,
      address.country,
      address.postalCode,
    ].where((part) => part != null && part.isNotEmpty).map((part) => part!);
    return parts.join(', ');
  }

  Future<void> _searchPlaces(String input) async {
    if (!widget.enabled) return;
    
    setState(() => _isLoading = true);
    try {
      final result = await _placesService.getAutocompleteSuggestions(input);
      if (mounted) {
        setState(() {
          _predictions = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectPlace(AutocompletePrediction prediction) async {
    try {
      final Place? details = await _placesService.getPlaceDetails(prediction.placeId);
      if (details != null && mounted) {
        _fillAddressFromPlaceDetails(details);
        _notifyAddressChanged();
        setState(() {
          _searchController.clear();
          _predictions = [];
        });
      }
    } catch (e) {
      // Handle error
    }
  }

  void _fillAddressFromPlaceDetails(Place details) {
    _streetController.clear();
    _streetNumberController.clear();
    _cityController.clear();
    _postalCodeController.clear();
    _countryController.clear();

    final streetName = details.addressComponents?.firstWhere(
      (c) => c.types.contains('route'), 
      orElse: () => AddressComponent(name: '', shortName: '', types: [])
    ).name ?? '';
    
    final streetNumber = details.addressComponents?.firstWhere(
      (c) => c.types.contains('street_number'), 
      orElse: () => AddressComponent(name: '', shortName: '', types: [])
    ).name ?? '';
    
    final city = details.addressComponents?.firstWhere(
      (c) => c.types.contains('locality'), 
      orElse: () => AddressComponent(name: '', shortName: '', types: [])
    ).name ?? '';
    
    final postalCode = details.addressComponents?.firstWhere(
      (c) => c.types.contains('postal_code'), 
      orElse: () => AddressComponent(name: '', shortName: '', types: [])
    ).name ?? '';
    
    final country = details.addressComponents?.firstWhere(
      (c) => c.types.contains('country'), 
      orElse: () => AddressComponent(name: '', shortName: '', types: [])
    ).name ?? '';

    _streetController.text = streetName;
    _streetNumberController.text = streetNumber;
    _cityController.text = city;
    _postalCodeController.text = postalCode;
    _countryController.text = country;
  }

  void _notifyAddressChanged() {
    final address = _buildAddressFromFields();
    widget.onAddressChanged(address);
  }

  Address _buildAddressFromFields() {
    return Address(
      streetLine1: _streetController.text.trim().isNotEmpty ? _streetController.text.trim() : null,
      streetLine2: _streetNumberController.text.trim().isNotEmpty ? _streetNumberController.text.trim() : null,
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      country: _countryController.text.trim().isNotEmpty ? _countryController.text.trim() : null,
      postalCode: _postalCodeController.text.trim().isNotEmpty ? _postalCodeController.text.trim() : null,
      state: null,
      latitude: null,
      longitude: null,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _streetController.dispose();
    _streetNumberController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with toggle
        Row(
          children: [
            Icon(Icons.location_on_outlined, 
                 color: Theme.of(context).colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text('Address', style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            )),
            const Spacer(),
            TextButton.icon(
              onPressed: widget.enabled ? () {
                setState(() {
                  _showManualEntry = !_showManualEntry;
                  if (!_showManualEntry) {
                    _predictions.clear();
                  }
                });
              } : null,
              icon: Icon(_showManualEntry ? Icons.search : Icons.edit, size: 16),
              label: Text(_showManualEntry ? 'Search' : 'Manual Entry'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Search or Manual Entry based on toggle
        if (!_showManualEntry) ...[
          _buildSearchSection(),
        ] else ...[
          _buildManualEntrySection(),
        ],
      ],
    );
  }

  Widget _buildSearchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field with modern styling
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _searchController,
            enabled: widget.enabled,
            decoration: InputDecoration(
              hintText: 'Search for an address...',
              prefixIcon: Container(
                padding: const EdgeInsets.all(12),
                child: Icon(Icons.search, 
                     color: Theme.of(context).colorScheme.primary),
              ),
              suffixIcon: _isLoading ? Container(
                padding: const EdgeInsets.all(12),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ) : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16,
              ),
            ),
          ),
        ),
        
        // Predictions dropdown
        if (_predictions.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Colors.transparent,
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _predictions.length,
                  itemBuilder: (context, index) {
                    final prediction = _predictions[index];
                    return ListTile(
                      leading: Icon(Icons.location_on, 
                           size: 20,
                           color: Theme.of(context).colorScheme.primary),
                      title: Text(prediction.fullText,
                                 style: const TextStyle(fontSize: 14)),
                      dense: true,
                      onTap: () => _selectPlace(prediction),
                    );
                  },
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildManualEntrySection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_outlined, 
                   color: Theme.of(context).colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Text('Manual Entry', 
                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
                     fontWeight: FontWeight.w600,
                   )),
            ],
          ),
          const SizedBox(height: 20),
          
          // Street fields
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _buildModernTextField(
                  controller: _streetController,
                  label: 'Street Name',
                  icon: Icons.streetview,
                  enabled: widget.enabled,
                  onChanged: (_) => _notifyAddressChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildModernTextField(
                  controller: _streetNumberController,
                  label: 'No.',
                  icon: Icons.home,
                  enabled: widget.enabled,
                  onChanged: (_) => _notifyAddressChanged(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // City and Postal Code
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildModernTextField(
                  controller: _cityController,
                  label: 'City',
                  icon: Icons.location_city,
                  enabled: widget.enabled,
                  onChanged: (_) => _notifyAddressChanged(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: _buildModernTextField(
                  controller: _postalCodeController,
                  label: 'Postal Code',
                  icon: Icons.mail,
                  enabled: widget.enabled,
                  onChanged: (_) => _notifyAddressChanged(),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Country
          _buildModernTextField(
            controller: _countryController,
            label: 'Country',
            icon: Icons.public,
            enabled: widget.enabled,
            onChanged: (_) => _notifyAddressChanged(),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool enabled,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, 
             style: Theme.of(context).textTheme.bodySmall?.copyWith(
               fontWeight: FontWeight.w500,
               color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
             )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: enabled,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, 
                 color: Theme.of(context).colorScheme.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: Theme.of(context).colorScheme.primary,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: enabled 
                ? Theme.of(context).colorScheme.surface
                : Theme.of(context).colorScheme.surface.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12, vertical: 12,
            ),
          ),
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
