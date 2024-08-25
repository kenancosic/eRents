import 'package:e_rents_mobile/core/widgets/host_section.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/feature/home/home_provider.dart';
import 'package:e_rents_mobile/feature/home/widgets/filter_dialog.dart';
import 'package:e_rents_mobile/feature/home/widgets/most_rented_props.dart';
import 'package:e_rents_mobile/feature/home/widgets/property_card.dart';
import 'package:e_rents_mobile/feature/home/widgets/sort_dialog.dart';
import 'package:e_rents_mobile/feature/home/widgets/welcome_section.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

// class HomeScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('eRents Home'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.filter_list),
//             onPressed: () => _showFilterDialog(context),
//           ),
//           IconButton(
//             icon: Icon(Icons.sort),
//             onPressed: () => _showSortDialog(context),
//           ),
//         ],
//       ),
//       body: Consumer<HomeProvider>(
//         builder: (context, homeProvider, child) {
//           if (homeProvider.isLoading) {
//             return Center(child: CircularProgressIndicator());
//           }

//           if (homeProvider.properties.isEmpty) {
//             return Center(child: Text('No properties available.'));
//           }

//           return ListView.builder(
//             itemCount: homeProvider.properties.length,
//             itemBuilder: (context, index) {
//               final property = homeProvider.properties[index];
//               return PropertyCard(property: property);
//             },
//           );
//         },
//       ),
//     );
//   }

//   void _showFilterDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return FilterDialog();
//       },
//     );
//   }

//   void _showSortDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return SortDialog();
//       },
//     );
//   }
// }


import 'package:e_rents_mobile/core/widgets/bottom_navigation_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Your current locations',
                style: Theme.of(context).textTheme.bodySmall),
            const Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.purple),
                Text(
                  'Lukavac, T.K., F.BiH',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Icon(Icons.arrow_drop_down),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Handle search action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SearchBar(),
              const SizedBox(height: 20),
              const WelcomeSection(),
              const SizedBox(height: 20),
              SectionHeader(title: 'Near your location', onSeeAll: () {}),
              const PropertyCard(
                  title: 'Small cottage with great view of bagmati',
                  location: 'Lukavac, TK, F.BiH',
                  details: '2 room   673 m2',
                  price: '\$526 / month',
                  rating: '4.8 (73)',
                  imageUrl: 'https://via.placeholder.com/150'), // Replace with actual image URL
              const SizedBox(height: 20),
              SectionHeader(title: 'Top rated', onSeeAll: () {}),
              const PropertyCard(
                  title: 'Entire private villa in Surabaya City',
                  location: 'Tuzla, T.K., F.BiH',
                  details: '2 room   488 m2',
                  price: '\$400 / month',
                  rating: '4.9 (104)',
                  imageUrl: 'https://via.placeholder.com/150'), // Replace with actual image URL
              const SizedBox(height: 20),
              SectionHeader(title: 'Most rented props', onSeeAll: () {}),
              const MostRentedProps(),
              const SizedBox(height: 20),
              const HostSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go('/'); // Navigate to Home
              break;
            case 1:
              context.go('/explore'); // Navigate to Explore
              break;
            case 2:
              context.go('/chat'); // Navigate to Chat
              break;
            case 3:
              context.go('/saved'); // Navigate to Saved
              break;
            case 4:
              context.go('/profile'); // Navigate to Profile
              break;
          }
        },
      ),
    );
  }
}
