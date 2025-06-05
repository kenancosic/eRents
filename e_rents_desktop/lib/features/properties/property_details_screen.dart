import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:e_rents_desktop/features/properties/providers/property_detail_provider.dart';
import 'package:e_rents_desktop/features/properties/providers/property_stats_provider.dart';
import 'package:e_rents_desktop/widgets/loading_or_error_widget.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/maintenance_issue.dart';
import 'package:e_rents_desktop/models/booking_summary.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_header.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_images_grid.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_overview_section.dart';
import 'package:e_rents_desktop/features/properties/widgets/tenant_info.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_reviews_section.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_financial_summary.dart';
import 'package:e_rents_desktop/features/properties/widgets/property_bookings_section.dart';

class PropertyDetailsScreen extends StatefulWidget {
  final String propertyId;

  const PropertyDetailsScreen({super.key, required this.propertyId});

  @override
  State<PropertyDetailsScreen> createState() => _PropertyDetailsScreenState();
}

class _PropertyDetailsScreenState extends State<PropertyDetailsScreen> {
  @override
  void initState() {
    super.initState();
  }

  void _navigateToEditScreen(BuildContext context, int propertyId) {
    context.push('/properties/${propertyId.toString()}/edit');
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<PropertyDetailProvider, PropertyStatsProvider>(
      builder: (context, detailProvider, statsProvider, child) {
        final property = detailProvider.property;
        final stats = statsProvider.stats;

        return Scaffold(
          appBar: AppBar(
            title: Text(property?.title ?? 'Property Details'),
            elevation: 1,
            actions: [
              if (property != null)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Property',
                  onPressed: () => _navigateToEditScreen(context, property.id),
                ),
            ],
          ),
          body: LoadingOrErrorWidget(
            isLoading: detailProvider.isLoading,
            error: detailProvider.error?.message,
            onRetry: () {
              detailProvider.loadPropertyById(int.parse(widget.propertyId));
              statsProvider.loadPropertyStats(widget.propertyId);
            },
            errorTitle: 'Failed to Load Property',
            child:
                property == null
                    ? const Center(
                      child: Text('Property data is not available.'),
                    )
                    : _buildPropertyContent(context, property, stats),
          ),
        );
      },
    );
  }

  Widget _buildPropertyContent(
    BuildContext context,
    Property property,
    PropertyStatsData? stats,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isWideScreen = constraints.maxWidth > 800;

        if (isWideScreen) {
          return _buildTwoColumnLayout(context, property, stats);
        } else {
          return _buildSingleColumnLayout(context, property, stats);
        }
      },
    );
  }

  Widget _buildSingleColumnLayout(
    BuildContext context,
    Property property,
    PropertyStatsData? stats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PropertyHeader(property: property),
          const SizedBox(height: 16),
          PropertyImagesGrid(images: property.imageIds),
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
              currentTenant: _getCurrentTenant(stats),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Property Statistics',
            child: _PropertyStatsCard(stats: stats),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Financial Summary',
            child: PropertyFinancialSummary(bookingStats: stats?.bookingStats),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Bookings',
            child: PropertyBookingsSection(
              currentBookings: _getBookingsByStatus('active', stats),
              upcomingBookings: _getBookingsByStatus('upcoming', stats),
              recentBookings: _getBookingsByStatus('completed', stats),
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Reviews',
            child: PropertyReviewsSection(
              reviewStats: stats?.reviewStats,
              reviews:
                  [], // Empty for now - can be enhanced to convert Map to Review objects
            ),
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Maintenance',
            child: _MaintenanceCard(
              property: property,
              issues: stats?.maintenanceIssues ?? [],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTwoColumnLayout(
    BuildContext context,
    Property property,
    PropertyStatsData? stats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PropertyHeader(property: property),
                const SizedBox(height: 24),
                PropertyImagesGrid(images: property.imageIds),
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
                    currentBookings: _getBookingsByStatus('active', stats),
                    upcomingBookings: _getBookingsByStatus('upcoming', stats),
                    recentBookings: _getBookingsByStatus('completed', stats),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Financial Summary',
                  child: PropertyFinancialSummary(
                    bookingStats: stats?.bookingStats,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          // Right Column
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionCard(
                  title: 'Current Tenant',
                  child: TenantInfo(
                    property: property,
                    currentTenant: _getCurrentTenant(stats),
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Property Statistics',
                  child: _PropertyStatsCard(stats: stats),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Reviews',
                  child: PropertyReviewsSection(
                    reviewStats: stats?.reviewStats,
                    reviews:
                        [], // Empty for now - can be enhanced to convert Map to Review objects
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Maintenance',
                  child: _MaintenanceCard(
                    property: property,
                    issues: stats?.maintenanceIssues ?? [],
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

  // Helper methods to extract data from stats
  BookingSummary? _getCurrentTenant(PropertyStatsData? stats) {
    // Get current tenant from current bookings
    return stats?.currentBookings.isNotEmpty == true
        ? stats!.currentBookings.first
        : null;
  }

  List<BookingSummary> _getBookingsByStatus(
    String status,
    PropertyStatsData? stats,
  ) {
    if (stats == null) return [];

    switch (status.toLowerCase()) {
      case 'active':
      case 'current':
        return stats.currentBookings;
      case 'upcoming':
        return stats.upcomingBookings;
      case 'completed':
      case 'recent':
        // For completed bookings, we'd need a separate endpoint
        // For now, return empty as the backend doesn't provide this in the current implementation
        return [];
      default:
        return [];
    }
  }
}

// Property Statistics Card Widget
class _PropertyStatsCard extends StatelessWidget {
  final PropertyStatsData? stats;

  const _PropertyStatsCard({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(child: Text('Statistics not available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatisticItem(
              context,
              'Bookings',
              '${stats!.bookingStats?.totalBookings ?? 0}',
              icon: Icons.event_note_outlined,
            ),
            _buildStatisticItem(
              context,
              'Rating',
              stats!.reviewStats != null &&
                      (stats!.reviewStats!.totalReviews > 0)
                  ? '${stats!.reviewStats!.averageRating.toStringAsFixed(1)}★'
                  : 'N/A',
              icon: Icons.star_border_outlined,
            ),
            _buildStatisticItem(
              context,
              'Occupancy',
              '${((stats!.bookingStats?.occupancyRate ?? 0) * 100).toStringAsFixed(0)}%',
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

// Maintenance Card Widget
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

// Extension for IssueStatus display name
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
