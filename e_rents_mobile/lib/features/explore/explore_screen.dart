import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/places_autocomplete_field.dart';
import 'package:e_rents_mobile/core/services/google_places_service.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';
import 'package:e_rents_mobile/features/explore/providers/property_search_provider.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:e_rents_mobile/core/widgets/empty_state_widget.dart';
import 'package:e_rents_mobile/core/widgets/error_state_widget.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';


import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  bool _isMapExpanded = false;

  LatLng _center = const LatLng(44.5328, 18.6704); // Default center (Tuzla, BiH)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Initialize with current user's city and sensible defaults
      final currentUserProvider = context.read<CurrentUserProvider>();
      context.read<PropertySearchProvider>().initializeWithUserCity(currentUserProvider);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Marker> _getMarkers(List<PropertyCardModel> properties) {
    if (properties.isEmpty) return [];

    return properties.map((property) {
      final LatLng position = LatLng(
        property.address?.latitude ?? _center.latitude,
        property.address?.longitude ?? _center.longitude,
      );

      return Marker(
        point: position,
        width: 90,
        height: 52,
        child: GestureDetector(
          onTap: () => _showPropertyInfo(property),
          child: _buildMapMarker(property),
        ),
      );
    }).toList();
  }

  Widget _buildMapMarker(PropertyCardModel property) {
    final isDaily = property.rentalType == PropertyRentalType.daily;
    final markerColor = isDaily ? AppColors.info : AppColors.success;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Price badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                markerColor,
                markerColor.withValues(alpha: 0.85),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: markerColor.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '\$${property.price.toStringAsFixed(0)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  letterSpacing: -0.3,
                ),
              ),
              if (isDaily) ...[
                const SizedBox(width: 2),
                Text(
                  '/n',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Pin indicator triangle
        CustomPaint(
          size: const Size(12, 8),
          painter: _MarkerTrianglePainter(color: markerColor),
        ),
      ],
    );
  }

  void _showPropertyInfo(PropertyCardModel property) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(property.name),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => context.push('/property/${property.propertyId}'),
        ),
      ),
    );
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

        final searchBar = Row(
          children: [
            Expanded(
              child: PlacesAutocompleteField(
                controller: _searchController,
                hintText: 'Search by city or location...',
                searchType: '(cities)',
                onPlaceSelected: (PlaceDetails? place) {
                  debugPrint('ExploreScreen: onPlaceSelected called with place: ${place != null}');
                  if (place != null) {
                    // Update map center and filter properties by location
                    final newCenter = LatLng(
                      place.geometry.location.lat,
                      place.geometry.location.lng,
                    );
                    debugPrint('ExploreScreen: New center - lat: ${newCenter.latitude}, lng: ${newCenter.longitude}');
                    setState(() => _center = newCenter);
                    
                    // Move map to new location - always try to move
                    debugPrint('ExploreScreen: Map expanded: $_isMapExpanded, moving map...');
                    try {
                      _mapController.move(newCenter, 12.0);
                    } catch (e) {
                      debugPrint('ExploreScreen: Error moving map: $e');
                    }
                    
                    // Apply city filter - use 'City' (uppercase) to match backend expectations
                    final cityName = place.bestCityName ?? place.city ?? '';
                    debugPrint('ExploreScreen: Applying filter - city: "$cityName"');
                    if (cityName.isNotEmpty) {
                      provider.applyFilters({
                        'City': cityName,
                        'latitude': place.geometry.location.lat,
                        'longitude': place.geometry.location.lng,
                      });
                    } else {
                      debugPrint('ExploreScreen: City name is empty, trying formatted address');
                      // Fallback: use the main text from formatted address
                      final parts = place.formattedAddress.split(',');
                      if (parts.isNotEmpty) {
                        final fallbackCity = parts.first.trim();
                        debugPrint('ExploreScreen: Using fallback city: "$fallbackCity"');
                        provider.applyFilters({
                          'City': fallbackCity,
                          'latitude': place.geometry.location.lat,
                          'longitude': place.geometry.location.lng,
                        });
                      }
                    }
                  } else {
                    debugPrint('ExploreScreen: Place is null, clearing filter');
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.tune),
              onPressed: _handleFilterButtonPressed,
              tooltip: 'Filters',
            ),
          ],
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
                      // OpenStreetMap powered by flutter_map (free, no API key needed)
                      if (_isMapExpanded)
                        FlutterMap(
                          mapController: _mapController,
                          options: MapOptions(
                            initialCenter: _center,
                            initialZoom: 14.0,
                            minZoom: 4.0,
                            maxZoom: 18.0,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName: 'com.erents.mobile',
                            ),
                            MarkerLayer(markers: _getMarkers(properties)),
                          ],
                        )
                      else
                        _buildCollapsedMapHeader(provider),
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
                              onRetry: () => provider.initializeWithUserCity(context.read<CurrentUserProvider>()),
                            )
                          : properties.isEmpty
                              ? EmptyStateWidget(
                                  icon: Icons.search_off,
                                  title: 'No properties found',
                                  message: 'Try adjusting your search filters',
                                  actionText: 'Reset Filters',
                                  onAction: () {
                                    provider.resetFilters();
                                    provider.initializeWithUserCity(context.read<CurrentUserProvider>());
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

/// Custom painter for the triangular pin indicator below the marker
class _MarkerTrianglePainter extends CustomPainter {
  final Color color;

  _MarkerTrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Use dart:ui Path explicitly to avoid conflict with flutter_map's Path
    final path = ui.Path();
    path.moveTo(0, 0);
    path.lineTo(size.width / 2, size.height);
    path.lineTo(size.width, 0);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MarkerTrianglePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
