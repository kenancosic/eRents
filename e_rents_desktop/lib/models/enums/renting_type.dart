enum RentingType {
  daily(1),
  monthly(2);

  const RentingType(this.value);
  final int value;

  static RentingType fromValue(int value) {
    return RentingType.values.firstWhere((e) => e.value == value);
  }

  static RentingType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'daily':
        return RentingType.daily;
      case 'monthly':
        return RentingType.monthly;
      default:
        throw ArgumentError('Unknown renting type: $type');
    }
  }

  String get displayName {
    switch (this) {
      case RentingType.daily:
        return 'Daily';
      case RentingType.monthly:
        return 'Monthly';
    }
  }

  @override
  String toString() => displayName;
}
