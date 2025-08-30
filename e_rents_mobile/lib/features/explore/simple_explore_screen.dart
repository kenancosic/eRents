import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/property.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:provider/provider.dart';

/// Simplified property exploration screen using StatefulWidget
/// Replaces the 538-line ExploreProvider with simple, direct approach
class SimpleExploreScreen extends StatefulWidget {
  const SimpleExploreScreen({super.key});

  @override
  State<SimpleExploreScreen> createState() => _SimpleExploreScreenState();
}

class _SimpleExploreScreenState extends State<SimpleExploreScreen> {
  List<Property> _properties = [];
  bool _isLoading = false;
  String? _error;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties({String? searchQuery}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final apiService = context.read<ApiService>();
      final response = await apiService.get(
        searchQuery != null 
          ? 'properties/search?query=$searchQuery'
          : 'properties/search',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> items = data['items'] ?? data;
        
        setState(() {
          _properties = items.map((item) => Property.fromJson(item)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load properties');
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load properties: $e';
        _isLoading = false;
      });
    }
  }

  void _searchProperties() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _loadProperties(searchQuery: query);
    } else {
      _loadProperties();
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
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search by city...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchProperties(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searchProperties,
                  child: const Text('Search'),
                ),
              ],
            ),
          ),
        ),
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
              onPressed: () => _loadProperties(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_properties.isEmpty) {
      return const Center(
        child: Text('No properties found'),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadProperties(),
      child: ListView.builder(
        itemCount: _properties.length,
        itemBuilder: (context, index) {
          final property = _properties[index];
          return Card(
            margin: const EdgeInsets.all(8),
            child: ListTile(
              title: Text(property.name ?? 'Unnamed Property'),
              subtitle: Text(property.description ?? 'No description'),
              trailing: property.price != null 
                ? Text('${property.price} BAM')
                : null,
              onTap: () {
                // Navigate to property details
                // Navigator.push(context, ...);
              },
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}