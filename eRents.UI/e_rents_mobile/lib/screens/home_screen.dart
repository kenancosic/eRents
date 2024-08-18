import 'package:flutter/material.dart';
import 'package:e_rents_mobile/models/user.dart';

class HomeScreen extends StatefulWidget {
  final User user;

  const HomeScreen({Key? key, required this.user}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Example state variables for dynamic content
  List<String> _properties = [];
  List<String> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // Simulate fetching data for properties and notifications
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _properties = ['Property 1', 'Property 2', 'Property 3'];
      _notifications = ['Booking confirmed', 'Payment received'];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome to eRents, ${widget.user.username}!',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Your Properties'),
                    _buildPropertyOverview(context),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Recent Notifications'),
                    _buildNotificationOverview(context),
                    const SizedBox(height: 20),
                    _buildSectionTitle('Top Rated Properties'),
                    _buildFeaturedProperties(context),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildPropertyOverview(BuildContext context) {
    return Column(
      children: [
        for (var property in _properties)
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(property),
            subtitle: const Text('2 rooms, €500/month'),
            onTap: () {
              // Navigate to property details
            },
          ),
        ElevatedButton(
          onPressed: () {
            // Navigate to Property List Screen
          },
          child: const Text('View All Properties'),
        ),
      ],
    );
  }

  Widget _buildNotificationOverview(BuildContext context) {
    return Column(
      children: [
        for (var notification in _notifications)
          ListTile(
            leading: const Icon(Icons.notifications),
            title: Text(notification),
            subtitle: const Text('Tap for more details'),
            onTap: () {
              // Navigate to notification details
            },
          ),
        ElevatedButton(
          onPressed: () {
            // Navigate to Notifications Screen
          },
          child: const Text('View All Notifications'),
        ),
      ],
    );
  }

  Widget _buildFeaturedProperties(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: Image.network('https://via.placeholder.com/100'),
          title: const Text('Luxury Villa'),
          subtitle: const Text('4.9 stars | €2000/month'),
          onTap: () {
            // Navigate to property details
          },
        ),
        ListTile(
          leading: Image.network('https://via.placeholder.com/100'),
          title: const Text('Modern Apartment'),
          subtitle: const Text('4.8 stars | €1200/month'),
          onTap: () {
            // Navigate to property details
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'Explore',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bookmark),
          label: 'Saved',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        // Handle navigation
      },
    );
  }
}
