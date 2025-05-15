import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/widgets/custom_search_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/widgets/filter_screen.dart';
import 'package:e_rents_mobile/core/widgets/location_widget.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/feature/home/widgets/most_rented_props.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  List<PropertyCard> _buildPropertyCards(BuildContext context, int count) {
    return List.filled(
      count,
      PropertyCard(
        title: 'Small cottage with great view of Bagmati',
        location: 'Lukavac, TK, F.BiH',
        details: '2 rooms   673 m2',
        price: '\$526',
        rating: '4.8',
        review: 73,
        rooms: 2,
        area: 673,
        imageUrl: 'assets/images/house.jpg',
        onTap: () {
          context.push('/property/1');
        },
      ),
    );
  }

  void _handleApplyFilters(BuildContext context, Map<String, dynamic> filters) {
    // TODO: Implement actual filter logic (e.g., update provider, refetch data)
    print('HomeScreen: Filters applied: $filters');
    // You might want to show a snackbar or some feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters applied!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final properties = _buildPropertyCards(context, 3);
    final properties2 = _buildPropertyCards(context, 5);

    final searchBar = CustomSearchBar(
      hintText: 'Search properties...',
      onSearchChanged: (query) {
        print('Search query: $query');
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
              SectionHeader(title: 'Near your location', onSeeAll: () {}),
              CustomSlider(items: properties),
              const SizedBox(height: 20),
              SectionHeader(title: 'Top rated', onSeeAll: () {}),
              CustomSlider(items: properties2),
              const SizedBox(height: 20),
              SectionHeader(title: 'Most rented properties', onSeeAll: () {}),
              const MostRentedProps(),
            ],
          ),
        ),
      ),
    );
  }
}
