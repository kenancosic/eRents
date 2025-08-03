import 'package:e_rents_desktop/models/property.dart';
import 'package:e_rents_desktop/models/renting_type.dart';
import 'package:e_rents_desktop/utils/formatters.dart';
import 'package:e_rents_desktop/widgets/status_chip.dart';
import 'package:flutter/material.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isGridView;

  const PropertyCard({
    super.key,
    required this.property,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    this.isGridView = false,
  });

  @override
  Widget build(BuildContext context) {
    return isGridView ? _buildGridCard(context) : _buildListCard(context);
  }

  Widget _buildListCard(BuildContext context) {
    final theme = Theme.of(context);
    final statusDisplay = _getStatusDisplayProperties(property.status, theme);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(width: 100, height: 100),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitle(theme),
                    const SizedBox(height: 4),
                    _buildAddress(),
                    const SizedBox(height: 8),
                    _buildPropertyInfo(),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildActions(context, isGrid: false),
                  const SizedBox(height: 8),
                  _buildPriceAndStatus(theme, statusDisplay, isGrid: false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final theme = Theme.of(context);
    final statusDisplay = _getStatusDisplayProperties(property.status, theme);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 160,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: StatusChip(
                      label: property.status,
                      backgroundColor: statusDisplay.color,
                      iconData: statusDisplay.icon,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildPriceBanner(theme),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTitle(theme),
                        const SizedBox(height: 4),
                        _buildAddress(),
                        const SizedBox(height: 6),
                        _buildPropertyInfo(),
                      ],
                    ),
                    _buildActions(context, isGrid: true),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage({double? width, double? height}) {
    final imageId =
        (property.coverImageId != null && property.coverImageId! > 0)
            ? property.coverImageId
            : property.imageIds.isNotEmpty
            ? property.imageIds.first
            : null;

    if (imageId == null) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(Icons.apartment, size: 48, color: Colors.grey.shade400),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.network(
        'http://localhost:5000/Image/$imageId',
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder:
            (context, error, stackTrace) => Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.broken_image,
                size: 48,
                color: Colors.grey.shade400,
              ),
            ),
      ),
    );
  }

  Widget _buildTitle(ThemeData theme) {
    return Text(
      property.name,
      style: theme.textTheme.titleMedium,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildAddress() {
    return Text(
      property.address?.getFullAddress() ?? 'No address',
      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildPropertyInfo() {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        _infoChip(Icons.bed_outlined, '${property.bedrooms} beds'),
        _infoChip(Icons.bathtub_outlined, '${property.bathrooms} baths'),
        _infoChip(Icons.square_foot_outlined, '${property.area} m²'),
      ],
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade700),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPriceBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
        ),
      ),
      child: Text(
        '${kCurrencyFormat.format(property.price)} / ${property.rentingType == RentingType.daily ? 'day' : 'month'}',
        style: theme.textTheme.titleMedium?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPriceAndStatus(
    ThemeData theme,
    ({Color color, IconData icon}) statusDisplay, {
    required bool isGrid,
  }) {
    final priceStyle = theme.textTheme.titleMedium?.copyWith(
      color: theme.colorScheme.primary,
      fontWeight: FontWeight.bold,
    );

    if (isGrid) {
      return Container();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '${kCurrencyFormat.format(property.price)} / ${property.rentingType == RentingType.daily ? 'day' : 'month'}',
          style: priceStyle,
        ),
        const SizedBox(height: 4),
        StatusChip(
          label: property.status,
          backgroundColor: statusDisplay.color,
          iconData: statusDisplay.icon,
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context, {required bool isGrid}) {
    return PopupMenuButton(
      tooltip: "Actions",
      itemBuilder:
          (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit_outlined),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete_outline, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete'),
                ],
              ),
            ),
          ],
      onSelected: (value) {
        if (value == 'edit') {
          onEdit();
        } else if (value == 'delete') {
          onDelete();
        }
      },
    );
  }

  ({Color color, IconData icon}) _getStatusDisplayProperties(
    String status,
    ThemeData theme,
  ) {
    switch (status) {
      case 'Available':
        return (color: Colors.green, icon: Icons.check_circle_outline);
      case 'Rented':
        return (color: Colors.blue, icon: Icons.person_outline);
      case 'Maintenance':
        return (color: Colors.orange, icon: Icons.build_circle_outlined);
      case 'Unavailable':
      default:
        return (color: Colors.grey, icon: Icons.help_outline);
    }
  }
}
