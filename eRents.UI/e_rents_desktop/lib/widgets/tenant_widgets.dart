import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../models/tenant_preference.dart';
import '../models/tenant_feedback.dart';
import '../features/tenants/providers/tenant_provider.dart';

class TenantCard extends StatelessWidget {
  final User tenant;
  final bool isCurrentTenant;
  final VoidCallback? onMessage;
  final VoidCallback? onViewProfile;

  const TenantCard({
    Key? key,
    required this.tenant,
    this.isCurrentTenant = false,
    this.onMessage,
    this.onViewProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      tenant.profileImage != null
                          ? NetworkImage(tenant.profileImage!)
                          : null,
                  child:
                      tenant.profileImage == null
                          ? Text(
                            '${tenant.firstName[0]}${tenant.lastName[0]}',
                            style: const TextStyle(fontSize: 20),
                          )
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${tenant.firstName} ${tenant.lastName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tenant.email,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (tenant.phone != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          tenant.phone!,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onMessage != null)
                  TextButton.icon(
                    onPressed: onMessage,
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                  ),
                if (onViewProfile != null) ...[
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: onViewProfile,
                    icon: const Icon(Icons.person),
                    label: const Text('View Profile'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TenantPreferenceCard extends StatelessWidget {
  final TenantPreference preference;
  final VoidCallback? onSendOffer;

  const TenantPreferenceCard({
    Key? key,
    required this.preference,
    this.onSendOffer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${preference.minPrice} - ${preference.maxPrice} \$',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(preference.city, style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  preference.amenities
                      .map(
                        (amenity) => Chip(
                          label: Text(amenity),
                          backgroundColor: Colors.blue[50],
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 8),
            Text(preference.description, style: const TextStyle(fontSize: 14)),
            if (onSendOffer != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onSendOffer,
                    icon: const Icon(Icons.send),
                    label: const Text('Send Property Offer'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class TenantFeedbackCard extends StatelessWidget {
  final TenantFeedback feedback;

  const TenantFeedbackCard({Key? key, required this.feedback})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ...List.generate(
                  5,
                  (index) => Icon(
                    Icons.star,
                    color:
                        index < feedback.rating
                            ? Colors.amber
                            : Colors.grey[300],
                  ),
                ),
                const Spacer(),
                Text(
                  '${feedback.stayStartDate.year}-${feedback.stayEndDate.year}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(feedback.comment, style: const TextStyle(fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class TenantSearchBar extends StatelessWidget {
  final TextEditingController searchController;
  final String? selectedCity;
  final List<String> cities;
  final ValueChanged<String?>? onCityChanged;
  final VoidCallback? onSearch;

  const TenantSearchBar({
    Key? key,
    required this.searchController,
    this.selectedCity,
    this.cities = const [],
    this.onCityChanged,
    this.onSearch,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search tenants...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onSubmitted: (_) => onSearch?.call(),
            ),
            const SizedBox(height: 16),
            if (cities.isNotEmpty)
              DropdownButtonFormField<String>(
                value: selectedCity,
                decoration: InputDecoration(
                  labelText: 'Filter by City',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('All Cities'),
                  ),
                  ...cities.map(
                    (city) => DropdownMenuItem(value: city, child: Text(city)),
                  ),
                ],
                onChanged: onCityChanged,
              ),
          ],
        ),
      ),
    );
  }
}

class PaginationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const PaginationControls({
    Key? key,
    required this.currentPage,
    required this.totalPages,
    this.onPrevious,
    this.onNext,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: currentPage > 1 ? onPrevious : null,
        ),
        Text('Page $currentPage of $totalPages'),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: currentPage < totalPages ? onNext : null,
        ),
      ],
    );
  }
}
