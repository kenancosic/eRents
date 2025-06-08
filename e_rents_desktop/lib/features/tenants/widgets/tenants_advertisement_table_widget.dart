import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/widgets/table/custom_table.dart';
import 'package:e_rents_desktop/features/tenants/widgets/tenant_match_score_widget.dart';
import 'package:e_rents_desktop/utils/formatters.dart';

class TenantsAdvertisementTableWidget extends StatelessWidget {
  final List<TenantPreference> preferences;
  final List<User> tenants;
  final String searchTerm;
  final String currentFilterField;
  final Function(TenantPreference) onSendMessage;
  final Function(TenantPreference, User) onShowDetails;

  const TenantsAdvertisementTableWidget({
    super.key,
    required this.preferences,
    required this.tenants,
    required this.searchTerm,
    required this.currentFilterField,
    required this.onSendMessage,
    required this.onShowDetails,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalTable.create<TenantPreference>(
      fetchData: (params) async {
        // Since this is static data (already loaded), simulate server response
        final searchTerm = params['searchTerm']?.toString().toLowerCase() ?? '';

        // Apply search filter
        var filteredPreferences = preferences;
        if (searchTerm.isNotEmpty) {
          filteredPreferences =
              preferences.where((preference) {
                return preference.city.toLowerCase().contains(searchTerm) ||
                    (preference.userFullName ?? '').toLowerCase().contains(
                      searchTerm,
                    ) ||
                    (preference.userEmail ?? '').toLowerCase().contains(
                      searchTerm,
                    ) ||
                    preference.description.toLowerCase().contains(searchTerm) ||
                    preference.amenities.any(
                      (amenity) => amenity.toLowerCase().contains(searchTerm),
                    );
              }).toList();
        }

        // Apply sorting
        final sortBy = params['sortBy']?.toString();
        final sortDesc = params['sortDesc'] as bool? ?? false;

        if (sortBy != null) {
          filteredPreferences.sort((a, b) {
            dynamic aValue, bValue;
            switch (sortBy) {
              case 'tenant':
                aValue = a.userFullName ?? 'Unknown';
                bValue = b.userFullName ?? 'Unknown';
                break;
              case 'city':
                aValue = a.city;
                bValue = b.city;
                break;
              case 'minPrice':
                aValue = a.minPrice ?? 0;
                bValue = b.minPrice ?? 0;
                break;
              case 'maxPrice':
                aValue = a.maxPrice ?? 999999;
                bValue = b.maxPrice ?? 999999;
                break;
              case 'moveIn':
                aValue = a.searchStartDate;
                bValue = b.searchStartDate;
                break;
              case 'matchScore':
                aValue = (a.matchScore * 100).round();
                bValue = (b.matchScore * 100).round();
                break;
              default:
                return 0;
            }

            int comparison = Comparable.compare(aValue, bValue);
            return sortDesc ? -comparison : comparison;
          });
        }

        // Apply pagination
        final page = (params['page'] as int? ?? 1) - 1; // Convert to 0-based
        final pageSize = params['pageSize'] as int? ?? 25;
        final startIndex = page * pageSize;
        final endIndex = (startIndex + pageSize).clamp(
          0,
          filteredPreferences.length,
        );

        final pageItems = filteredPreferences.sublist(
          startIndex.clamp(0, filteredPreferences.length),
          endIndex,
        );

        return PagedResult<TenantPreference>(
          items: pageItems,
          totalCount: filteredPreferences.length,
          page: page,
          pageSize: pageSize,
          totalPages: (filteredPreferences.length / pageSize).ceil(),
        );
      },
      columns: [
        UniversalTable.column<TenantPreference>(
          key: 'tenant',
          label: 'Tenant',
          cellBuilder:
              (preference) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage:
                        (preference.profileImageUrl != null &&
                                preference.profileImageUrl!.isNotEmpty)
                            ? NetworkImage(preference.profileImageUrl!)
                            : null,
                    child:
                        preference.profileImageUrl == null ||
                                preference.profileImageUrl!.isEmpty
                            ? Text(
                              _getInitials(
                                preference.userFullName ?? 'Unknown User',
                              ),
                              style: const TextStyle(fontSize: 10),
                            )
                            : null,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preference.userFullName ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          preference.userEmail ?? 'No email',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
          width: const FlexColumnWidth(1.5),
        ),
        UniversalTable.column<TenantPreference>(
          key: 'city',
          label: 'Location',
          cellBuilder: (preference) => UniversalTable.textCell(preference.city),
          width: const FlexColumnWidth(0.8),
        ),
        UniversalTable.column<TenantPreference>(
          key: 'budget',
          label: 'Budget',
          cellBuilder:
              (preference) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${preference.minPrice != null ? kCurrencyFormat.format(preference.minPrice) : 'Any'} - '
                    '${preference.maxPrice != null ? kCurrencyFormat.format(preference.maxPrice) : 'Any'}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13),
                  ),
                  if (preference.maxPrice != null)
                    Text(
                      '/month',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                ],
              ),
          width: const FlexColumnWidth(1),
        ),
        UniversalTable.column<TenantPreference>(
          key: 'moveIn',
          label: 'Move-in Timeline',
          cellBuilder:
              (preference) => Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isUrgentMoveIn(preference.searchStartDate))
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(2),
                          ),
                          child: Text(
                            'Urgent',
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.red[900],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          _formatDate(preference.searchStartDate),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    preference.searchEndDate != null
                        ? 'to ${_formatDate(preference.searchEndDate!)}'
                        : 'Open-ended',
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
          width: const FlexColumnWidth(1.2),
        ),
        UniversalTable.column<TenantPreference>(
          key: 'amenities',
          label: 'Key Amenities',
          cellBuilder:
              (preference) => SizedBox(
                width: 140,
                child: Wrap(
                  spacing: 2,
                  runSpacing: 2,
                  children: [
                    ...preference.amenities
                        .take(2)
                        .map(
                          (amenity) => Container(
                            margin: const EdgeInsets.only(right: 2, bottom: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              amenity,
                              style: const TextStyle(fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    if (preference.amenities.length > 2)
                      Tooltip(
                        message: preference.amenities.skip(2).join(', '),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '+${preference.amenities.length - 2}',
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          sortable: false,
          width: const FlexColumnWidth(1.2),
        ),
        UniversalTable.column<TenantPreference>(
          key: 'description',
          label: 'Description',
          cellBuilder:
              (preference) => Tooltip(
                message: preference.description,
                child: Text(
                  preference.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          width: const FlexColumnWidth(1.5),
        ),
        UniversalTable.column<TenantPreference>(
          key: 'matchScore',
          label: 'Match',
          cellBuilder:
              (preference) => TenantMatchScoreWidget(
                score: (preference.matchScore * 100).round(),
              ),
          width: const FixedColumnWidth(70),
        ),
        UniversalTable.column<TenantPreference>(
          key: 'actions',
          label: 'Actions',
          cellBuilder:
              (preference) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  UniversalTable.iconActionCell(
                    icon: Icons.send,
                    onPressed: () => onSendMessage(preference),
                    tooltip: 'Send Property Offer',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 4),
                  UniversalTable.iconActionCell(
                    icon: Icons.visibility,
                    onPressed:
                        () => onShowDetails(
                          preference,
                          _createUserFromPreference(preference),
                        ),
                    tooltip: 'View Details',
                    color: Colors.green,
                  ),
                ],
              ),
          sortable: false,
          width: const FixedColumnWidth(80),
        ),
      ],
      title: 'Tenant Advertisements (${preferences.length})',
      searchHint: 'Search by tenant, city, amenities, or description...',
      emptyStateMessage:
          'No tenant advertisements found. Tenant searches will appear here.',
      defaultPageSize: 25,
    );
  }

  // Helper method to check if a move-in date is urgent (within 30 days)
  bool _isUrgentMoveIn(DateTime moveInDate) {
    final now = DateTime.now();
    final difference = moveInDate.difference(now).inDays;
    return difference >= 0 && difference <= 30;
  }

  // Helper method to format dates in a user-friendly way
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Helper method to get initials from a full name
  String _getInitials(String fullName) {
    final names = fullName.split(' ');
    return names.map((name) => name[0]).join();
  }

  // Helper method to create a User object from a TenantPreference
  User _createUserFromPreference(TenantPreference preference) {
    final fullName = preference.userFullName ?? 'Unknown User';
    final nameParts = fullName.split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : 'Unknown';
    final lastName =
        nameParts.length > 1 ? nameParts.sublist(1).join(' ') : 'User';

    return User(
      id: preference.userId,
      email: preference.userEmail ?? 'no-email@example.com',
      username: preference.userEmail?.split('@').first ?? 'unknown',
      firstName: firstName,
      lastName: lastName,
      role: UserType.tenant,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
