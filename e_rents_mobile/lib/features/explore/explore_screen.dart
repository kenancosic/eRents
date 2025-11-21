import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_search_bar.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/features/explore/providers/property_search_provider.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:e_rents_mobile/core/widgets/empty_state_widget.dart';
import 'package:e_rents_mobile/core/widgets/error_state_widget.dart';


import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late GoogleMapController _mapController;
  bool _isMapExpanded = false;  // Map collapsed by default for better mobile UX

  final LatLng _center = const LatLng(44.5328, 18.6704); // Default center

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize with current user's city and sensible defaults
      context.read<PropertySearchProvider>().initializeWithUserCity();
    });
  }

  Set<Marker> _getMarkers(List<PropertyCardModel> properties) {
    if (properties.isEmpty) return {};

    return properties.asMap().entries.map((entry) {
      final property = entry.value;

      LatLng position = LatLng(
        property.address?.latitude ?? _center.latitude,
        property.address?.longitude ?? _center.longitude,
      );

      return Marker(
        markerId: MarkerId(property.propertyId.toString()),
        position: position,
        infoWindow: InfoWindow(
          title: '\$${property.price.toStringAsFixed(0)}',
          snippet: property.name,
        ),
        icon: BitmapDescriptor.defaultMarker,
      );
    }).toSet();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }


  void _handleFilterButtonPressed() {
    final provider = context.read<PropertySearchProvider>();
    final current = provider.currentFilters;

    String mapRentalToUi(dynamic rentingType) {
      final v = rentingType?.toString().toLowerCase();
      if (v == 'daily') return 'Per day';
      if (v == 'monthly') return 'Monthly';
      return 'Any';
    }

    final double minPrice = (current['minPrice'] ?? current['MinPrice'] ?? 0).toDouble();
    final double maxPrice = (current['maxPrice'] ?? current['MaxPrice'] ?? 5000).toDouble();
    final String propertyTypeUi = (current['propertyType'] ?? current['PropertyType'] ?? 'Any').toString();
    final String rentalUi = mapRentalToUi(current['rentingType'] ?? current['RentingType']);
    final String city = (current['city'] ?? current['City'] ?? '').toString();
    final String? sortBy = (current['sortBy'] ?? current['SortBy'])?.toString();
    final String? sortDir = (current['sortDirection'] ?? current['SortDirection'])?.toString();
    // Date and partial availability (if previously applied)
    final String? startDate = (current['StartDate'] ?? current['startDate'])?.toString();
    final String? endDate = (current['EndDate'] ?? current['endDate'])?.toString();
    final bool? includePartialDaily = (current['IncludePartialDaily'] is bool)
        ? current['IncludePartialDaily'] as bool
        : (current['includePartialDaily'] is bool)
            ? current['includePartialDaily'] as bool
            : null;

    final initialFilters = {
      'propertyType': propertyTypeUi,
      'priceRange': RangeValues(minPrice, maxPrice),
      'rentalPeriod': rentalUi,
      if (city.isNotEmpty) 'city': city,
      if (sortBy != null) 'sortBy': sortBy,
      if (sortDir != null) 'sortDirection': sortDir,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
      if (includePartialDaily != null) 'includePartialDaily': includePartialDaily,
      // 'facilities' omitted; defaults handled in FilterScreen
    };

    context.push('/filter', extra: {
      'onApplyFilters': (Map<String, dynamic> filters) => provider.applyFilters(filters),
      'initialFilters': initialFilters,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertySearchProvider>(
      builder: (context, provider, child) {
        final properties = provider.properties?.items ?? [];
        final isLoading = provider.isLoading;
        final hasError = provider.hasError;
        final errorMessage = provider.errorMessage;

        final searchBar = CustomSearchBar(
          onSearchChanged: (query) {
            // For search, we'll apply a filter with the search query
            final filters = <String, dynamic>{'searchTerm': query};
            provider.applyFilters(filters);
          },
          hintText: 'Search places...',
          showFilterIcon: true,
          onFilterIconPressed: _handleFilterButtonPressed,
        );

        final appBar = CustomAppBar(
          showSearch: true,
          searchWidget: searchBar,
          showBackButton: false,
        );

        return BaseScreen(
          useSlidingDrawer: false,
          appBar: appBar,
          body: Column(
            children: [
              // Collapsible map section
              GestureDetector(
                onTap: () => setState(() => _isMapExpanded = !_isMapExpanded),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: _isMapExpanded ? 300 : 80,
                  child: Stack(
                    children: [
                      // Temporarily disabled GoogleMap due to missing API key and backend issues.
                      // This allows other UI elements to be verified.
                      if (_isMapExpanded)
                        Container(
                          color: AppColors.surfaceLight,
                          child: Center(
                            child: Text(
                              'Map functionality requires Google Maps API Key and backend. Not available for this verification.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                        )
                      else
                        _buildCollapsedMapHeader(provider),
                    // Original GoogleMap code commented out:
                    /*
                    GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: _center,
                        zoom: 14.0,
                      ),
                      markers: _getMarkers(properties),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                    ),
                    */
                      if (!isLoading && _isMapExpanded)
                        Positioned(
                          top: AppSpacing.md,
                          left: AppSpacing.md,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AppRadius.xlRadius,
                              boxShadow: AppShadows.sm,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on, size: 16, color: AppColors.primary),
                                SizedBox(width: AppSpacing.xs),
                                Text(
                                  '${provider.properties?.totalCount ?? 0} properties',
                                  style: const TextStyle(
                                      fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (isLoading && properties.isEmpty)
                        const Center(child: CircularProgressIndicator()),
                      // Toggle button
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: FloatingActionButton.small(
                          heroTag: 'map_toggle',
                          backgroundColor: AppColors.primary,
                          child: Icon(_isMapExpanded ? Icons.expand_less : Icons.map, color: Colors.white),
                          onPressed: () => setState(() => _isMapExpanded = !_isMapExpanded),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Property list (takes remaining space)
              Expanded(
                child: Container(
                  child: (isLoading && properties.isEmpty)
                      ? const Center(child: CircularProgressIndicator())
                      : hasError
                          ? ErrorStateWidget(
                              message: errorMessage.isEmpty ? 'An error occurred' : errorMessage,
                              onRetry: () => provider.initializeWithUserCity(),
                            )
                          : properties.isEmpty
                              ? EmptyStateWidget(
                                  icon: Icons.search_off,
                                  title: 'No properties found',
                                  message: 'Try adjusting your search filters',
                                  actionText: 'Reset Filters',
                                  onAction: () {
                                    provider.resetFilters();
                                    provider.initializeWithUserCity();
                                  },
                                )
                              : ListView.builder(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  itemCount: properties.length,
                                  itemBuilder: (context, index) {
                                    final card = properties[index];
                                    return Padding(
                                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                                      child: PropertyCard(
                                        layout: _isMapExpanded 
                                            ? PropertyCardLayout.compactHorizontal
                                            : PropertyCardLayout.horizontal,
                                        property: card,
                                        onTap: () => context.push(
                                            '/property/${card.propertyId}'),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCollapsedMapHeader(PropertySearchProvider provider) {
    return Container(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          Icon(Icons.location_on, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${provider.properties?.totalCount ?? 0} properties',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Tap to view map',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.expand_more, color: Colors.grey[600]),
        ],
      ),
    );
  }
}
