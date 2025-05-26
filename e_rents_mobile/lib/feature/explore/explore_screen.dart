import 'package:e_rents_mobile/core/base/base_screen.dart';
// import 'package:e_rents_mobile/core/base/app_bar_config.dart'; // Removed
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart'; // Added
import 'package:e_rents_mobile/core/widgets/custom_search_bar.dart'; // Added for searchWidget
import 'package:e_rents_mobile/core/widgets/elevated_text_button.dart';
// Import FilterScreen
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/address_detail.dart';
import 'package:e_rents_mobile/core/models/geo_region.dart';
import 'package:e_rents_mobile/core/models/image_response.dart';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late GoogleMapController mapController;
  final PageController _pageController = PageController();
  int _selectedPropertyIndex = 0;

  final LatLng _center = const LatLng(44.5328, 18.6704);

  // Sample properties using your existing Property model
  late final List<Property> _properties;

  @override
  void initState() {
    super.initState();
    _initializeProperties();
  }

  void _initializeProperties() {
    // Mock data using your existing Property structure
    _properties = [
      Property(
        propertyId: 1,
        ownerId: 1,
        name: 'Small cottage in the center of town',
        description: 'Cozy cottage perfect for a peaceful stay',
        price: 526.0,
        status: 'Available',
        dateAdded: DateTime.now(),
        averageRating: 4.8,
        images: [
          ImageResponse(
            imageId: 1,
            fileName: 'assets/images/house.jpg',
            imageData: ByteData(0),
            dateUploaded: DateTime.now(),
          ),
        ],
        addressDetailId: 1,
        addressDetail: AddressDetail(
          addressDetailId: 1,
          geoRegionId: 1,
          streetLine1: 'Main Street 123',
          latitude: 44.5328,
          longitude: 18.6704,
          geoRegion: GeoRegion(
            geoRegionId: 1,
            city: 'Lukavac',
            state: 'T.K.',
            country: 'F.BiH',
          ),
        ),
        rentalType: PropertyRentalType.monthly,
        minimumStayDays: 30,
      ),
      Property(
        propertyId: 2,
        ownerId: 2,
        name: 'Entire private villa in Tuzla City',
        description: 'Beautiful villa with modern amenities',
        price: 400.0,
        status: 'Available',
        dateAdded: DateTime.now(),
        averageRating: 4.9,
        images: [
          ImageResponse(
            imageId: 2,
            fileName: 'assets/images/house.jpg',
            imageData: ByteData(0),
            dateUploaded: DateTime.now(),
          ),
        ],
        addressDetailId: 2,
        addressDetail: AddressDetail(
          addressDetailId: 2,
          geoRegionId: 2,
          streetLine1: 'Villa Street 456',
          latitude: 44.5398,
          longitude: 18.6804,
          geoRegion: GeoRegion(
            geoRegionId: 2,
            city: 'Tuzla',
            state: 'T.K.',
            country: 'F.BiH',
          ),
        ),
        rentalType: PropertyRentalType.daily,
        dailyRate: 400.0,
        minimumStayDays: 3,
      ),
      Property(
        propertyId: 3,
        ownerId: 3,
        name: 'Entire rental unit, close to main square',
        description: 'Prime location rental unit',
        price: 1290.0,
        status: 'Available',
        dateAdded: DateTime.now(),
        averageRating: 4.8,
        images: [
          ImageResponse(
            imageId: 3,
            fileName: 'assets/images/house.jpg',
            imageData: ByteData(0),
            dateUploaded: DateTime.now(),
          ),
        ],
        addressDetailId: 3,
        addressDetail: AddressDetail(
          addressDetailId: 3,
          geoRegionId: 3,
          streetLine1: 'Square Avenue 789',
          latitude: 44.5258,
          longitude: 18.6654,
          geoRegion: GeoRegion(
            geoRegionId: 3,
            city: 'Tuzla',
            state: 'T.K.',
            country: 'F.BiH',
          ),
        ),
        rentalType: PropertyRentalType.both,
        dailyRate: 120.0,
        minimumStayDays: 7,
      ),
    ];
  }

  Set<Marker> get _markers {
    return _properties.asMap().entries.map((entry) {
      int index = entry.key;
      Property property = entry.value;

      // Use coordinates from addressDetail
      LatLng position = LatLng(
        property.addressDetail?.latitude ?? _center.latitude,
        property.addressDetail?.longitude ?? _center.longitude,
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
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      );
    }).toSet();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
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

    Property property = _properties[index];
    LatLng position = LatLng(
      property.addressDetail?.latitude ?? _center.latitude,
      property.addressDetail?.longitude ?? _center.longitude,
    );

    mapController.animateCamera(
      CameraUpdate.newLatLngZoom(position, 15.0),
    );
  }

  void _handleSearchChanged(String query) {
    // TODO: Implement search logic
  }

  void _handleFilterButtonPressed() {
    context.push('/filter', extra: {
      'onApplyFilters': (Map<String, dynamic> filters) =>
          _handleApplyFilters(context, filters),
    });
  }

  void _handleApplyFilters(BuildContext context, Map<String, dynamic> filters) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters applied to map/list!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchBar = CustomSearchBar(
      onSearchChanged: _handleSearchChanged,
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
          // Map Section (60% of screen)
          Expanded(
            flex: 6,
            child: Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _center,
                    zoom: 14.0,
                  ),
                  markers: _markers,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                ),
                // Results counter overlay
                Positioned(
                  top: 16,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '${_properties.length} properties',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Property List Section (40% of screen)
          Expanded(
            flex: 4,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle indicator
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Section title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Available Properties',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        ElevatedTextButton(
                          text: 'View All',
                          isCompact: true,
                          onPressed: () {
                            // TODO: Navigate to full list view
                          },
                        ),
                      ],
                    ),
                  ),
                  // Horizontal property list
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPropertyCardChanged,
                      itemCount: _properties.length,
                      itemBuilder: (context, index) {
                        final property = _properties[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: PropertyCard(
                            layout: PropertyCardLayout.compactHorizontal,
                            property: property,
                            onTap: () {
                              context.push('/property/${property.propertyId}');
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  // Page indicator
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _properties.length,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 8,
                          width: _selectedPropertyIndex == index ? 24 : 8,
                          decoration: BoxDecoration(
                            color: _selectedPropertyIndex == index
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(4),
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
  }
}
