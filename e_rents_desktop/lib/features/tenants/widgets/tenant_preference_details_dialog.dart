import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/models/tenant_preference.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/features/tenants/widgets/tenant_match_score_widget.dart';
import 'package:e_rents_desktop/utils/date_utils.dart';

class TenantPreferenceDetailsDialog extends StatelessWidget {
  final TenantPreference preference;
  final User tenant;

  const TenantPreferenceDetailsDialog({
    super.key,
    required this.preference,
    required this.tenant,
  });

  @override
  Widget build(BuildContext context) {
    final matchScore = (preference.matchScore * 100).round();
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        width: 650,
        constraints: const BoxConstraints(maxHeight: 750),
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with tenant info and match score
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: theme.colorScheme.primaryContainer,
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                            )
                            : null,
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          preference.userFullName ?? 'Unknown User',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preference.userEmail ?? 'No email',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (preference.userPhone != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              preference.userPhone!,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text(
                        'Match Score',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TenantMatchScoreWidget(score: matchScore),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Location and Budget Row
              Row(
                children: [
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      title: 'Location Preference',
                      value: preference.city,
                      icon: Icons.location_city_outlined,
                      iconColor: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildInfoCard(
                      context,
                      title: 'Monthly Budget',
                      value:
                          '${preference.minPrice != null ? kCurrencyFormat.format(preference.minPrice) : 'Any'} - '
                          '${preference.maxPrice != null ? kCurrencyFormat.format(preference.maxPrice) : 'Any'}',
                      icon: Icons.attach_money_outlined,
                      iconColor: theme.colorScheme.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Move-in Timeline
              _buildInfoCard(
                context,
                title: 'Ideal Move-in Dates',
                value:
                    '${_formatDate(preference.searchStartDate)} ${preference.searchEndDate != null ? 'to ${_formatDate(preference.searchEndDate!)}' : '(Flexible)'}',
                icon: Icons.calendar_month_outlined,
                iconColor: Colors.orange.shade700,
              ),
              const SizedBox(height: 18),

              // Amenities
              _buildSection(
                context,
                title: 'Desired Amenities',
                content:
                    preference.amenities.isNotEmpty
                        ? Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children:
                              preference.amenities
                                  .map(
                                    (amenity) => Chip(
                                      label: Text(amenity),
                                      backgroundColor: theme
                                          .colorScheme
                                          .secondaryContainer
                                          .withOpacity(0.5),
                                      labelStyle: TextStyle(
                                        color:
                                            theme
                                                .colorScheme
                                                .onSecondaryContainer,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                    ),
                                  )
                                  .toList(),
                        )
                        : Text(
                          'No specific amenities listed.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
              ),
              const SizedBox(height: 24),

              // Description
              if (preference.description.isNotEmpty) ...[
                _buildSection(
                  context,
                  title: 'Tenant Description',
                  content: Text(
                    preference.description,
                    style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Match Reasons
              if (preference.matchReasons.isNotEmpty) ...[
                _buildSection(
                  context,
                  title: 'Key Matching Points',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:
                        preference.matchReasons
                            .map(
                              (reason) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      size: 20,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        reason,
                                        style: theme.textTheme.bodyLarge,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ),
                const SizedBox(height: 28),
              ],

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // TODO: Implement send property offer functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Property offer feature for ${preference.userFullName} coming soon!',
                            style: TextStyle(
                              color: theme.colorScheme.onInverseSurface,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.inverseSurface,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: const EdgeInsets.all(10),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.send_outlined),
                    label: const Text('Send Property Offer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: iconColor ?? theme.colorScheme.primary,
                size: 22,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required Widget content,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        content,
      ],
    );
  }

  String _formatDate(DateTime date) {
    return AppDateUtils.formatShort(date);
  }

  String _getInitials(String fullName) {
    if (fullName.isEmpty) return 'U';
    final names = fullName.trim().split(' ');
    if (names.length == 1) {
      return names[0].isNotEmpty ? names[0][0].toUpperCase() : 'U';
    }
    return names
        .where((name) => name.isNotEmpty)
        .map((name) => name[0].toUpperCase())
        .take(2)
        .join();
  }
}
