enum PropertyStatus {
  available(1),
  occupied(2),
  underMaintenance(3),
  unavailable(4);

  const PropertyStatus(this.value);
  final int value;

  static PropertyStatus fromValue(int value) {
    return PropertyStatus.values.firstWhere((e) => e.value == value);
  }

  static PropertyStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return PropertyStatus.available;
      case 'occupied':
        return PropertyStatus.occupied;
      case 'maintenance':
      case 'undermaintenance':
        return PropertyStatus.underMaintenance;
      case 'unavailable':
        return PropertyStatus.unavailable;
      default:
        throw ArgumentError('Unknown property status: $status');
    }
  }

  String get displayName {
    switch (this) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.occupied:
        return 'Occupied';
      case PropertyStatus.underMaintenance:
        return 'Under Maintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
    }
  }

  String get name {
    switch (this) {
      case PropertyStatus.available:
        return 'Available';
      case PropertyStatus.occupied:
        return 'Occupied';
      case PropertyStatus.underMaintenance:
        return 'UnderMaintenance';
      case PropertyStatus.unavailable:
        return 'Unavailable';
    }
  }

  @override
  String toString() => displayName;
}
