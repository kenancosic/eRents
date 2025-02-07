import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/widgets/location_widget.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/feature/home/widgets/most_rented_props.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final List<PropertyCard> properties = List.filled(
    3,
    const PropertyCard(
      title: 'Small cottage with great view of Bagmati',
      location: 'Lukavac, TK, F.BiH',
      details: '2 rooms   673 m2',
      price: '\$526',
      rating: '4.8 (73)',
      imageUrl: 'assets/images/house.jpg',
    ),
  );

  final List<PropertyCard> properties2 = List.filled(
    5,
    const PropertyCard(
      title: 'Small cottage with great view of Bagmati',
      location: 'Lukavac, TK, F.BiH',
      details: '2 rooms   673 m2',
      price: '\$526',
      rating: '4.8 (73)',
      imageUrl: 'assets/images/house.jpg',
    ),
  );

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      // Since we are using a custom title widget, we can set title to null
      title: null,
      showAppBar: true,
      useSlidingDrawer: true,
      showBackButton: false,
      showFilterButton: true,
      // Passing the LocationWidget as a custom title widget
      locationWidget: const LocationWidget(
          title: 'Welcome back, User', location: 'Lukavac'),
      onSearchChanged: (query) {
        // Handle search query
        print('Search query: $query');
      },
      searchHintText: 'Search properties...',
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.grey),
          onPressed: () {
            // Handle notifications
          },
        ),
      ],
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            // Removed the custom app bar content from the body
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              SectionHeader(title: 'Near your location', onSeeAll: () {}),
              CustomSlider(items: properties),
              const SizedBox(height: 20),
              SectionHeader(title: 'Top rated', onSeeAll: () {}),
              CustomSlider(items: properties2),
              const SizedBox(height: 20),
              SectionHeader(title: 'Most rented properties', onSeeAll: () {}),
              const MostRentedProps(),
              // const SizedBox(height: 20),
              // const HostSection(),
            ],
          ),
        ),
      ),
    );
  }
}
