import 'package:e_rents_desktop/models/property.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For currency formatting

class PropertyInsightsCard extends StatelessWidget {
  final List<Property> properties;
  final NumberFormat currencyFormat; // Receive formatter

  const PropertyInsightsCard({
    super.key,
    required this.properties,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Calculate stats
    final totalProperties = properties.length;
    final availableProperties =
        properties.where((p) => p.status.toLowerCase() == 'available').toList();
    final rentedProperties = totalProperties - availableProperties.length;
    final occupancyRate =
        totalProperties > 0 ? (rentedProperties / totalProperties) : 0.0;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 12.0,
        ), // No horizontal padding on card itself
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Use the same helper as MaintenanceOverviewCard for consistency
            _buildInsightTile(
              context: context,
              icon: Icons.business_rounded,
              iconColor: theme.colorScheme.primary,
              title: 'Total Properties',
              value: totalProperties.toString(),
            ),
            const Divider(height: 1),
            _buildInsightTile(
              context: context,
              icon: Icons.event_available_rounded,
              iconColor: Colors.green.shade700,
              title: 'Available Units',
              value: availableProperties.length.toString(),
              valueColor:
                  availableProperties.isNotEmpty ? Colors.green.shade800 : null,
            ),
            const Divider(height: 1),
            _buildInsightTile(
              context: context,
              icon: Icons.event_busy_rounded,
              iconColor: Colors.orange.shade800,
              title: 'Rented Units',
              value: rentedProperties.toString(),
            ),
            const Divider(height: 1),
            _buildInsightTile(
              context: context,
              icon: Icons.pie_chart_outline_rounded,
              iconColor: theme.colorScheme.secondary,
              title: 'Occupancy Rate',
              value: '${(occupancyRate * 100).toStringAsFixed(0)}%',
            ),

            // Optional: Show vacant properties list if needed
            if (availableProperties.isNotEmpty) ...[
              const Divider(
                height: 10,
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: Text('Vacant Properties', style: textTheme.titleSmall),
              ),
              // Limited list of vacant properties
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    availableProperties.length > 3
                        ? 3
                        : availableProperties.length, // Limit to 3 max
                itemBuilder: (context, index) {
                  final property = availableProperties[index];
                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 0,
                    ),
                    title: Text(
                      property.title,
                      style: textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Text(
                      currencyFormat.format(property.price),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // onTap: () { /* Navigate to property details */ },
                  );
                },
              ),
              if (availableProperties.length > 3)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    '... and ${availableProperties.length - 3} more',
                    style: textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 8), // Add space before button
            ],

            // View All Button
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
                right: 8.0,
                bottom: 0,
                left: 8.0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: Implement navigation to full properties list
                    print('Navigate to all properties');
                  },
                  child: const Text('View All Properties'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Copied from MaintenanceOverviewCard - consider moving to a shared helper file
  Widget _buildInsightTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    Color? valueColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return ListTile(
      leading: Padding(
        padding: const EdgeInsets.only(
          left: 8.0,
        ), // Add padding to align icon with Card padding
        child: Icon(icon, color: iconColor),
      ),
      title: Text(title, style: textTheme.bodyLarge),
      trailing: Padding(
        padding: const EdgeInsets.only(right: 8.0), // Add padding to align text
        child: Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: valueColor ?? textTheme.bodyMedium?.color?.withOpacity(0.8),
          ),
        ),
      ),
      onTap: onTap,
      dense: true,
      // Remove internal padding, handled by Padding widgets above
      contentPadding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
    );
  }
}
