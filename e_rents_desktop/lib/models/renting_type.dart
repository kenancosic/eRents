/// Renting type enum matching backend RentingType values
enum RentingType { daily, monthly }

/// Extension for RentingType to provide display names
extension RentingTypeExtension on RentingType {
  String get displayName {
    switch (this) {
      case RentingType.daily:
        return 'Daily';
      case RentingType.monthly:
        return 'Monthly';
    }
  }
}
