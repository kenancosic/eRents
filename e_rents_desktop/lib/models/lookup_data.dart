// Lookup Data Models
// These models represent the ID-Name pairs returned from the backend lookup APIs

class LookupItem {
  final int id;
  final String name;

  const LookupItem({required this.id, required this.name});

  factory LookupItem.fromJson(Map<String, dynamic> json) {
    // Handle different ID field names from backend
    int id;
    if (json.containsKey('id')) {
      id = json['id'] as int;
    } else if (json.containsKey('typeId')) {
      id = json['typeId'] as int;
    } else if (json.containsKey('rentingTypeId')) {
      id = json['rentingTypeId'] as int;
    } else if (json.containsKey('userTypeId')) {
      id = json['userTypeId'] as int;
    } else if (json.containsKey('bookingStatusId')) {
      id = json['bookingStatusId'] as int;
    } else if (json.containsKey('priorityId')) {
      id = json['priorityId'] as int;
    } else if (json.containsKey('statusId')) {
      id = json['statusId'] as int;
    } else if (json.containsKey('amenityId')) {
      id = json['amenityId'] as int;
    } else {
      throw ArgumentError('No valid ID field found in JSON: ${json.keys}');
    }

    return LookupItem(id: id, name: json['name'] as String);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name};
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LookupItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'LookupItem(id: $id, name: $name)';
}

// Comprehensive lookup data container
class LookupData {
  final List<LookupItem> propertyTypes;
  final List<LookupItem> rentingTypes;
  final List<LookupItem> userTypes;
  final List<LookupItem> bookingStatuses;
  final List<LookupItem> issuePriorities;
  final List<LookupItem> issueStatuses;
  final List<LookupItem> propertyStatuses;
  final List<LookupItem> amenities;

  const LookupData({
    required this.propertyTypes,
    required this.rentingTypes,
    required this.userTypes,
    required this.bookingStatuses,
    required this.issuePriorities,
    required this.issueStatuses,
    required this.propertyStatuses,
    required this.amenities,
  });

  factory LookupData.fromJson(Map<String, dynamic> json) {
    return LookupData(
      propertyTypes: _parseItemList(json['propertyTypes']),
      rentingTypes: _parseItemList(json['rentingTypes']),
      userTypes: _parseItemList(json['userTypes']),
      bookingStatuses: _parseItemList(json['bookingStatuses']),
      issuePriorities: _parseItemList(json['issuePriorities']),
      issueStatuses: _parseItemList(json['issueStatuses']),
      propertyStatuses: _parseItemList(json['propertyStatuses']),
      amenities: _parseItemList(json['amenities']),
    );
  }

  static List<LookupItem> _parseItemList(dynamic jsonList) {
    if (jsonList == null || jsonList is! List) return [];
    return (jsonList)
        .map((item) => LookupItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Map<String, dynamic> toJson() {
    return {
      'propertyTypes': propertyTypes.map((item) => item.toJson()).toList(),
      'rentingTypes': rentingTypes.map((item) => item.toJson()).toList(),
      'userTypes': userTypes.map((item) => item.toJson()).toList(),
      'bookingStatuses': bookingStatuses.map((item) => item.toJson()).toList(),
      'issuePriorities': issuePriorities.map((item) => item.toJson()).toList(),
      'issueStatuses': issueStatuses.map((item) => item.toJson()).toList(),
      'propertyStatuses':
          propertyStatuses.map((item) => item.toJson()).toList(),
      'amenities': amenities.map((item) => item.toJson()).toList(),
    };
  }

  // Helper methods for quick lookups
  LookupItem? getPropertyTypeById(int id) =>
      propertyTypes.where((item) => item.id == id).firstOrNull;

  LookupItem? getRentingTypeById(int id) => rentingTypes
      .cast<LookupItem?>()
      .firstWhere((item) => item?.id == id, orElse: () => null);

  LookupItem? getUserTypeById(int id) => userTypes
      .cast<LookupItem?>()
      .firstWhere((item) => item?.id == id, orElse: () => null);

  LookupItem? getBookingStatusById(int id) => bookingStatuses
      .cast<LookupItem?>()
      .firstWhere((item) => item?.id == id, orElse: () => null);

  LookupItem? getIssuePriorityById(int id) => issuePriorities
      .cast<LookupItem?>()
      .firstWhere((item) => item?.id == id, orElse: () => null);

  LookupItem? getIssueStatusById(int id) => issueStatuses
      .cast<LookupItem?>()
      .firstWhere((item) => item?.id == id, orElse: () => null);

  LookupItem? getPropertyStatusById(int id) => propertyStatuses
      .cast<LookupItem?>()
      .firstWhere((item) => item?.id == id, orElse: () => null);

  LookupItem? getAmenityById(int id) => amenities
      .cast<LookupItem?>()
      .firstWhere((item) => item?.id == id, orElse: () => null);

  // Helper methods for reverse lookups
  int? getPropertyTypeIdByName(String name) =>
      propertyTypes
          .cast<LookupItem?>()
          .firstWhere(
            (item) => item?.name.toLowerCase() == name.toLowerCase(),
            orElse: () => null,
          )
          ?.id;

  int? getRentingTypeIdByName(String name) =>
      rentingTypes
          .cast<LookupItem?>()
          .firstWhere(
            (item) => item?.name.toLowerCase() == name.toLowerCase(),
            orElse: () => null,
          )
          ?.id;

  int? getPropertyStatusIdByName(String name) =>
      propertyStatuses
          .cast<LookupItem?>()
          .firstWhere(
            (item) => item?.name.toLowerCase() == name.toLowerCase(),
            orElse: () => null,
          )
          ?.id;

  int? getAmenityIdByName(String name) =>
      amenities
          .cast<LookupItem?>()
          .firstWhere(
            (item) => item?.name.toLowerCase() == name.toLowerCase(),
            orElse: () => null,
          )
          ?.id;

  // Helper method for multiple amenity lookup
  List<LookupItem> getAmenitiesByIds(List<int> ids) =>
      amenities.where((amenity) => ids.contains(amenity.id)).toList();
}
