import 'package:e_rents_desktop/models/enums/property_status.dart';

class PropertyStatusUpdateRequest {
  final PropertyStatus status;
  final DateTime? unavailableFrom;
  final DateTime? unavailableTo;

  PropertyStatusUpdateRequest({
    required this.status,
    this.unavailableFrom,
    this.unavailableTo,
  });

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'status': status.value,
      'unavailableFrom': unavailableFrom?.toIso8601String(),
      'unavailableTo': unavailableTo?.toIso8601String(),
    };
  }
}
