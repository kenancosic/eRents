import 'package:e_rents_desktop/models/lookup_data.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/widgets/amenity_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// A data class to hold the state of the filters
class PropertyFilterState {
  String? name;
  int? propertyTypeId;
  int? rentingTypeId;
  int? statusId;
  double? minPrice;
  double? maxPrice;
  int? bedrooms;
  int? bathrooms;
  List<int>? amenityIds;

  PropertyFilterState({
    this.name,
    this.propertyTypeId,
    this.rentingTypeId,
    this.statusId,
    this.minPrice,
    this.maxPrice,
    this.bedrooms,
    this.bathrooms,
    this.amenityIds,
  });

  // Method to convert to a map for the provider
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'propertyTypeId': propertyTypeId,
      'rentingTypeId': rentingTypeId,
      'statusId': statusId,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'amenityIds': amenityIds,
    }..removeWhere(
      (key, value) => value == null || (value is String && value.isEmpty),
    );
  }
}

class PropertyFilterPanel extends StatefulWidget {
  final Function(PropertyFilterState) onApplyFilters;
  final VoidCallback onResetFilters;

  const PropertyFilterPanel({
    super.key,
    required this.onApplyFilters,
    required this.onResetFilters,
  });

  @override
  State<PropertyFilterPanel> createState() => _PropertyFilterPanelState();
}

class _PropertyFilterPanelState extends State<PropertyFilterPanel> {
  late PropertyFilterState _filterState;
  final _searchController = TextEditingController();

  // For price range slider
  RangeValues _priceRange = const RangeValues(0, 5000);
  final double _maxPriceValue = 10000;

  @override
  void initState() {
    super.initState();
    _filterState = PropertyFilterState();
    _filterState.minPrice = _priceRange.start;
    _filterState.maxPrice = _priceRange.end;
    _searchController.addListener(() {
      _filterState.name = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetFilters() {
    setState(() {
      _filterState = PropertyFilterState();
      _searchController.clear();
      _priceRange = RangeValues(0, _maxPriceValue / 2);
      _filterState.minPrice = _priceRange.start;
      _filterState.maxPrice = _priceRange.end;
    });
    widget.onResetFilters();
  }

  @override
  Widget build(BuildContext context) {
    final lookupProvider = context.watch<LookupProvider>();
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filters', style: theme.textTheme.headlineSmall),
            const Divider(height: 24),
            _buildSearchField(),
            const SizedBox(height: 16),
            _buildDropdown(
              'Property Type',
              lookupProvider.propertyTypes,
              _filterState.propertyTypeId,
              (id) => setState(() => _filterState.propertyTypeId = id),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Renting Type',
              lookupProvider.rentingTypes,
              _filterState.rentingTypeId,
              (id) => setState(() => _filterState.rentingTypeId = id),
            ),
            const SizedBox(height: 16),
            _buildDropdown(
              'Status',
              lookupProvider.propertyStatuses,
              _filterState.statusId,
              (id) => setState(() => _filterState.statusId = id),
            ),
            const SizedBox(height: 24),
            _buildPriceRangeSlider(),
            const SizedBox(height: 24),
            _buildRoomCounters(),
            const SizedBox(height: 24),
            _buildAmenitySelector(),
            const SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextFormField(
      controller: _searchController,
      decoration: const InputDecoration(
        labelText: 'Search by Name or Description',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.search),
      ),
      onChanged: (value) {
        setState(() {
          _filterState.name = value;
        });
      },
    );
  }

  Widget _buildDropdown(
    String label,
    List<LookupItem> items,
    int? selectedValue,
    ValueChanged<int?> onChanged,
  ) {
    return DropdownButtonFormField<int>(
      value: selectedValue,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        const DropdownMenuItem<int>(value: null, child: Text('Any')),
        ...items.map(
          (item) =>
              DropdownMenuItem<int>(value: item.id, child: Text(item.name)),
        ),
      ],
      onChanged: onChanged,
    );
  }

  Widget _buildPriceRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (BAM)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        RangeSlider(
          values: _priceRange,
          min: 0,
          max: _maxPriceValue,
          divisions: 100,
          labels: RangeLabels(
            '${_priceRange.start.round()}',
            '${_priceRange.end.round()}',
          ),
          onChanged: (values) {
            setState(() {
              _priceRange = values;
              _filterState.minPrice = values.start == 0 ? null : values.start;
              _filterState.maxPrice =
                  values.end == _maxPriceValue ? null : values.end;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('BAM ${_priceRange.start.round()}'),
            Text('BAM ${_priceRange.end.round()}'),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomCounters() {
    return Row(
      children: [
        Expanded(
          child: _buildCounter(
            'Bedrooms',
            _filterState.bedrooms,
            (count) => setState(() => _filterState.bedrooms = count),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildCounter(
            'Bathrooms',
            _filterState.bathrooms,
            (count) => setState(() => _filterState.bathrooms = count),
          ),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int? value, ValueChanged<int?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: () {
                if (value == null || value == 0) {
                  onChanged(null);
                } else if (value == 1) {
                  onChanged(null);
                } else {
                  onChanged(value - 1);
                }
              },
            ),
            Text(
              value?.toString() ?? 'Any',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => onChanged((value ?? 0) + 1),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAmenitySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        AmenityManager(
          mode: AmenityManagerMode.select,
          showTitle: false,
          onAmenityIdsChanged: (ids) {
            _filterState.amenityIds = ids.isEmpty ? null : ids;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(onPressed: _resetFilters, child: const Text('Reset')),
        const SizedBox(width: 8),
        ElevatedButton.icon(
          icon: const Icon(Icons.search),
          onPressed: () => widget.onApplyFilters(_filterState),
          label: const Text('Search'),
        ),
      ],
    );
  }
}
