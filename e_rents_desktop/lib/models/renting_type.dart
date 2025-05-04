enum RentingType { monthly, daily }

// Helper extension for display names (optional but useful)
extension RentingTypeExtension on RentingType {
  String get displayName {
    switch (this) {
      case RentingType.monthly:
        return 'Monthly';
      case RentingType.daily:
        return 'Daily';
    }
  }
}
