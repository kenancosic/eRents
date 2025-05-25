import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/widgets/custom_search_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/widgets/location_widget.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/feature/home/widgets/upcoming_stays_section.dart';
import 'package:e_rents_mobile/feature/home/widgets/currently_residing_section.dart';
import 'package:e_rents_mobile/feature/saved/saved_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<Widget> _buildPropertyCards(BuildContext context, int count) {
    return List.generate(
      count,
      (index) => Consumer<SavedProvider>(
        builder: (context, savedProvider, child) => PropertyCard(
          title: 'Small cottage with great view of Bagmati',
          location: 'Lukavac, TK, F.BiH',
          details: '2 rooms   673 m2',
          price: '\$526',
          rating: '4.8',
          review: 73,
          rooms: 2,
          area: 673,
          imageUrl: 'assets/images/house.jpg',
          rentalType: PropertyRentalType.monthly,
          isBookmarked: savedProvider.isPropertySaved(1 + index),
          onBookmarkTap: () => _handleBookmarkTap(context, 1 + index),
          onTap: () {
            context.push('/property/1');
          },
        ),
      ),
    );
  }

  List<Widget> _buildMixedPropertyCards(BuildContext context) {
    return [
      // Daily rental property
      Consumer<SavedProvider>(
        builder: (context, savedProvider, child) => PropertyCard(
          title: 'Cozy Cottage - Daily Rental',
          location: 'Viewpoint, NV, USA',
          details: '2 rooms   874 m²',
          price: '\$75/night',
          rating: '4.8',
          review: 25,
          rooms: 2,
          area: 874,
          imageUrl: 'assets/images/house.jpg',
          rentalType: PropertyRentalType.daily,
          isBookmarked: savedProvider.isPropertySaved(1),
          onBookmarkTap: () => _handleBookmarkTap(context, 1),
          onTap: () {
            context.push('/property/1'); // Daily rental property
          },
        ),
      ),
      // Monthly lease property
      Consumer<SavedProvider>(
        builder: (context, savedProvider, child) => PropertyCard(
          title: 'Modern Downtown Apartment - Monthly Lease',
          location: 'Downtown, NY, USA',
          details: '1 bedroom   650 m²',
          price: '\$1,850/month',
          rating: '4.6',
          review: 18,
          rooms: 1,
          area: 650,
          imageUrl: 'assets/images/appartment.jpg',
          rentalType: PropertyRentalType.monthly,
          isBookmarked: savedProvider.isPropertySaved(300),
          onBookmarkTap: () => _handleBookmarkTap(context, 300),
          onTap: () {
            context.push('/property/300'); // Monthly rental property
          },
        ),
      ),
      // Another daily rental
      Consumer<SavedProvider>(
        builder: (context, savedProvider, child) => PropertyCard(
          title: 'Beachside Villa Getaway',
          location: 'Paradise City, FL, USA',
          details: '3 rooms   1200 m²',
          price: '\$120/night',
          rating: '4.9',
          review: 45,
          rooms: 3,
          area: 1200,
          imageUrl: 'assets/images/house.jpg',
          rentalType: PropertyRentalType.daily,
          isBookmarked: savedProvider.isPropertySaved(102),
          onBookmarkTap: () => _handleBookmarkTap(context, 102),
          onTap: () {
            context.push('/property/102'); // Daily rental property
          },
        ),
      ),
    ];
  }

  void _handleApplyFilters(BuildContext context, Map<String, dynamic> filters) {
    // TODO: Implement actual filter logic (e.g., update provider, refetch data)
    // print('HomeScreen: Filters applied: $filters'); // Removed print
    // You might want to show a snackbar or some feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters applied!')),
    );
  }

  Future<void> _handleBookmarkTap(BuildContext context, int propertyId) async {
    // Create a mock property for the bookmark action
    // In a real app, you'd fetch the actual property data
    final mockProperty = Property(
      propertyId: propertyId,
      ownerId: 1,
      name: 'Property $propertyId',
      price: 0,
      images: [],
      rentalType: PropertyRentalType.daily,
    );

    final savedProvider = context.read<SavedProvider>();
    await savedProvider.toggleSavedStatus(mockProperty);

    if (context.mounted) {
      final isNowSaved = savedProvider.isPropertySaved(propertyId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNowSaved ? 'Property saved!' : 'Property removed from saved',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final properties = _buildPropertyCards(context, 3);
    final mixedProperties =
        _buildMixedPropertyCards(context); // Mix of daily and monthly

    final searchBar = CustomSearchBar(
      hintText: 'Search properties...',
      onSearchChanged: (query) {
        // print('Search query: $query'); // Removed print
      },
      showFilterIcon: true,
      onFilterIconPressed: () {
        context.push('/filter', extra: {
          'onApplyFilters': (Map<String, dynamic> filters) =>
              _handleApplyFilters(context, filters),
          // 'initialFilters': {}, // Store and pass current filters if needed
        });
      },
    );

    final locationWidgetForAppBar = const LocationWidget(
        title: 'Welcome back, User',
        location: 'Lukavac'); // This is your custom LocationWidget

    final appBar = CustomAppBar(
      showSearch: true,
      searchWidget: searchBar,
      showAvatar: true,
      avatarWidget: Builder(builder: (BuildContext avatarContext) {
        return CustomAvatar(
          imageUrl: 'assets/images/user-image.png',
          onTap: () {
            BaseScreenState.of(avatarContext)?.toggleDrawer();
          },
        );
      }),
      showBackButton:
          false, // Explicitly false so avatar is the leading element
      userLocationWidget:
          locationWidgetForAppBar, // Pass the LocationWidget for the second row
      actions: [],
    );

    return BaseScreen(
      showAppBar: true,
      useSlidingDrawer: true,
      appBar: appBar,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // LocationWidget is now part of the AppBar, so remove from body if not needed here too.
              // const LocationWidget(title: 'Welcome back, User', location: 'Lukavac'),
              const SizedBox(height: 20), // Adjust spacing as needed

              // Currently Residing Section
              CurrentlyResidingSection(),
              const SizedBox(height: 20),

              // Upcoming Stays Section
              UpcomingStaysSection(),
              const SizedBox(height: 20),

              SectionHeader(title: 'Near your location', onSeeAll: () {}),
              CustomSlider(items: properties),
              const SizedBox(height: 20),
              SectionHeader(
                  title: 'Featured Properties (Daily & Monthly)',
                  onSeeAll: () {}),
              CustomSlider(items: mixedProperties),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
