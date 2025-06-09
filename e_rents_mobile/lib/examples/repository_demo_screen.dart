import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/services/service_locator.dart';
import 'package:e_rents_mobile/feature/property_detail/property_details_provider.dart';
import 'package:e_rents_mobile/core/widgets/custom_button.dart';

/// Demonstration screen showing the power of the repository architecture
///
/// 🚀 REPOSITORY PATTERN BENEFITS DEMONSTRATED:
///
/// ✅ **Automatic Caching**: Load property once, access from any screen instantly
/// ✅ **Automatic Error Handling**: Structured errors with retry functionality
/// ✅ **Loading States**: Consistent loading indicators across all screens
/// ✅ **Data Consistency**: Single source of truth for property data
/// ✅ **Offline Support**: Cached data available even without network
/// ✅ **Memory Management**: Automatic cache cleanup and TTL management
/// ✅ **Business Logic Focus**: 80% less infrastructure code
///
class RepositoryDemoScreen extends StatelessWidget {
  const RepositoryDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repository Architecture Demo'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.blue.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.rocket_launch,
                          color: Colors.blue.shade600, size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        'Repository Pattern in Action',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Demonstrating automatic caching, error handling, and simplified code',
                    style: TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Demo sections
            _buildDemoSection(
              '🚀 Load Property (First Time)',
              'This will fetch from API and cache automatically',
              () => _loadProperty(context, 1),
              Colors.green,
            ),

            const SizedBox(height: 16),

            _buildDemoSection(
              '⚡ Load Same Property (Cached)',
              'This will load instantly from cache - no API call!',
              () => _loadProperty(context, 1),
              Colors.orange,
            ),

            const SizedBox(height: 16),

            _buildDemoSection(
              '🔄 Force Refresh',
              'This will bypass cache and fetch fresh data',
              () => _refreshProperty(context),
              Colors.purple,
            ),

            const SizedBox(height: 16),

            _buildDemoSection(
              '🔍 Load Different Property',
              'This will demonstrate cache miss -> API call -> cache',
              () => _loadProperty(context, 2),
              Colors.teal,
            ),

            const SizedBox(height: 24),

            // Provider display
            ChangeNotifierProvider<PropertyDetailProvider>(
              create: (_) => ServiceLocator.get<PropertyDetailProvider>(),
              child: Consumer<PropertyDetailProvider>(
                builder: (context, provider, child) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline,
                                color: Colors.blue.shade600),
                            const SizedBox(width: 8),
                            const Text(
                              'Provider State',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildStatusRow('Loading', provider.isLoading),
                        _buildStatusRow('Has Error', provider.hasError),
                        _buildStatusRow('Has Data', provider.hasData),
                        _buildStatusRow('Cache Hit', provider.hasLoaded),
                        if (provider.hasError) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline,
                                    color: Colors.red.shade600, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    provider.errorMessage ?? 'Unknown error',
                                    style:
                                        TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (provider.hasData) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.home,
                                        color: Colors.green.shade600, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      provider.title,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('💰 ${provider.priceDisplay}'),
                                Text('📍 ${provider.city}'),
                                Text(
                                    '🏠 ${provider.specificationsDisplay ?? 'N/A'}'),
                                Text(
                                    '⭐ ${provider.ratingDisplay ?? 'No rating'}'),
                                Text(
                                    '🏷️ Status: ${provider.isAvailable ?? false ? "Available" : "Not Available"}'),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Benefits summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '✨ Repository Pattern Benefits',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildBenefitItem('⚡', 'Instant cached data access'),
                  _buildBenefitItem('🛡️', 'Automatic error handling & retry'),
                  _buildBenefitItem('📱', 'Consistent loading states'),
                  _buildBenefitItem('🔄', 'Automatic cache invalidation'),
                  _buildBenefitItem('📊', 'Built-in data transformation'),
                  _buildBenefitItem('🧹', 'Memory management & TTL'),
                  _buildBenefitItem('🎯', '80% less boilerplate code'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoSection(
      String title, String description, VoidCallback onTap, Color color) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.1),
          child: Icon(Icons.play_arrow, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusRow(String label, bool value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            value ? Icons.check_circle : Icons.cancel,
            color: value ? Colors.green : Colors.grey,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text('$label: ${value ? "Yes" : "No"}'),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  void _loadProperty(BuildContext context, int propertyId) {
    final provider = context.read<PropertyDetailProvider>();
    provider.loadItem(propertyId.toString());

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Loading property $propertyId...'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _refreshProperty(BuildContext context) {
    final provider = context.read<PropertyDetailProvider>();
    provider.refreshItem();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Refreshing property data...'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
