/// Property status enum matching backend PropertyStatusEnum values
enum PropertyStatus { available, rented, maintenance, unavailable }

/// Extension for PropertyStatus to provide display names
extension PropertyStatusExtension on PropertyStatus {
  String get displayName {
    switch (this) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.rented:
        return 'Rented';
      case PropertyStatus.maintenance:
        return 'Maintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
    }
  }
}
