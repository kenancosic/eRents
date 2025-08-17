enum PropertyType {
  apartment(1),
  house(2),
  studio(3),
  villa(4),
  room(5);

  const PropertyType(this.value);
  final int value;

  static PropertyType fromValue(int value) {
    return PropertyType.values.firstWhere((e) => e.value == value);
  }

  static PropertyType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'apartment':
        return PropertyType.apartment;
      case 'house':
        return PropertyType.house;
      case 'studio':
        return PropertyType.studio;
      case 'villa':
        return PropertyType.villa;
      case 'room':
        return PropertyType.room;
      default:
        throw ArgumentError('Unknown property type: $type');
    }
  }

  String get displayName {
    switch (this) {
      case PropertyType.apartment:
        return 'Apartment';
      case PropertyType.house:
        return 'House';
      case PropertyType.studio:
        return 'Studio';
      case PropertyType.villa:
        return 'Villa';
      case PropertyType.room:
        return 'Room';
    }
  }

  @override
  String toString() => displayName;
}
