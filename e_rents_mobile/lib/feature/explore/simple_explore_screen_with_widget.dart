import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/services/secure_storage_service.dart';

/// Simple property service for direct API calls without complex Provider patterns
class SimplePropertyService {
  final ApiService _apiService;
  
  SimplePropertyService(this._apiService);
  
  Future<List<Property>> searchProperties({String? cityName}) async {
    final endpoint = cityName != null && cityName.isNotEmpty
        ? 'properties/search?query=$cityName'
        : 'properties/search';
        
    final response = await _apiService.get(endpoint);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'] ?? data;
      return items.map((item) => Property.fromJson(item)).toList();
    } else {
      throw Exception('Failed to load properties');
    }
  }
}

/// Simplified explore screen using StatefulWidget instead of Provider pattern
/// This replaces the complex ExploreProvider (538 lines) with direct service usage
/// Demonstrates the simplified architecture: StatefulWidget -> Service -> API
class SimpleExploreScreenWidget extends StatefulWidget {
  const SimpleExploreScreenWidget({super.key});

  @override
  State<SimpleExploreScreenWidget> createState() => _SimpleExploreScreenWidgetState();
}

class _SimpleExploreScreenWidgetState extends State<SimpleExploreScreenWidget> {
  late final SimplePropertyService _propertyService;
  
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize API service with required dependencies
    final apiService = ApiService(
      'https://api.example.com', // Base URL - should be from config
      SecureStorageService(),
    );
    _propertyService = SimplePropertyService(apiService);
    _loadProperties();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final properties = await _propertyService.searchProperties();
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load properties: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchProperties(String query) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _searchQuery = query;
    });

    try {
      final properties = await _propertyService.searchProperties(
        cityName: query.isNotEmpty ? query : null,
      );
      setState(() {
        _properties = properties;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Search failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Properties'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by city...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _searchProperties('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onSubmitted: _searchProperties,
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadProperties,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.home_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty 
                  ? 'No properties available'
                  : 'No properties found for "$_searchQuery"',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProperties,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _properties.length,
        itemBuilder: (context, index) {
          final property = _properties[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PropertyCard(
              property: property,
              onTap: () {
                // Navigate to property details
                Navigator.pushNamed(
                  context,
                  '/property-details',
                  arguments: property.propertyId,
                );
              },
            ),
          );
        },
      ),
    );
  }
}