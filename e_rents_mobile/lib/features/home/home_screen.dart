import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'dart:async';
import 'package:signalr_core/signalr_core.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/features/profile/providers/user_profile_provider.dart';
import 'package:e_rents_mobile/core/providers/current_user_provider.dart';
import 'package:e_rents_mobile/core/widgets/location_widget.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/features/home/providers/home_provider.dart';
import 'package:e_rents_mobile/features/saved/saved_provider.dart';
import 'package:e_rents_mobile/features/property_detail/utils/view_context.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:e_rents_mobile/core/utils/app_spacing.dart';
import 'package:e_rents_mobile/core/utils/app_colors.dart';
import 'package:e_rents_mobile/core/widgets/empty_state_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _pendingRefreshTimer;
  HubConnection? _notifHub;

  Widget _buildRecommendedSection(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        // If we have no recommended properties or are still loading, show a loading indicator or empty state
        if (provider.recommendedCards.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Recommended for you',
              onSeeAll: () {
                context.push('/explore');
              },
            ),
            // Use vertical cards for recommended section for variety
            SizedBox(
              height: PropertyCardDimensions.verticalHeight + AppSpacing.xl,
              child: ListView.builder(
                primary: false,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.paddingH_MD,
                itemCount: provider.recommendedCards.length,
                itemBuilder: (context, index) {
                  final card = provider.recommendedCards[index];
                  return SizedBox(
                    width: PropertyCardDimensions.verticalWidth,
                    child: Stack(
                      children: [
                        PropertyCard(
                          layout: PropertyCardLayout.vertical,
                          property: card,
                          onTap: () {
                            context.push('/property/${card.propertyId}');
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCurrentResidencesSection(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        final items = provider.currentResidences;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Currently residing properties',
            ),
            if (items.isEmpty)
              Padding(
                padding: AppSpacing.paddingH_MD,
                child: EmptyStateCompact(
                  icon: Icons.home_outlined,
                  message: "You're not currently residing in any property.",
                ),
              )
            else
              SizedBox(
                height: PropertyCardDimensions.verticalHeight + AppSpacing.xl,
                child: ListView.builder(
                  primary: false,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.paddingH_MD,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final card = items[index];
                    return SizedBox(
                      width: PropertyCardDimensions.verticalWidth,
                      child: Stack(
                        children: [
                          PropertyCard(
                            layout: PropertyCardLayout.vertical,
                            property: card,
                            onTap: () {
                              final booking = context.read<HomeProvider>().getBookingForProperty(card.propertyId);
                              context.push(
                                '/property/${card.propertyId}',
                                extra: {
                                  'viewContext': ViewContext.activeLease,
                                  'bookingId': booking?.bookingId,
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingBookingsSection(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Upcoming Bookings',
              onSeeAll: () {
                context.push('/bookings');
              },
            ),
            if (provider.upcomingCards.isEmpty)
              Padding(
                padding: AppSpacing.paddingH_MD,
                child: EmptyStateCompact(
                  icon: Icons.calendar_today_outlined,
                  message: 'No upcoming bookings found.',
                ),
              )
            else
              SizedBox(
                height: PropertyCardDimensions.verticalHeight + AppSpacing.xl,
                child: ListView.builder(
                  primary: false,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  padding: AppSpacing.paddingH_MD,
                  itemCount: provider.upcomingCards.length,
                  itemBuilder: (context, index) {
                    final card = provider.upcomingCards[index];
                    return SizedBox(
                      width: PropertyCardDimensions.verticalWidth,
                      child: PropertyCard.vertical(
                        property: card,
                        onTap: () {
                          final booking = context.read<HomeProvider>().getBookingForProperty(card.propertyId);
                          context.push(
                            '/property/${card.propertyId}',
                            extra: {
                              'viewContext': ViewContext.upcomingBooking,
                              'bookingId': booking?.bookingId,
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildPendingBookingsSection(BuildContext context) {
    return Consumer<HomeProvider>(
      builder: (context, provider, child) {
        if (provider.pendingCards.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: 'Pending Monthly Bookings',
              onSeeAll: () {
                context.push('/bookings');
              },
            ),
            SizedBox(
              // Match the visual design of Current Residences/Recommended
              height: PropertyCardDimensions.verticalHeight + AppSpacing.xl,
              child: ListView.builder(
                primary: false,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                padding: AppSpacing.paddingH_MD,
                itemCount: provider.pendingCards.length,
                itemBuilder: (context, index) {
                  final card = provider.pendingCards[index];
                  return SizedBox(
                    width: PropertyCardDimensions.verticalWidth,
                    child: Stack(
                      children: [
                        PropertyCard(
                          layout: PropertyCardLayout.vertical,
                          property: card,
                          onTap: () {
                            final booking = context.read<HomeProvider>().getBookingForProperty(card.propertyId);
                            context.push(
                              '/property/${card.propertyId}',
                              extra: {
                                'viewContext': ViewContext.upcomingBooking,
                                'bookingId': booking?.bookingId,
                              },
                            );
                          },
                        ),
                        Positioned(
                          top: AppSpacing.sm,
                          left: AppSpacing.sm,
                          child: Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: AppRadius.smRadius,
                            ),
                            child: const Text(
                              'Awaiting acceptance',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  

  @override
  void initState() {
    super.initState();
    // Initialize dashboard data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Ensure profile is loaded for avatar rendering across the app
      context.read<UserProfileProvider>().loadCurrentUser();
      // Load saved property IDs so bookmark icons render correctly on property cards
      context.read<SavedProvider>().loadSavedProperties();
      _initializeDashboard();
      // Start periodic refresh of pending monthly bookings so user sees acceptance updates
      _pendingRefreshTimer?.cancel();
      _pendingRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
        if (!mounted) return;
        await context.read<HomeProvider>().refreshPendingBookings();
      });
      _connectNotifications();
    });
  }

  Future<void> _initializeDashboard() async {
    try {
      final currentUserProvider = context.read<CurrentUserProvider>();
      await context.read<HomeProvider>().initializeDashboard(currentUserProvider);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${error.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pendingRefreshTimer?.cancel();
    final hub = _notifHub;
    if (hub != null) {
      hub.stop();
      _notifHub = null;
    }
    super.dispose();
  }

  Future<void> _connectNotifications() async {
    // Build hub URL by stripping trailing '/api' from baseUrl
    String _buildHubUrl(String baseUrl) {
      final uri = Uri.parse(baseUrl);
      var path = uri.path;
      if (path.endsWith('/')) path = path.substring(0, path.length - 1);
      if (path.endsWith('/api')) path = path.substring(0, path.length - 4);
      final cleanPath = path.isEmpty ? '/' : path;
      final hub = uri.replace(path: '${cleanPath == '/' ? '' : cleanPath}/chatHub');
      return hub.toString();
    }

    try {
      final api = context.read<ApiService>();
      final token = await api.secureStorageService.getToken();
      if (token == null || token.isEmpty) return;

      final hubUrl = _buildHubUrl(api.baseUrl);
      final hub = HubConnectionBuilder()
          .withUrl(
            hubUrl,
            HttpConnectionOptions(
              accessTokenFactory: () async => token,
              transport: HttpTransportType.webSockets,
            ),
          )
          .withAutomaticReconnect([0, 2000, 10000, 30000])
          .build();

      // Register notification handler
      hub.on('ReceiveNotification', (args) async {
        if (!mounted) return;
        if (args == null || args.isEmpty) return;
        final data = args.first;
        if (data is Map) {
          final type = (data['type'] ?? '').toString();
          final title = (data['title'] ?? '').toString();
          final message = (data['message'] ?? '').toString();
          if (type == 'booking') {
            // Refresh pending bookings immediately on booking notifications
            await context.read<HomeProvider>().refreshPendingBookings();
          }
          // Show toast
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(title.isNotEmpty ? '$title: $message' : message)),
            );
          }
        }
      });

      await hub.start();
      _notifHub = hub;
    } catch (_) {
      // Fail silently; polling still works
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return _HomeAppBar();
  }

  @override
  Widget build(BuildContext context) {
    // Search functionality belongs in Explore screen only
    // Removed redundant search bar from Home

    return BaseScreen(
      showAppBar: true,
      useSlidingDrawer: true,
      appBar: _buildAppBar(context),
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              // Refresh all dashboard data
              try {
                final currentUserProvider = context.read<CurrentUserProvider>();
                await provider.refreshDashboard(currentUserProvider);
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh data: ${error.toString()}'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: AppSpacing.md),
                  _buildCurrentResidencesSection(context),
                  SizedBox(height: AppSpacing.lg),
                  _buildRecommendedSection(context),
                  SizedBox(height: AppSpacing.lg),
                  _buildUpcomingBookingsSection(context),
                  SizedBox(height: AppSpacing.lg),
                  _buildPendingBookingsSection(context),
                  SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom AppBar for Home screen that properly implements PreferredSizeWidget
class _HomeAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProfileProvider>(
      builder: (context, profile, _) {
        return CustomAppBar(
          showSearch: false,
          showAvatar: true,
          avatarWidget: Builder(
            builder: (avatarContext) {
              return CustomAvatar(
                imageUrl: profile.profileImageUrlOrPlaceholder,
                onTap: () {
                  // Use findAncestorStateOfType to get BaseScreenState from avatarContext
                  final baseScreenState = avatarContext.findAncestorStateOfType<BaseScreenState>();
                  baseScreenState?.toggleDrawer();
                },
              );
            },
          ),
          showBackButton: false,
          userLocationWidget: Consumer<HomeProvider>(
            builder: (locationContext, provider, _) => LocationWidget(
              title: 'Welcome back, ${provider.currentUser?.firstName ?? 'User'}',
              location: provider.userLocation,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                context.push('/notifications');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
