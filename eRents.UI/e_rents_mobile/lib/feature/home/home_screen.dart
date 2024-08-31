import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/widgets/host_section.dart';
import 'package:e_rents_mobile/core/widgets/location_widget.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/feature/home/widgets/most_rented_props.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/feature/home/widgets/welcome_section.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BaseScreen(
      title: 'Home', // Title for the app bar if shown
      body: SingleChildScrollView(
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
            _buildSection(
              title: 'Near your location',
              properties: _buildPropertyList(3),
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: 'Top rated',
              properties: _buildPropertyList(5),
            ),
            const SizedBox(height: 20),
            SectionHeader(title: 'Most rented props', onSeeAll: () {}),
            const MostRentedProps(),
            const SizedBox(height: 20),
            const HostSection(),
          ],
        ),
      ),
      showAppBar: true,
    );
  }

  Widget _buildAppBarContent(BuildContext context) {
    return const LocationWidget(
      title: 'Your current location',
      location: 'Lukavac, TK, F.BiH',
    );
  }

  Widget _buildSection({required String title, required List<PropertyCard> properties}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, onSeeAll: () {}),
        CustomSlider(items: properties),
      ],
    );
  }

  List<PropertyCard> _buildPropertyList(int count) {
    return List.generate(
      count,
      (index) => const PropertyCard(
        title: 'Small cottage with great view of Bagmati',
        location: 'Lukavac, TK, F.BiH',
        details: '2 rooms   673 m2',
        price: '\$526 / month',
        rating: '4.8 (73)',
        imageUrl: 'assets/images/house.jpg',
      ),
    );
  }
}
