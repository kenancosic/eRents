import 'package:e_rents_mobile/core/base/base_screen.dart';
import 'dart:async';
import 'package:signalr_core/signalr_core.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/widgets/custom_search_bar.dart';
import 'package:e_rents_mobile/core/widgets/location_widget.dart';
import 'package:e_rents_mobile/core/widgets/section_header.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/core/models/address.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';
import 'package:e_rents_mobile/features/home/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _pendingRefreshTimer;
  HubConnection? _notifHub;

  void _handleApplyFilters(BuildContext context, Map<String, dynamic> filters) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filters applied!')),
    );
  }

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
              height: 240, // Fixed height for vertical cards
              child: ListView.builder(
                primary: false,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: provider.recommendedCards.length,
                itemBuilder: (context, index) {
                  final card = provider.recommendedCards[index];
                  return SizedBox(
                    width: 180, // Fixed width for vertical cards
                    child: PropertyCard(
                      layout: PropertyCardLayout.vertical,
                      property: card,
                      onTap: () {
                        context.push('/property/${card.propertyId}');
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
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  "You're not currently residing in any property.",
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                height: 240,
                child: ListView.builder(
                  primary: false,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final card = items[index];
                    return SizedBox(
                      width: 180,
                      child: PropertyCard.vertical(
                        property: card,
                        onTap: () {
                          context.push('/property/${card.propertyId}');
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
            if (provider.upcomingBookings.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Text(
                  'No upcoming bookings found.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            else
              SizedBox(
                // Match the visual design of Current Residences/Recommended
                height: 240,
                child: ListView.builder(
                  primary: false,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.upcomingBookings.length,
                  itemBuilder: (context, index) {
                    final booking = provider.upcomingBookings[index];
                    // Create a minimal Property object from booking data
                    final card = PropertyCardModel(
                      propertyId: booking.propertyId,
                      name: booking.propertyName,
                      price: booking.dailyRate,
                      currency: booking.currency ?? 'USD',
                      averageRating: null,
                      coverImageId: null,
                      address: Address(city: '', streetLine1: ''),
                      rentalType: PropertyRentalType.daily,
                    );
                    return SizedBox(
                      width: 180,
                      child: PropertyCard.vertical(
                        property: card,
                        onTap: () {
                          context.push('/property/${booking.propertyId}');
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
        if (provider.pendingBookings.isEmpty) {
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
              height: 240,
              child: ListView.builder(
                primary: false,
                shrinkWrap: true,
                physics: const ClampingScrollPhysics(),
                scrollDirection: Axis.horizontal,
                itemCount: provider.pendingBookings.length,
                itemBuilder: (context, index) {
                  final booking = provider.pendingBookings[index];
                  // Create a minimal Property object from booking data
                  final card = PropertyCardModel(
                    propertyId: booking.propertyId,
                    name: booking.propertyName,
                    price: booking.dailyRate,
                    currency: booking.currency ?? 'USD',
                    averageRating: null,
                    coverImageId: 0,
                    address: Address(city: '', streetLine1: ''),
                    rentalType: PropertyRentalType.monthly,
                  );
                  return SizedBox(
                    width: 180,
                    child: Stack(
                      children: [
                        PropertyCard(
                          layout: PropertyCardLayout.vertical,
                          property: card,
                          onTap: () {
                            context.push('/property/${booking.propertyId}');
                          },
                        ),
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
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
      await context.read<HomeProvider>().initializeDashboard();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load dashboard data: ${error.toString()}'),
            backgroundColor: Colors.red,
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

  @override
  Widget build(BuildContext context) {
    final searchBar = CustomSearchBar(
      hintText: 'Search properties...',
      onSearchChanged: (query) {
        // Handle search query
      },
      showFilterIcon: true,
      onFilterIconPressed: () {
        context.push('/filter', extra: {
          'onApplyFilters': (Map<String, dynamic> filters) =>
              _handleApplyFilters(context, filters),
        });
      },
    );

    final appBar = CustomAppBar(
      showSearch: true,
      searchWidget: searchBar,
      showAvatar: true,
      avatarWidget: Builder(
        builder: (avatarContext) => CustomAvatar(
          imageUrl: 'assets/images/user-image.png',
          onTap: () {
            BaseScreenState.of(avatarContext)?.toggleDrawer();
          },
        ),
      ),
      showBackButton: false,
      userLocationWidget: Consumer<HomeProvider>(
        builder: (context, provider, _) => LocationWidget(
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

    return BaseScreen(
      showAppBar: true,
      useSlidingDrawer: true,
      appBar: appBar,
      body: Consumer<HomeProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            onRefresh: () async {
              // Refresh all dashboard data
              try {
                await provider.initializeDashboard();
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to refresh data: ${error.toString()}'),
                      backgroundColor: Colors.red,
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
                  _buildCurrentResidencesSection(context),
                  _buildRecommendedSection(context),
                  _buildUpcomingBookingsSection(context),
                  _buildPendingBookingsSection(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
