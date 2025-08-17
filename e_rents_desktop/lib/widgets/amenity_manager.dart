import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/providers/lookup_provider.dart';
import 'package:e_rents_desktop/models/lookup_item.dart';

/// A modern, reusable amenity widget that can work in both view and edit modes.
/// Uses the new AmenityService to fetch amenities from the AmenitiesController backend.
class AmenityManager extends StatefulWidget {
  /// Mode of the widget
  final AmenityManagerMode mode;

  /// Initial amenity IDs (for efficiency - what we send to backend)
  final List<int>? initialAmenityIds;

  /// Initial amenity names (for display - what we show to user)
  final List<String>? initialAmenityNames;

  /// Callback when amenities change (returns amenity IDs for backend efficiency)
  final Function(List<int> amenityIds)? onAmenityIdsChanged;

  /// Whether to show section title
  final bool showTitle;

  /// Custom title text
  final String? titleText;

  /// Whether to show add button (only in edit mode)
  final bool allowCustomAmenities;

  /// Maximum number of amenities that can be selected
  final int? maxSelection;

  const AmenityManager({
    super.key,
    required this.mode,
    this.initialAmenityIds,
    this.initialAmenityNames,
    this.onAmenityIdsChanged,
    this.showTitle = true,
    this.titleText,
    this.allowCustomAmenities = true,
    this.maxSelection,
  });

  @override
  State<AmenityManager> createState() => _AmenityManagerState();
}

class _AmenityManagerState extends State<AmenityManager> {
  List<int> _selectedAmenityIds = [];
  List<LookupItem> _availableAmenities = [];
  Map<int, LookupItem> _amenityMap = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  // Hold the amenities Future once to avoid recreating it every build
  Future<List<LookupItem>>? _amenitiesFuture;

  @override
  void initState() {
    super.initState();
    _selectedAmenityIds = List.from(widget.initialAmenityIds ?? []);
    // Initialize the amenities future once to prevent infinite loading loops
    // caused by creating a new Future on each build
    _amenitiesFuture = context.read<LookupProvider>().getAmenities();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _buildAmenityMap() {
    // Create amenity map from the list
    _amenityMap = {};
    for (final amenity in _availableAmenities) {
      _amenityMap[amenity.value] = amenity;
    }
  }

  void _toggleAmenity(int amenityId) {
    if (widget.mode == AmenityManagerMode.view) return;

    setState(() {
      if (_selectedAmenityIds.contains(amenityId)) {
        _selectedAmenityIds.remove(amenityId);
      } else {
        // Check max selection limit
        if (widget.maxSelection != null &&
            _selectedAmenityIds.length >= widget.maxSelection!) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Maximum ${widget.maxSelection} amenities allowed'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }
        _selectedAmenityIds.add(amenityId);
      }
    });

    // Notify parent of change
    widget.onAmenityIdsChanged?.call(_selectedAmenityIds);
  }

  List<LookupItem> get _filteredAmenities {
    if (_searchQuery.isEmpty) return _availableAmenities;

    return _availableAmenities
        .where(
          (amenity) =>
              amenity.text.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LookupProvider>(
      builder: (context, lookupProvider, child) {
        return FutureBuilder<List<LookupItem>>(
          future: _amenitiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load amenities: ${snapshot.error}',
                        style: TextStyle(color: Colors.red.shade700),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {}); // Retry by rebuilding
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            _availableAmenities = snapshot.data ?? [];
            _buildAmenityMap();
            return _buildContent(theme);
          },
        );
      },
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTitle && widget.mode != AmenityManagerMode.select) ...[
          Row(
            children: [
              Icon(Icons.deck_outlined, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                widget.titleText ?? 'Amenities',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              if (widget.mode == AmenityManagerMode.edit)
                Text(
                  '${_selectedAmenityIds.length}${widget.maxSelection != null ? '/${widget.maxSelection}' : ''} selected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          ),
          const Divider(height: 24, thickness: 1),
        ],

        // Search bar (only in edit mode with many amenities)
        if (widget.mode == AmenityManagerMode.edit &&
            _availableAmenities.length > 6) ...[
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: 'Search amenities',
              hintText: 'Type to filter amenities...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                      : null,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
          const SizedBox(height: 16),
        ],

        // Amenities display
        if (_selectedAmenityIds.isEmpty &&
            widget.mode == AmenityManagerMode.view)
          _buildEmptyState()
        else
          _buildAmenitiesContent(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Text(
            'No amenities specified',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesContent() {
    if (widget.mode == AmenityManagerMode.view) {
      return _buildViewMode();
    } else {
      return _buildInteractiveMode();
    }
  }

  Widget _buildViewMode() {
    // Show only selected amenities in view mode
    final selectedAmenities =
        _selectedAmenityIds
            .map((id) => _amenityMap[id])
            .where((amenity) => amenity != null)
            .cast<LookupItem>()
            .toList();

    if (selectedAmenities.isEmpty) {
      return _buildEmptyState();
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: selectedAmenities.map((amenity) {
        final icon = _getFlutterIconFromName(amenity.text);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 6),
              Text(
                amenity.text,
                style: TextStyle(
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInteractiveMode() {
    final filtered = _filteredAmenities;

    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No amenities found for "$_searchQuery"'
                  : 'No amenities available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: filtered.map((amenity) {
        final isSelected = _selectedAmenityIds.contains(amenity.value);
        final icon = _getFlutterIconFromName(amenity.text);

        return FilterChip(
          selected: isSelected,
          avatar: Icon(
            icon,
            size: 18,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
          label: Text(amenity.text),
          onSelected: (_) => _toggleAmenity(amenity.value),
          selectedColor: Colors.blue.shade600,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade800,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  IconData _getFlutterIconFromName(String amenityName) {
    // Map amenity names to appropriate Flutter icon names
    // This ensures icons are determined by name rather than backend icon field
    // This approach is more robust when amenity IDs are inconsistent
    switch (amenityName.toLowerCase()) {
      case 'wi-fi':
      case 'wifi':
        return Icons.wifi;
      case 'air conditioning':
      case 'ac':
        return Icons.ac_unit;
      case 'parking':
        return Icons.local_parking;
      case 'heating':
        return Icons.thermostat;
      case 'balcony':
        return Icons.balcony;
      case 'pool':
        return Icons.pool;
      case 'gym':
      case 'fitness':
        return Icons.fitness_center;
      case 'kitchen':
        return Icons.kitchen;
      case 'laundry':
        return Icons.local_laundry_service;
      case 'pet friendly':
      case 'pets':
        return Icons.pets;
      case 'elevator':
        return Icons.elevator;
      case 'security':
        return Icons.security;
      case 'garden':
        return Icons.eco;
      case 'furnished':
        return Icons.chair;
      default:
        return Icons.check_circle; // Default icon
    }
  }
}

enum AmenityManagerMode {
  view, // Display-only mode (for property details)
  edit, // Interactive mode with search and title (for property form)
  select, // Interactive selection mode for filters (no title/search)
}
