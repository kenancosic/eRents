import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/core/widgets/custom_app_bar.dart';
import 'package:e_rents_mobile/core/widgets/custom_avatar.dart';
import 'package:e_rents_mobile/core/models/property_card_model.dart';
import 'package:e_rents_mobile/core/widgets/property_card.dart';
import 'package:e_rents_mobile/features/users/providers/public_user_provider.dart';
import 'package:e_rents_mobile/core/enums/property_enums.dart';
import 'package:e_rents_mobile/core/models/property_detail.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class PublicUserScreen extends StatefulWidget {
  final int userId;
  final String? displayName;

  const PublicUserScreen({super.key, required this.userId, this.displayName});

  @override
  State<PublicUserScreen> createState() => _PublicUserScreenState();
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 48, color: Colors.grey[500]),
          const SizedBox(height: 8),
          const Text('No properties found'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _PublicUserScreenState extends State<PublicUserScreen> {
  @override
  void initState() {
    super.initState();
    // Defer to next frame to ensure provider available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<PublicUserProvider>();
      provider.loadUser(widget.userId);
      provider.loadOwnerProperties(widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Owner Profile',
        showBackButton: true,
      ),
      body: Consumer<PublicUserProvider>(
        builder: (context, provider, child) {
          final user = provider.user;
          final properties = provider.filteredProperties;
          final isLoading = provider.isLoading;
          final hasError = provider.hasError;
          final errorMessage = provider.errorMessage;
          final api = context.read<ApiService>();

          if (isLoading && user == null && properties.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (hasError && user == null && properties.isEmpty) {
            return _ErrorState(
              message: errorMessage.isNotEmpty ? errorMessage : 'Failed to load user',
              onRetry: () {
                provider.loadUser(widget.userId);
                provider.loadOwnerProperties(widget.userId);
              },
            );
          }

          final imageUrl = (user?.profileImageId != null && user!.profileImageId! > 0)
              ? api.makeAbsoluteUrl('/api/Images/${user.profileImageId}/content')
              : 'assets/images/user-image.png';

          final fullName = (user?.fullName.isNotEmpty ?? false) ? user!.fullName : (widget.displayName ?? 'User');
          final username = (user?.username.isNotEmpty ?? false) ? '@${user!.username}' : '';
          final email = user?.email ?? '';

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CustomAvatar(imageUrl: imageUrl, size: 64),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(fullName, style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (username.isNotEmpty)
                                Text(username, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
                              if (email.isNotEmpty)
                                Text(email, style: Theme.of(context).textTheme.bodyMedium),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Message',
                      icon: const Icon(Icons.message_outlined),
                      onPressed: () {
                        context.push('/chat/${widget.userId.toString()}', extra: {
                          'name': fullName,
                        });
                      },
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Properties', style: Theme.of(context).textTheme.titleMedium),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: !provider.onlyAvailable,
                          onSelected: (sel) => provider.setOnlyAvailable(false),
                        ),
                        ChoiceChip(
                          label: const Text('Available'),
                          selected: provider.onlyAvailable,
                          onSelected: (sel) => provider.setOnlyAvailable(true),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(
                  children: [
                    Text('Sort:', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(width: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Available first'),
                          selected: context.select<PublicUserProvider, bool>((p) => p.sort == PublicUserSort.availableFirst),
                          onSelected: (_) => context.read<PublicUserProvider>().setSort(PublicUserSort.availableFirst),
                        ),
                        ChoiceChip(
                          label: const Text('Newest'),
                          selected: context.select<PublicUserProvider, bool>((p) => p.sort == PublicUserSort.newest),
                          onSelected: (_) => context.read<PublicUserProvider>().setSort(PublicUserSort.newest),
                        ),
                        ChoiceChip(
                          label: const Text('Price ↑'),
                          selected: context.select<PublicUserProvider, bool>((p) => p.sort == PublicUserSort.priceLowToHigh),
                          onSelected: (_) => context.read<PublicUserProvider>().setSort(PublicUserSort.priceLowToHigh),
                        ),
                        ChoiceChip(
                          label: const Text('Price ↓'),
                          selected: context.select<PublicUserProvider, bool>((p) => p.sort == PublicUserSort.priceHighToLow),
                          onSelected: (_) => context.read<PublicUserProvider>().setSort(PublicUserSort.priceHighToLow),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: isLoading && properties.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : properties.isEmpty
                        ? const _EmptyState()
                        : RefreshIndicator(
                            onRefresh: () => context.read<PublicUserProvider>().refreshOwner(widget.userId),
                            child: ListView.builder(
                              padding: const EdgeInsets.only(bottom: 8),
                              itemCount: properties.length + (provider.hasMore ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= properties.length) {
                                  // Load more row
                                  if (!provider.isLoadingMore) {
                                    // Trigger load more
                                    WidgetsBinding.instance.addPostFrameCallback((_) {
                                      context.read<PublicUserProvider>().loadMoreOwnerProperties(widget.userId);
                                    });
                                  }
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: provider.isLoadingMore
                                          ? const SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: CircularProgressIndicator(strokeWidth: 2),
                                            )
                                          : const SizedBox.shrink(),
                                    ),
                                  );
                                }

                                final p = properties[index];
                                final card = _toCardModel(p);
                                return _CardWithStatus(
                                  property: p,
                                  card: card,
                                  onTap: () => context.push('/property/${p.propertyId}'),
                                );
                              },
                            ),
                          ),
              ),
            ],
          );
        },
      ),
    );
  }

  PropertyCardModel _toCardModel(p) {
    return PropertyCardModel(
      propertyId: p.propertyId,
      name: p.name,
      price: p.price,
      currency: p.currency,
      averageRating: p.averageRating,
      coverImageId: p.coverImageId,
      address: p.address,
      rentalType: p.rentalType,
    );
  }
}

class _CardWithStatus extends StatelessWidget {
  final PropertyDetail property;
  final PropertyCardModel card;
  final VoidCallback onTap;
  const _CardWithStatus({required this.property, required this.card, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        PropertyCard.vertical(property: card, onTap: onTap),
        Positioned(
          top: 12,
          left: 12,
          child: _StatusPill(status: property.status),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final PropertyStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    final text = _statusText(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Color _statusColor(PropertyStatus s) {
    switch (s) {
      case PropertyStatus.available:
        return Colors.green.shade700;
      case PropertyStatus.rented:
        return Colors.blue.shade700;
      case PropertyStatus.maintenance:
        return Colors.orange.shade700;
      case PropertyStatus.unavailable:
        return Colors.red.shade700;
    }
  }

  String _statusText(PropertyStatus s) {
    switch (s) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.rented:
        return 'Occupied';
      case PropertyStatus.maintenance:
        return 'Maintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
    }
  }
}
