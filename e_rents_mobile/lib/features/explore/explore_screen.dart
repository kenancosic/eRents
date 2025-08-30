import 'package:e_rents_mobile/core/base/base_screen.dart';
// import 'package:e_rents_mobile/core/base/app_bar_config.dart'; // Removed
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart'; // Added
import 'package:e_rents_mobile/core/widgets/custom_search_bar.dart'; // Added for searchWidget
// Import FilterScreen
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/features/explore/explore_provider.dart';


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
  final PageController _pageController = PageController();
  int _selectedPropertyIndex = -1;

  final LatLng _center = const LatLng(44.5328, 18.6704); // Default center

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExploreProvider>().fetchProperties();
    });
  }

  Set<Marker> _getMarkers(List<Property> properties) {
    if (properties.isEmpty) return {};

    return properties.asMap().entries.map((entry) {
      int index = entry.key;
      Property property = entry.value;

      LatLng position = LatLng(
        property.address?.latitude ?? _center.latitude,
        property.address?.longitude ?? _center.longitude,
      );

      return Marker(
        markerId: MarkerId(property.propertyId.toString()),
        position: position,
        onTap: () => _onMarkerTapped(index),
        infoWindow: InfoWindow(
          title: '\$${property.price.toStringAsFixed(0)}',
          snippet: property.name,
        ),
        icon: _selectedPropertyIndex == index
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed)
            : BitmapDescriptor.defaultMarker,
      );
    }).toSet();
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMarkerTapped(int index) {
    setState(() {
      _selectedPropertyIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPropertyCardChanged(int index) {
    setState(() {
      _selectedPropertyIndex = index;
    });

    final properties = context.read<ExploreProvider>().properties?.items ?? [];
    if (index < properties.length) {
      Property property = properties[index];
      LatLng position = LatLng(
        property.address?.latitude ?? _center.latitude,
        property.address?.longitude ?? _center.longitude,
      );
      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(position, 15.0),
      );
    }
  }

  void _handleFilterButtonPressed() {
    context.push('/filter', extra: {
      'onApplyFilters': (Map<String, dynamic> filters) =>
          context.read<ExploreProvider>().applyFilters(filters),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreProvider>(
      builder: (context, provider, child) {
        final properties = provider.properties?.items ?? [];
        final isLoading = provider.isLoading;
        final hasError = provider.hasError;
        final errorMessage = provider.errorMessage;

        final searchBar = CustomSearchBar(
          onSearchChanged: (query) => provider.search(query),
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
              Expanded(
                flex: 6,
                child: Stack(
                  children: [
                    // Temporarily disabled GoogleMap due to missing API key and backend issues.
                    // This allows other UI elements to be verified.
                    Container(
                      color: Colors.grey[200],
                      child: Center(
                        child: Text(
                          'Map functionality requires Google Maps API Key and backend. Not available for this verification.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ),
                    ),
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
                    if (!isLoading)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 8)
                            ],
                          ),
                          child: Text(
                            '${provider.properties?.totalCount ?? 0} properties found',
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    if (isLoading && properties.isEmpty)
                      const Center(child: CircularProgressIndicator()),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Container(
                  child: (isLoading && properties.isEmpty)
                      ? const SizedBox.shrink()
                      : hasError
                          ? Center(
                              child: Text(errorMessage ?? 'An error occurred'))
                          : properties.isEmpty
                              ? const Center(
                                  child: Text('No properties found.'))
                              : Column(
                                  children: [
                                    Expanded(
                                      child: PageView.builder(
                                        controller: _pageController,
                                        onPageChanged: _onPropertyCardChanged,
                                        itemCount: properties.length,
                                        itemBuilder: (context, index) {
                                          final property = properties[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16),
                                            child: PropertyCard(
                                              layout: PropertyCardLayout
                                                  .compactHorizontal,
                                              property: property,
                                              onTap: () => context.push(
                                                  '/property/${property.propertyId}'),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    // Page indicator
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 4),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: List.generate(
                                          properties.length,
                                          (index) => AnimatedContainer(
                                            duration: const Duration(
                                                milliseconds: 300),
                                            margin: const EdgeInsets.symmetric(
                                                horizontal: 4),
                                            height: 8,
                                            width:
                                                _selectedPropertyIndex == index
                                                    ? 24
                                                    : 8,
                                            decoration: BoxDecoration(
                                              color: _selectedPropertyIndex ==
                                                      index
                                                  ? Theme.of(context)
                                                      .primaryColor
                                                  : Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
