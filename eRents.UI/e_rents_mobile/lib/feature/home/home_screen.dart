import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/widgets/host_section.dart';
import 'package:e_rents_mobile/core/widgets/location_widget.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/feature/home/widgets/most_rented_props.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/feature/home/widgets/welcome_section.dart';
import 'package:flutter/material.dart';


  List<PropertyCard> properties = List.filled(3, const PropertyCard(
                  title: 'Small cottage with great view of bagmati',
                  location: 'Lukavac, TK, F.BiH',
                  details: '2 room   673 m2',
                  price: '\$526 / month',
                  rating: '4.8 (73)',
                  imageUrl: 'assets/images/house.jpg'));
  List<PropertyCard> properties2 = List.filled(5,  const PropertyCard(
                   title: 'Small cottage with great view of bagmati',
                  location: 'Lukavac, TK, F.BiH',
                  details: '2 room   673 m2',
                  price: '\$526 / month',
                  rating: '4.8 (73)',
                  imageUrl: 'assets/images/house.jpg'));

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Home', // Title for the app bar if shown
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAppBarContent(context),
              const SizedBox(height: 20),
              const SearchBar(),
              const SizedBox(height: 20),
              const WelcomeSection(),
              const SizedBox(height: 20),
              SectionHeader(title: 'Near your location', onSeeAll: () {}),
              CustomSlider(items: properties), // Replace with actual image URL
              const SizedBox(height: 20),
              SectionHeader(title: 'Top rated', onSeeAll: () {}),
              CustomSlider(items:  properties2),
              const SizedBox(height: 20),
              SectionHeader(title: 'Most rented props', onSeeAll: () {}),
              const MostRentedProps(),
              const SizedBox(height: 20),
              const HostSection(),
            ],
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     // Action for floating button
      //   },
      //   child: const Icon(Icons.add),
      // ),
      showAppBar: true, // No app bar since custom one is used
    );
  }

  Widget _buildAppBarContent(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         Row(
          children: [
            LocationWidget(title: 'MyTitle',location: 'Lukavac'),
          ],
        ),
      ],
    );
  }
}
