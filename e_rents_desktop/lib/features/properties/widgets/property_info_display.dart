import 'package:flutter/material.dart';
import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/widgets/status_chip.dart';

/// Standardized property information display widget
///
/// This widget ensures consistent display of property data across all screens
/// and helps identify data inconsistencies.
class PropertyInfoDisplay extends StatelessWidget {
  final Property property;
  final bool showStatus;

  const PropertyInfoDisplay({
    super.key,
    required this.property,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                property.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (showStatus)
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: StatusChip(
                  label: property.propertyStatus.displayName,
                  backgroundColor: _getStatusColor(property.propertyStatus),
                  iconData: _getStatusIcon(property.propertyStatus),
                ),
              ),
          ],
        ),
        if (property.address != null) ...[
          const SizedBox(height: 4),
          Text(
            property.address!.getFullAddress(),
            style: theme.textTheme.bodySmall,
          ),
        ],
        const SizedBox(height: 12),
        _buildInfoChips(context),
        const SizedBox(height: 12),
        Text(
          '${kCurrencyFormat.format(property.price)} / ${property.rentingType.displayName.toLowerCase()}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        if (property.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(property.description, style: theme.textTheme.bodyMedium),
        ],
      ],
    );
  }

  Widget _buildInfoChips(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _InfoChip(
          icon: Icons.king_bed_outlined,
          label: '${property.bedrooms} Beds',
        ),
        _InfoChip(
          icon: Icons.bathtub_outlined,
          label: '${property.bathrooms} Baths',
        ),
        _InfoChip(
          icon: Icons.square_foot_outlined,
          label: '${property.area.toStringAsFixed(0)} m²',
        ),
        _InfoChip(
          icon: Icons.calendar_today_outlined,
          label: property.rentingType.displayName,
          color: Theme.of(context).colorScheme.secondary,
        ),
      ],
    );
  }

  Color _getStatusColor(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return Colors.green;
      case PropertyStatus.rented:
        return Colors.orange;
      case PropertyStatus.maintenance:
        return Colors.blue;
      case PropertyStatus.unavailable:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(PropertyStatus status) {
    switch (status) {
      case PropertyStatus.available:
        return Icons.check_circle_outline;
      case PropertyStatus.rented:
        return Icons.person_outline;
      case PropertyStatus.maintenance:
        return Icons.build_circle_outlined;
      case PropertyStatus.unavailable:
        return Icons.help_outline;
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chipColor = color ?? theme.chipTheme.backgroundColor;
    return Chip(
      avatar: Icon(icon, size: 16, color: chipColor),
      label: Text(label),
      backgroundColor: chipColor?.withValues(alpha: 0.1),
      shape: StadiumBorder(
        side: BorderSide(color: chipColor!.withValues(alpha: 0.2)),
      ),
    );
  }
}
