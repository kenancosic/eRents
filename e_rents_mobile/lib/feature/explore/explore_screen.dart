import 'package:e_rents_mobile/core/base/base_screen.dart';
// import 'package:e_rents_mobile/core/base/app_bar_config.dart'; // Removed
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart'; // Added
import 'package:e_rents_mobile/core/widgets/custom_search_bar.dart'; // Added for searchWidget
import 'package:e_rents_mobile/core/widgets/filter_screen.dart'; // Import FilterScreen
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:go_router/go_router.dart'; // Add GoRouter import

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  _ExploreScreenState createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late GoogleMapController mapController;
  final PanelController _panelController =
      PanelController(); // Controller for SlidingUpPanel
  bool _isDraggable = false; // Control panel dragging

  final LatLng _center =
      const LatLng(44.5328, 18.6704); // Example: Coordinates for Lukavac

  final Set<Marker> _markers = {
    const Marker(
      markerId: MarkerId('marker_1'),
      position: LatLng(44.5328, 18.6704),
      infoWindow: InfoWindow(
        title: '\$2,430',
      ),
    ),
    // Add more markers as needed
  };

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void _handleSearchChanged(String query) {
    // TODO: Implement search logic
    // print('Search query: $query'); // Removed print
  }

  void _handleFilterButtonPressed() {
    context.push('/filter', extra: {
      'onApplyFilters': (Map<String, dynamic> filters) =>
          _handleApplyFilters(context, filters),
      // 'initialFilters': _currentFilters, // Pass current filters if you have them stored
    });
  }

  void _handleApplyFilters(BuildContext context, Map<String, dynamic> filters) {
    // TODO: Implement actual filter logic for ExploreScreen
    // print('ExploreScreen: Filters applied: $filters'); // Removed print
    // Example: update markers on the map, refresh list in panel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters applied to map/list!')),
    );
    // Potentially store these filters in the state if needed for re-passing
    // setState(() {
    //   _currentFilters = filters;
    // });
  }

  @override
  Widget build(BuildContext context) {
    final searchBar = CustomSearchBar(
      onSearchChanged: _handleSearchChanged,
      hintText: 'Search places...',
      showFilterIcon: true, // Keep filter icon inside search bar
      onFilterIconPressed: _handleFilterButtonPressed,
      // searchHistory: [], // Optional: Provide search history
      // localData: [], // Optional: Provide local data for suggestions
    );

    final appBar = CustomAppBar(
      showSearch: true,
      searchWidget: searchBar,
      showBackButton: false,
    );

    return BaseScreen(
      useSlidingDrawer: false,
      appBar: appBar,
      body: Stack(
        children: [
          // Google Map
          Positioned.fill(
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: CameraPosition(
                target: _center,
                zoom: 14.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: (LatLng location) {
                // Add interaction for tapping on the map (if needed)
              },
            ),
          ),
          // SlidingUpPanel for Property List
          SlidingUpPanel(
            controller: _panelController,
            minHeight:
                MediaQuery.of(context).size.height * 0.15, // Minimized view
            maxHeight:
                MediaQuery.of(context).size.height * 0.9, // Expanded view
            snapPoint: 0.5, // Snap at 50% of the screen
            isDraggable:
                _isDraggable, // Make it draggable only based on handle interaction
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            panelBuilder: (ScrollController sc) => Column(
              children: [
                // Drag Handle Indicator with GestureDetector to manage dragging
                GestureDetector(
                  onVerticalDragUpdate: (details) {
                    setState(() {
                      _isDraggable = true; // Enable dragging
                    });

                    // Clamp the panel position between 0.0 and 1.0
                    final newPosition = (_panelController.panelPosition +
                            details.primaryDelta! /
                                MediaQuery.of(context).size.height)
                        .clamp(0.0, 1.0);

                    _panelController.panelPosition = newPosition;
                  },
                  onVerticalDragEnd: (details) {
                    setState(() {
                      _isDraggable =
                          false; // Disable dragging after user stops dragging
                    });
                    // Snap to 0.5 or 1.0 height based on user velocity and drag direction
                    if (details.velocity.pixelsPerSecond.dy > 0) {
                      _panelController.close(); // Minimize
                    } else {
                      _panelController.open(); // Maximize
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withAlpha((255 * 0.7).round()), // Fixed withOpacity
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // "Showing results" and Sort/Filter row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Showing 72 results',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Property List - Only Scrollable content
                Expanded(
                  child: SafeArea(
                    child: ListView(
                      controller: sc,
                      children: [
                        PropertyCard(
                          title: 'Small cottage in the center of town',
                          location: 'Lukavac, T.K., F.BiH',
                          details: '',
                          price: '\$526',
                          rating: '4.8',
                          imageUrl: 'assets/images/house.jpg',
                          review: 73,
                          rooms: 2,
                          area: 673,
                          onTap: () {
                            context.push('/property/1');
                          },
                        ),
                        PropertyCard(
                          title: 'Entire private villa in Tuzla City',
                          location: 'Tuzla, T.K., F.BiH',
                          details: '',
                          price: '\$400',
                          rating: '4.9',
                          imageUrl: 'assets/images/house.jpg',
                          review: 104,
                          rooms: 2,
                          area: 488,
                          onTap: () {
                            context.push('/property/2');
                          },
                        ),
                        PropertyCard(
                          title: 'Entire rental unit, close to main square',
                          location: 'Tuzla, T.K., F.BiH',
                          details: '',
                          price: '\$1,290',
                          rating: '4.8',
                          imageUrl: 'assets/images/house.jpg',
                          review: 73,
                          rooms: 2,
                          area: 874,
                          onTap: () {
                            context.push('/property/3');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            body: Container(),
          ),
        ],
      ),
    );
  }
}
