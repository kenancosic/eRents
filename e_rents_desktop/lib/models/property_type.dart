/// Property type enum matching backend PropertyTypeEnum values
enum PropertyType { apartment, house, condo, townhouse, studio }

/// Extension for PropertyType to provide display names
extension PropertyTypeExtension on PropertyType {
  String get displayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.condo:
        return 'Condo';
      case PropertyType.townhouse:
        return 'Townhouse';
      case PropertyType.studio:
        return 'Studio';
    }
  }
}
