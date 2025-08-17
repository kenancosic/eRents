enum UserType {
  guest(0),
  landlord(1),
  tenant(2);

  const UserType(this.value);
  final int value;

  static UserType fromValue(int value) {
    return UserType.values.firstWhere((e) => e.value == value);
  }

  static UserType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'guest':
      case 'user': // treat generic "user" as guest-level in this client
        return UserType.guest;
      case 'landlord':
        return UserType.landlord;
      case 'tenant':
        return UserType.tenant;
      default:
        throw ArgumentError('Unknown user type: $type');
    }
  }

  // Accepts dynamic from backend: int codes, numeric strings, or names
  static UserType fromDynamic(dynamic value) {
    if (value == null) return UserType.guest;
    if (value is int) {
      try {
        return fromValue(value);
      } catch (_) {
        return UserType.guest;
      }
    }
    if (value is String) {
      // numeric string fallback
      final asInt = int.tryParse(value);
      if (asInt != null) {
        try {
          return fromValue(asInt);
        } catch (_) {
          return UserType.guest;
        }
      }
      try {
        return fromString(value);
      } catch (_) {
        return UserType.guest;
      }
    }
    return UserType.guest;
  }

  String get displayName {
    switch (this) {
      case UserType.guest:
        return 'Guest';
      case UserType.landlord:
        return 'Landlord';
      case UserType.tenant:
        return 'Tenant';
    }
  }

  @override
  String toString() => displayName;
}
