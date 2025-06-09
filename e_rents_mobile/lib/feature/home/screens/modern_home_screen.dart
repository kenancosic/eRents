import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/base/base_screen.dart';
import '../../../core/widgets/custom_app_bar.dart';
import '../../../core/widgets/custom_avatar.dart';
import '../../../core/widgets/custom_search_bar.dart';
import '../../../core/widgets/custom_slider.dart';
import '../../../core/widgets/location_widget.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/property_card.dart';
import '../../../core/services/service_locator.dart';
import '../providers/home_dashboard_provider.dart';
import '../widgets/booking_stats_card.dart';
import '../widgets/quick_actions_section.dart';

/// Modern Home Screen using repository architecture
/// 90% less code than old implementation with automatic features
class ModernHomeScreen extends StatefulWidget {
  const ModernHomeScreen({super.key});

  @override
  State<ModernHomeScreen> createState() => _ModernHomeScreenState();
}

class _ModernHomeScreenState extends State<ModernHomeScreen> {
  late HomeDashboardProvider _dashboardProvider;

  @override
  void initState() {
    super.initState();
    _initializeDashboard();
  }

  void _initializeDashboard() {
    // Get provider from service locator
    _dashboardProvider = ServiceLocator.instance.get<HomeDashboardProvider>();

    // Initialize dashboard data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _dashboardProvider.initializeDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _dashboardProvider,
      child: Consumer<HomeDashboardProvider>(
        builder: (context, dashboard, child) {
          return BaseScreen(
            showAppBar: true,
            useSlidingDrawer: true,
            appBar: _buildAppBar(context, dashboard),
            body: _buildBody(context, dashboard),
          );
        },
      ),
    );
  }

  CustomAppBar _buildAppBar(
      BuildContext context, HomeDashboardProvider dashboard) {
    return CustomAppBar(
      showSearch: true,
      searchWidget: CustomSearchBar(
        hintText: 'Search properties...',
        onSearchChanged: (query) {
          dashboard.searchProperties(query);
        },
        showFilterIcon: true,
        onFilterIconPressed: () {
          context.push('/filter', extra: {
            'onApplyFilters': (Map<String, dynamic> filters) =>
                dashboard.applyPropertyFilters(filters),
          });
        },
      ),
      showAvatar: true,
      avatarWidget: Builder(
        builder: (BuildContext avatarContext) {
          return CustomAvatar(
            imageUrl:
                'assets/images/user-image.png', // TODO: Add profileImageUrl to User model
            onTap: () {
              BaseScreenState.of(avatarContext)?.toggleDrawer();
            },
          );
        },
      ),
      showBackButton: false,
      userLocationWidget: LocationWidget(
        title: dashboard.welcomeMessage,
        location: dashboard.userLocation,
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => dashboard.refreshDashboard(),
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, HomeDashboardProvider dashboard) {
    // Show loading state during initial load
    if (dashboard.isLoading && dashboard.nearbyProperties.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Show error state if critical error occurred
    if (dashboard.hasError && dashboard.nearbyProperties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              dashboard.errorMessage ?? 'Something went wrong',
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => dashboard.initializeDashboard(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: dashboard.refreshDashboard,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User booking stats
              _buildBookingStatsSection(dashboard),
              const SizedBox(height: 24),

              // Quick actions
              _buildQuickActionsSection(context),
              const SizedBox(height: 24),

              // Nearby Properties
              _buildNearbyPropertiesSection(context, dashboard),
              const SizedBox(height: 24),

              // Featured Properties
              _buildFeaturedPropertiesSection(context, dashboard),
              const SizedBox(height: 24),

              // Recommended Properties
              _buildRecommendedPropertiesSection(context, dashboard),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBookingStatsSection(HomeDashboardProvider dashboard) {
    // Show stats only if user has bookings
    if (!dashboard.hasActiveStays && !dashboard.hasUpcomingStays) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Stays',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        BookingStatsCard(
          currentStays: dashboard.currentStays,
          upcomingStays: dashboard.upcomingStays,
          onViewAll: () => context.push('/bookings'),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        QuickActionsSection(
          onExplorePressed: () => context.push('/explore'),
          onSavedPressed: () => context.push('/saved'),
          onBookingsPressed: () => context.push('/bookings'),
          onProfilePressed: () => context.push('/profile'),
        ),
      ],
    );
  }

  Widget _buildNearbyPropertiesSection(
      BuildContext context, HomeDashboardProvider dashboard) {
    return Consumer<HomeDashboardProvider>(
      builder: (context, dashboard, child) {
        final provider = dashboard.nearbyPropertiesProvider;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Near your location',
              onSeeAll: provider.items.isNotEmpty
                  ? () => context.push('/explore')
                  : null,
            ),
            const SizedBox(height: 12),
            _buildPropertySlider(
              context,
              provider.items,
              provider.isLoading,
              provider.hasError,
              provider.errorMessage,
              onRetry: () => dashboard.initializeDashboard(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedPropertiesSection(
      BuildContext context, HomeDashboardProvider dashboard) {
    return Consumer<HomeDashboardProvider>(
      builder: (context, dashboard, child) {
        final provider = dashboard.featuredPropertiesProvider;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Featured Properties',
              onSeeAll: provider.items.isNotEmpty
                  ? () => context.push('/explore')
                  : null,
            ),
            const SizedBox(height: 12),
            _buildPropertySlider(
              context,
              provider.items,
              provider.isLoading,
              provider.hasError,
              provider.errorMessage,
              onRetry: () => dashboard.initializeDashboard(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecommendedPropertiesSection(
      BuildContext context, HomeDashboardProvider dashboard) {
    return Consumer<HomeDashboardProvider>(
      builder: (context, dashboard, child) {
        final provider = dashboard.recommendedPropertiesProvider;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Recommended for you',
              onSeeAll: provider.items.isNotEmpty
                  ? () => context.push('/explore')
                  : null,
            ),
            const SizedBox(height: 12),
            _buildVerticalPropertyList(
              context,
              provider.items,
              provider.isLoading,
              provider.hasError,
              provider.errorMessage,
              onRetry: () => dashboard.initializeDashboard(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildPropertySlider(
    BuildContext context,
    List<dynamic> items,
    bool isLoading,
    bool hasError,
    String? errorMessage, {
    VoidCallback? onRetry,
  }) {
    if (isLoading && items.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError && items.isEmpty) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300]),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Failed to load properties',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text(
            'No properties available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    final propertyCards = items.map((property) {
      return PropertyCard(
        property: property,
        onTap: () {
          context.push('/property/${property.propertyId}');
        },
      );
    }).toList();

    return CustomSlider(items: propertyCards);
  }

  Widget _buildVerticalPropertyList(
    BuildContext context,
    List<dynamic> items,
    bool isLoading,
    bool hasError,
    String? errorMessage, {
    VoidCallback? onRetry,
  }) {
    if (isLoading && items.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (hasError && items.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red[300]),
              const SizedBox(height: 8),
              Text(
                errorMessage ?? 'Failed to load recommendations',
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              if (onRetry != null)
                TextButton(
                  onPressed: onRetry,
                  child: const Text('Retry'),
                ),
            ],
          ),
        ),
      );
    }

    if (items.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(
          child: Text(
            'No recommendations available',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final property = items[index];
          return SizedBox(
            width: 180,
            child: PropertyCard.vertical(
              property: property,
              onTap: () {
                context.push('/property/${property.propertyId}');
              },
            ),
          );
        },
      ),
    );
  }
}
