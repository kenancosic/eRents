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
      'status': status.name,
      'unavailableFrom': unavailableFrom != null 
          ? '${unavailableFrom!.year.toString().padLeft(4, '0')}-${unavailableFrom!.month.toString().padLeft(2, '0')}-${unavailableFrom!.day.toString().padLeft(2, '0')}'
          : null,
      'unavailableTo': unavailableTo != null 
          ? '${unavailableTo!.year.toString().padLeft(4, '0')}-${unavailableTo!.month.toString().padLeft(2, '0')}-${unavailableTo!.day.toString().padLeft(2, '0')}'
          : null,
    };
  }
}
