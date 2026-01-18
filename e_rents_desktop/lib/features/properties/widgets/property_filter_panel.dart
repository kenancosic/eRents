import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/models/lookup_item.dart';
import 'package:e_rents_desktop/widgets/amenity_manager.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/base/crud/list_screen.dart' show FilterController;
import 'package:e_rents_desktop/base/lookups/lookup_key.dart';
import 'package:e_rents_desktop/widgets/inputs/custom_dropdown.dart';

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
  String? sortBy;
  bool ascending = true;

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
    this.sortBy,
    this.ascending = true,
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
      'sortBy': sortBy,
      'ascending': ascending,
    }..removeWhere(
      (key, value) => value == null || (value is String && value.isEmpty),
    );
  }
}

// Sort options for properties
const List<Map<String, String>> _propertySortOptions = [
  {'value': 'name', 'label': 'Name'},
  {'value': 'price', 'label': 'Price'},
  {'value': 'createdAt', 'label': 'Date Added'},
  {'value': 'status', 'label': 'Status'},
];

class PropertyFilterPanel extends StatefulWidget {
  // Optional: provide initial filters to pre-populate state when reopening panel
  final Map<String, dynamic>? initialFilters;
  // Whether to show an embedded search text field in the panel
  final bool showSearchField;
  // Optional: when provided, the panel will bind this controller to expose
  // its current state and a reset method to the parent dialog actions.
  final FilterController? controller;

  const PropertyFilterPanel({
    super.key,
    this.initialFilters,
    this.showSearchField = true,
    this.controller,
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

  // Lookup futures
  late Future<List<LookupItem>> _propertyTypesFuture;
  late Future<List<LookupItem>> _rentingTypesFuture;
  late Future<List<LookupItem>> _propertyStatusesFuture;

  @override
  void initState() {
    super.initState();
    _filterState = PropertyFilterState();

    // If initial filters are provided, map them into the local state for persistence
    final init = widget.initialFilters ?? const <String, dynamic>{};
    if (init.isNotEmpty) {
      // Map provider filter keys -> local state keys
      _filterState.name = (init['nameContains'] as String?)?.trim();
      _filterState.propertyTypeId = init['propertyType'] as int?;
      _filterState.rentingTypeId = init['rentingType'] as int?;
      _filterState.statusId = init['status'] as int?;
      _filterState.minPrice = (init['minPrice'] as num?)?.toDouble();
      _filterState.maxPrice = (init['maxPrice'] as num?)?.toDouble();

      // Reflect in text field and range slider
      if (_filterState.name != null) {
        _searchController.text = _filterState.name!;
      }
      final min = _filterState.minPrice ?? _priceRange.start;
      final max = _filterState.maxPrice ?? _priceRange.end;
      _priceRange = RangeValues(min, max);
    } else {
      // Do not activate price filters by default; treat full-range as no filter
      _filterState.minPrice = null;
      _filterState.maxPrice = null;
    }

    _searchController.addListener(() {
      _filterState.name = _searchController.text;
    });

    // Prime lookup data
    final lookup = context.read<LookupProvider>();
    _propertyTypesFuture = lookup.getPropertyTypes();
    _rentingTypesFuture = lookup.getRentingTypes();
    _propertyStatusesFuture = lookup.getPropertyStatuses();

    // Bind external controller if provided so parent dialog actions can
    // retrieve the current filters and reset fields without relying on
    // the panel's internal buttons.
    widget.controller?.bind(
      getFilters: () {
        final map = <String, dynamic>{
          'nameContains': _filterState.name?.trim(),
          'propertyType': _filterState.propertyTypeId,
          'rentingType': _filterState.rentingTypeId,
          'status': _filterState.statusId,
          'minPrice': _filterState.minPrice,
          'maxPrice': _filterState.maxPrice,
          'bedrooms': _filterState.bedrooms,
          'bathrooms': _filterState.bathrooms,
          'amenityIds': _filterState.amenityIds,
          'sortBy': _filterState.sortBy,
          'ascending': _filterState.ascending,
        }..removeWhere((k, v) => v == null || (v is String && v.isEmpty));
        return map;
      },
      resetFields: () {
        _resetFilters();
      },
    );
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
      // Reset range to defaults but treat as no filter unless changed later
      _priceRange = const RangeValues(0, 5000);
      _filterState.minPrice = null;
      _filterState.maxPrice = null;
      _filterState.sortBy = null;
      _filterState.ascending = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24.0),
      color: theme.scaffoldBackgroundColor,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [
            if (widget.showSearchField) _buildSearchField(),
            const SizedBox(height: 16),
            FutureBuilder<List<LookupItem>>(
              future: _propertyTypesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return LookupDropdown(
                  label: 'Property Type',
                  lookupKey: LookupKey.propertyType,
                  value: _filterState.propertyTypeId,
                  onChanged: (id) => setState(() => _filterState.propertyTypeId = id),
                  includeAny: true,
                  anyLabel: 'Any',
                  anyValue: null,
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<LookupItem>>(
              future: _rentingTypesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return LookupDropdown(
                  label: 'Renting Type',
                  lookupKey: LookupKey.rentingType,
                  value: _filterState.rentingTypeId,
                  onChanged: (id) => setState(() => _filterState.rentingTypeId = id),
                  includeAny: true,
                  anyLabel: 'Any',
                  anyValue: null,
                );
              },
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<LookupItem>>(
              future: _propertyStatusesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 48,
                    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }
                return LookupDropdown(
                  label: 'Status',
                  lookupKey: LookupKey.propertyStatus,
                  value: _filterState.statusId,
                  onChanged: (id) => setState(() => _filterState.statusId = id),
                  includeAny: true,
                  anyLabel: 'Any',
                  anyValue: null,
                );
              },
            ),
            const SizedBox(height: 24),
            _buildPriceRangeSlider(),
            const SizedBox(height: 24),
            _buildRoomCounters(),
            const SizedBox(height: 24),
            _buildAmenitySelector(),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            _buildSortingOptions(),
            const SizedBox(height: 24),
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

  Widget _buildPriceRangeSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Price Range (USD)',
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
            Text('USD ${_priceRange.start.round()}'),
            Text('USD ${_priceRange.end.round()}'),
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

  Widget _buildSortingOptions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sort By', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String?>(
                value: _filterState.sortBy,
                decoration: const InputDecoration(
                  labelText: 'Sort Field',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sort),
                ),
                hint: const Text('Default'),
                isExpanded: true,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('Default'),
                  ),
                  ..._propertySortOptions.map((opt) => DropdownMenuItem<String?>(
                    value: opt['value'],
                    child: Text(opt['label']!),
                  )),
                ],
                onChanged: (value) => setState(() => _filterState.sortBy = value),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<bool>(
                value: _filterState.ascending,
                decoration: const InputDecoration(
                  labelText: 'Order',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: true, child: Text('Ascending')),
                  DropdownMenuItem(value: false, child: Text('Descending')),
                ],
                onChanged: (value) => setState(() => _filterState.ascending = value ?? true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Legacy action buttons removed; dialog actions manage Apply/Reset
}
