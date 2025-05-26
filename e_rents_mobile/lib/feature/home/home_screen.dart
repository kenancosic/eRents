import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/widgets/custom_search_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_slider.dart';
import 'package:e_rents_mobile/core/widgets/location_widget.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/address_detail.dart';
import 'package:e_rents_mobile/core/models/geo_region.dart';
import 'package:e_rents_mobile/core/models/image_response.dart';
import 'package:e_rents_mobile/feature/home/widgets/upcoming_stays_section.dart';
import 'package:e_rents_mobile/feature/home/widgets/currently_residing_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:typed_data';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Property _createMockProperty(
      int id, String name, PropertyRentalType rentalType,
      {double? dailyRate}) {
    return Property(
      propertyId: id,
      ownerId: 1,
      name: name,
      price:
          rentalType == PropertyRentalType.daily ? (dailyRate ?? 75.0) : 526.0,
      dailyRate:
          rentalType == PropertyRentalType.daily ? (dailyRate ?? 75.0) : null,
      description: 'A beautiful property with great amenities',
      averageRating: 4.8,
      images: [
        ImageResponse(
          imageId: id,
          fileName: id.isEven
              ? 'assets/images/house.jpg'
              : 'assets/images/appartment.jpg',
          imageData: ByteData(0),
          dateUploaded: DateTime.now(),
        ),
      ],
      addressDetail: AddressDetail(
        addressDetailId: id,
        geoRegionId: id,
        streetLine1: id == 1
            ? 'Lukavac Street'
            : id == 300
                ? 'Downtown Street'
                : 'Paradise Beach Road',
        geoRegion: GeoRegion(
          geoRegionId: id,
          city: id == 1
              ? 'Lukavac'
              : id == 300
                  ? 'Downtown'
                  : 'Paradise City',
          country: 'USA',
          state: id == 1
              ? 'BiH'
              : id == 300
                  ? 'NY'
                  : 'FL',
        ),
      ),
      facilities: "Wi-Fi, Kitchen, Air Conditioning",
      status: "Available",
      dateAdded: DateTime.now().subtract(Duration(days: id * 10)),
      rentalType: rentalType,
      minimumStayDays: rentalType == PropertyRentalType.monthly ? 30 : 3,
    );
  }

  List<Widget> _buildPropertyCards(BuildContext context, int count) {
    return List.generate(
      count,
      (index) => PropertyCard(
        property: _createMockProperty(
            1 + index,
            'Small cottage with great view of Bagmati',
            PropertyRentalType.monthly),
        onTap: () {
          context.push('/property/1');
        },
      ),
    );
  }

  List<Widget> _buildMixedPropertyCards(BuildContext context) {
    return [
      // Daily rental property
      PropertyCard(
        property: _createMockProperty(
          1,
          'Cozy Cottage - Daily Rental',
          PropertyRentalType.daily,
          dailyRate: 75.0,
        ),
        onTap: () {
          context.push('/property/1');
        },
      ),
      // Monthly lease property
      PropertyCard(
        property: _createMockProperty(
          300,
          'Modern Downtown Apartment - Monthly Lease',
          PropertyRentalType.monthly,
        ),
        onTap: () {
          context.push('/property/300');
        },
      ),
      // Another daily rental
      PropertyCard(
        property: _createMockProperty(
          102,
          'Beachside Villa Getaway',
          PropertyRentalType.daily,
          dailyRate: 120.0,
        ),
        onTap: () {
          context.push('/property/102');
        },
      ),
    ];
  }

  void _handleApplyFilters(BuildContext context, Map<String, dynamic> filters) {
    // TODO: Implement actual filter logic (e.g., update provider, refetch data)
    // You might want to show a snackbar or some feedback
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters applied!')),
    );
  }

  Widget _buildRecommendedSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Recommended for you',
          onSeeAll: () {
            context.push('/explore');
          },
        ),
        // Use vertical cards for recommended section for variety
        SizedBox(
          height: 240, // Fixed height for vertical cards
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 3,
            itemBuilder: (context, index) {
              final property = _createMockProperty(
                104 + index,
                'Recommended Property ${index + 1}',
                PropertyRentalType.both,
                dailyRate: 85.0 + (index * 10),
              );
              return SizedBox(
                width: 180, // Fixed width for vertical cards
                child: PropertyCard.vertical(
                  property: property,
                  onTap: () {
                    context.push('/property/${property.propertyId}');
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final properties = _buildPropertyCards(context, 3);
    final mixedProperties = _buildMixedPropertyCards(context);

    final searchBar = CustomSearchBar(
      hintText: 'Search properties...',
      onSearchChanged: (query) {
        // Handle search query
      },
      showFilterIcon: true,
      onFilterIconPressed: () {
        context.push('/filter', extra: {
          'onApplyFilters': (Map<String, dynamic> filters) =>
              _handleApplyFilters(context, filters),
        });
      },
    );

    final locationWidgetForAppBar =
        const LocationWidget(title: 'Welcome back, User', location: 'Lukavac');

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
      showBackButton: false,
      userLocationWidget: locationWidgetForAppBar,
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
              const SizedBox(height: 20),

              // Currently Residing Section
              const CurrentlyResidingSection(),
              const SizedBox(height: 20),

              // Upcoming Stays Section
              const UpcomingStaysSection(),
              const SizedBox(height: 20),

              SectionHeader(title: 'Near your location', onSeeAll: () {}),
              CustomSlider(items: properties),
              const SizedBox(height: 20),
              SectionHeader(
                  title: 'Featured Properties (Daily & Monthly)',
                  onSeeAll: () {}),
              CustomSlider(items: mixedProperties),
              const SizedBox(height: 20),

              _buildRecommendedSection(context),
            ],
          ),
        ),
      ),
    );
  }
}
