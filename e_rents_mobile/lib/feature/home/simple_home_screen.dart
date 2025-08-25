import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/models/booking_model.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:provider/provider.dart';

/// Simplified home dashboard screen using StatefulWidget
/// Replaces the 173-line HomeProvider with direct, simple approach
class SimpleHomeScreen extends StatefulWidget {
  const SimpleHomeScreen({super.key});

  @override
  State<SimpleHomeScreen> createState() => _SimpleHomeScreenState();
}

class _SimpleHomeScreenState extends State<SimpleHomeScreen> {
  List<Booking> _currentBookings = [];
  List<Property> _featuredProperties = [];
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      
      // Load current bookings and featured properties in parallel
      final results = await Future.wait([
        _loadCurrentBookings(apiService),
        _loadFeaturedProperties(apiService),
      ]);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load dashboard: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCurrentBookings(ApiService apiService) async {
    try {
      final response = await apiService.get('bookings/current');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        _currentBookings = data.map((item) => Booking.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load bookings: $e');
    }
  }

  Future<void> _loadFeaturedProperties(ApiService apiService) async {
    try {
      final response = await apiService.get('properties/featured');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? data;
        _featuredProperties = items.map((item) => Property.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load featured properties: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadDashboardData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            const SizedBox(height: 24),
            _buildCurrentBookingsSection(),
            const SizedBox(height: 24),
            _buildFeaturedPropertiesSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Find your perfect rental property',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentBookingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Current Stays',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_currentBookings.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No current bookings'),
            ),
          )
        else
          ...(_currentBookings.map((booking) => Card(
            child: ListTile(
              title: Text(booking.propertyName ?? 'Property'),
              subtitle: Text('Check-out: ${booking.endDate?.toString().split(' ')[0]}'),
              trailing: const Icon(Icons.home),
            ),
          ))),
      ],
    );
  }

  Widget _buildFeaturedPropertiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Featured Properties',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        if (_featuredProperties.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No featured properties available'),
            ),
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _featuredProperties.length,
              itemBuilder: (context, index) {
                final property = _featuredProperties[index];
                return Card(
                  margin: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: 150,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                            ),
                            child: const Center(
                              child: Icon(Icons.home, size: 40),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                property.name ?? 'Property',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text('${property.price} BAM'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}