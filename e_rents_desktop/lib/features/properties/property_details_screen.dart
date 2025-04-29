import 'package:flutter/material.dart';
import 'package:e_rents_desktop/base/app_base_screen.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_header.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_images_grid.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_overview_section.dart';
import 'package:e_rents_desktop/features/properties/widgets/tenant_info.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_provider.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  Property? _property;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPropertyDetails();
  }

  Future<void> _fetchPropertyDetails() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<PropertyProvider>();
      if (provider.properties.isEmpty) {
        await provider.fetchProperties();
      }
      _property = provider.getPropertyById(widget.propertyId);

      if (_property == null) {
        _error = 'Property with ID ${widget.propertyId} not found.';
      }
    } catch (e) {
      _error = "Failed to fetch property details: ${e.toString()}";
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBaseScreen(
      title:
          _isLoading
              ? 'Loading Property...'
              : (_error != null
                  ? 'Error'
                  : (_property?.title ?? 'Property Details')),
      currentPath: '/properties',
      child: LoadingOrErrorWidget(
        isLoading: _isLoading,
        error: _error,
        onRetry: _fetchPropertyDetails,
        errorTitle: 'Failed to Load Property',
        child:
            _property == null
                ? const Center(child: Text('Property data is not available.'))
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildBackButton(context),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                PropertyHeader(property: _property!),
                                const SizedBox(height: 16),
                                PropertyImagesGrid(images: _property!.images),
                                const SizedBox(height: 16),
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: PropertyOverviewSection(
                                      property: _property!,
                                      onEdit:
                                          () => _navigateToEditScreen(
                                            context,
                                            _property!.id,
                                          ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                Card(
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: TenantInfo(property: _property!),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildCompactStatistics(),
                                const SizedBox(height: 16),
                                _buildMaintenanceIssues(context, _property!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  Widget _buildBackButton(BuildContext context) {
    final router = GoRouter.of(context);
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (router.canPop()) {
              router.pop();
            } else {
              // Fallback navigation if cannot pop
              router.go('/properties');
            }
          },
          tooltip: 'Go back',
        ),
      ],
    );
  }

  Widget _buildCompactStatistics() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Stats',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Show detailed statistics
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatistic('Tenants', '15'),
                _buildStatistic('Avg. Stay', '12m'),
                _buildStatistic('Vacancy', '20%'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistic(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMaintenanceIssues(BuildContext context, Property property) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Maintenance Issues',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        context.push(
                          '/maintenance/new?propertyId=${property.id}',
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Issue'),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        context.go('/maintenance?propertyId=${property.id}');
                      },
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('View All'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          if (property.maintenanceIssues.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No maintenance issues found')),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: property.maintenanceIssues.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final issue = property.maintenanceIssues[index];
                return ListTile(
                  leading: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: issue.priorityColor,
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          issue.title,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: issue.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          issue.status.toString().split('.').last,
                          style: TextStyle(
                            color: issue.statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    '${issue.description}\nReported ${_formatTimeAgo(issue.createdAt)}',
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 16),
                    onPressed: () {
                      context.go('/maintenance/${issue.id}');
                    },
                  ),
                  isThreeLine: true,
                  dense: true,
                  onTap: () {
                    context.go('/maintenance/${issue.id}');
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inMinutes} minutes ago';
    }
  }

  void _navigateToEditScreen(BuildContext context, String propertyId) {
    context.push('/properties/${propertyId}/edit');
  }
}
