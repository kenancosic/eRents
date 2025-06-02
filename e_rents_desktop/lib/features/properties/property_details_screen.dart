import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_header.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_images_grid.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_overview_section.dart';
import 'package:e_rents_desktop/features/properties/widgets/tenant_info.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_reviews_section.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_financial_summary.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_bookings_section.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_collection_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_details_provider.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:intl/intl.dart'; // Ensure DateFormat is imported
import 'package:e_rents_desktop/base/base_provider.dart'; // Added for ViewState

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  Property? _property;
  // bool _isLoading = true; // Managed by PropertyDetailsProvider now
  // String? _error; // Managed by PropertyDetailsProvider now

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchPropertyDetails();
    });
  }

  Future<void> _fetchPropertyDetails() async {
    if (!mounted) return;
    // setState(() { // Managed by provider
    //   _isLoading = true;
    //   _error = null;
    // });

    final detailsProvider = context.read<PropertyDetailsProvider>();
    // detailsProvider.setLoading(true); // Use provider's loading state - replaced by setLoadingState
    detailsProvider.setLoadingState(true);

    try {
      print(
        'PropertyDetailsScreen: Fetching details for property ID: ${widget.propertyId}',
      );

      final propertyCollectionProvider =
          context.read<PropertyCollectionProvider>();

      final propertyIdInt = int.tryParse(widget.propertyId);
      if (propertyIdInt == null) {
        throw Exception('Invalid property ID format: ${widget.propertyId}');
      }

      // Get property using the new provider architecture
      _property = await propertyCollectionProvider.getPropertyById(
        propertyIdInt,
      );

      print(
        'PropertyDetailsScreen: Found property from collection provider: ${_property?.title ?? 'null'}',
      );

      if (_property == null) {
        detailsProvider.setLoadingState(
          false,
          'Property with ID ${widget.propertyId} not found.',
        );
        print(
          'PropertyDetailsScreen: Error - Property with ID ${widget.propertyId} not found after getItemById.',
        );
        // No need for setState here as provider notifies
        return;
      }

      if (mounted) {
        setState(() {}); // Update local _property
      }

      await detailsProvider.loadPropertyDetails(propertyIdInt.toString());
      // detailsProvider.setLoading(false); // loadPropertyDetails should handle its own final state
    } catch (e) {
      print('PropertyDetailsScreen: Exception - ${e.toString()}');
      final detailsProvider =
          context.read<PropertyDetailsProvider>(); // ensure it's in scope
      detailsProvider.setLoadingState(
        false,
        "Failed to fetch property details: ${e.toString()}",
      );
      // No need for setState here as provider notifies
    }
    // finally { // Managed by provider
    //   if (mounted) {
    //     setState(() {
    //       _isLoading = false;
    //     });
    //   }
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PropertyDetailsProvider>(
      builder: (context, detailsProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_property?.title ?? 'Property Details'),
            elevation: 1,
            actions: [
              if (_property != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Property',
                  onPressed:
                      () => _navigateToEditScreen(context, _property!.id),
                ),
            ],
          ),
          body: LoadingOrErrorWidget(
            isLoading:
                detailsProvider.isLoadingDetails ||
                (_property == null && detailsProvider.errorMessage == null),
            error: detailsProvider.detailsError ?? detailsProvider.errorMessage,
            onRetry: _fetchPropertyDetails,
            errorTitle: 'Failed to Load Property',
            child:
                _property == null
                    ? const Center(
                      child: Text('Property data is not available.'),
                    )
                    : _buildPropertyContent(
                      context,
                      detailsProvider,
                      _property!,
                    ),
          ),
        );
      },
    );
  }

  Widget _buildPropertyContent(
    BuildContext context,
    PropertyDetailsProvider detailsProvider,
    Property property,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen =
            constraints.maxWidth > 800; // Define breakpoint

        if (isWideScreen) {
          return _buildTwoColumnLayout(context, detailsProvider, property);
        } else {
          return _buildSingleColumnLayout(context, detailsProvider, property);
        }
      },
    );
  }

  Widget _buildSingleColumnLayout(
    BuildContext context,
    PropertyDetailsProvider detailsProvider,
    Property property,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16), // Consistent padding
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyHeader(property: property),
          const SizedBox(height: 16),
          PropertyImagesGrid(images: property.images),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Overview',
            child: PropertyOverviewSection(
              property: property,
              onEdit: () => _navigateToEditScreen(context, property.id),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Current Tenant',
            child: TenantInfo(
              property: property,
              currentTenant: detailsProvider.currentTenant,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Property Statistics',
            child: _PropertyStatsCard(detailsProvider: detailsProvider),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Financial Summary',
            child: PropertyFinancialSummary(
              bookingStats: detailsProvider.bookingStats,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Bookings',
            child: PropertyBookingsSection(
              currentBookings: detailsProvider.currentBookings,
              upcomingBookings: detailsProvider.upcomingBookings,
              recentBookings: detailsProvider.recentBookings,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Reviews',
            child: PropertyReviewsSection(
              reviewStats: detailsProvider.reviewStats,
              reviews: detailsProvider.reviews,
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Maintenance',
            child: _MaintenanceCard(
              property: property,
              issues: detailsProvider.fetchedMaintenanceIssues,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnLayout(
    BuildContext context,
    PropertyDetailsProvider detailsProvider,
    Property property,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            flex: 3, // Give more space to primary info
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PropertyHeader(property: property),
                const SizedBox(height: 24),
                PropertyImagesGrid(images: property.images),
                const SizedBox(height: 24),
                _buildSectionCard(
                  title: 'Overview',
                  child: PropertyOverviewSection(
                    property: property,
                    onEdit: () => _navigateToEditScreen(context, property.id),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Bookings',
                  child: PropertyBookingsSection(
                    currentBookings: detailsProvider.currentBookings,
                    upcomingBookings: detailsProvider.upcomingBookings,
                    recentBookings: detailsProvider.recentBookings,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Financial Summary',
                  child: PropertyFinancialSummary(
                    bookingStats: detailsProvider.bookingStats,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24), // Spacing between columns
          // Right Column
          Expanded(
            flex: 2, // Less space for secondary info
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Current Tenant',
                  child: TenantInfo(
                    property: property,
                    currentTenant: detailsProvider.currentTenant,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Property Statistics',
                  child: _PropertyStatsCard(detailsProvider: detailsProvider),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Reviews',
                  child: PropertyReviewsSection(
                    reviewStats: detailsProvider.reviewStats,
                    reviews: detailsProvider.reviews,
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Maintenance',
                  child: _MaintenanceCard(
                    property: property,
                    issues: detailsProvider.fetchedMaintenanceIssues,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper to wrap sections in a styled Card
  Widget _buildSectionCard({
    required String title,
    required Widget child,
    IconData? icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const Divider(height: 24, thickness: 1),
            child,
          ],
        ),
      ),
    );
  }

  // Extracted widgets for stats and maintenance for clarity
  Widget _buildRealStatistics(PropertyDetailsProvider detailsProvider) {
    // This is now _PropertyStatsCard
    return _PropertyStatsCard(detailsProvider: detailsProvider);
  }

  Widget _buildStatistic(String label, String value, {IconData? icon}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        if (icon != null) const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildMaintenanceIssues(
    BuildContext context,
    Property property,
    List<MaintenanceIssue> issues,
  ) {
    // This is now _MaintenanceCard
    return _MaintenanceCard(property: property, issues: issues);
  }

  void _navigateToEditScreen(BuildContext context, int propertyId) {
    context.push('/properties/${propertyId.toString()}/edit');
  }
}

// New private widget for Property Statistics - THIS MUST BE TOP-LEVEL
class _PropertyStatsCard extends StatelessWidget {
  final PropertyDetailsProvider detailsProvider;
  const _PropertyStatsCard({required this.detailsProvider});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatisticItem(
              context,
              'Bookings',
              '${detailsProvider.totalBookings}',
              icon: Icons.event_note_outlined,
            ),
            _buildStatisticItem(
              context,
              'Rating',
              detailsProvider.averageRating > 0
                  ? '${detailsProvider.averageRating.toStringAsFixed(1)}★'
                  : 'N/A',
              icon: Icons.star_border_outlined,
            ),
            _buildStatisticItem(
              context,
              'Occupancy',
              '${(detailsProvider.occupancyRate * 100).toStringAsFixed(0)}%',
              icon: Icons.pie_chart_outline_outlined,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatisticItem(
    BuildContext context,
    String label,
    String value, {
    IconData? icon,
  }) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
          if (icon != null) const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// New private widget for Maintenance Issues - THIS MUST BE TOP-LEVEL
class _MaintenanceCard extends StatelessWidget {
  final Property property;
  final List<MaintenanceIssue> issues;

  const _MaintenanceCard({required this.property, required this.issues});

  String _formatTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: () {
                context.push(
                  '/maintenance/new?propertyId=${property.id.toString()}',
                );
              },
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('New Issue'),
            ),
            TextButton.icon(
              onPressed: () {
                context.push(
                  '/maintenance?propertyId=${property.id.toString()}',
                );
              },
              icon: const Icon(Icons.list_alt_outlined, size: 18),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (issues.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.build_circle_outlined,
                    size: 48,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 8),
                  Text('No maintenance issues reported.'),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: issues.length > 3 ? 3 : issues.length,
            separatorBuilder:
                (context, index) =>
                    const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (context, index) {
              final issue = issues[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: issue.priorityColor.withOpacity(0.15),
                  child: Icon(
                    Icons.error_outline,
                    color: issue.priorityColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  issue.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  'Reported ${_formatTimeAgo(issue.createdAt)} • Status: ${issue.status.displayName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: issue.statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    issue.status.displayName,
                    style: TextStyle(
                      color: issue.statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                onTap: () {
                  context.push('/maintenance/${issue.id}');
                },
              );
            },
          ),
        if (issues.length > 3)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: TextButton(
              onPressed: () {
                context.push(
                  '/maintenance?propertyId=${property.id.toString()}',
                );
              },
              child: Text('View All ${issues.length} Issues'),
            ),
          ),
      ],
    );
  }
}

// Add extension for IssueStatus display name - THIS MUST BE TOP-LEVEL
extension IssueStatusExtension on IssueStatus {
  String get displayName {
    switch (this) {
      case IssueStatus.pending:
        return 'Pending';
      case IssueStatus.inProgress:
        return 'In Progress';
      case IssueStatus.completed:
        return 'Completed';
      case IssueStatus.cancelled:
        return 'Cancelled';
      default:
        final name = toString().split('.').last;
        return name[0].toUpperCase() + name.substring(1);
    }
  }
}
