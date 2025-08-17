import 'package:e_rents_desktop/models/user.dart';

enum NotificationType {
  maintenance,
  booking,
  message,
  system;

  static NotificationType fromString(String type) {
    switch (type.toLowerCase()) {
      case 'maintenance':
        return NotificationType.maintenance;
      case 'booking':
        return NotificationType.booking;
      case 'message':
        return NotificationType.message;
      case 'system':
        return NotificationType.system;
      default:
        throw ArgumentError('Unknown notification type: $type');
    }
  }

  String get displayName {
    switch (this) {
      case NotificationType.maintenance:
        return 'Maintenance';
      case NotificationType.booking:
        return 'Booking';
      case NotificationType.message:
        return 'Message';
      case NotificationType.system:
        return 'System';
    }
  }

  String get typeName => name.toLowerCase();
}

class Notification {
  final int notificationId;
  final int userId;
  final String title;
  final String message;
  final NotificationType type;
  final int? referenceId; // ID of related entity (bookingId, maintenanceIssueId, etc.)
  final bool isRead;

  // BaseEntity fields
  final DateTime createdAt;
  final DateTime updatedAt;
  final int? createdBy;
  final int? modifiedBy;

  // Navigation properties - excluded from JSON serialization
  final User? user;

  const Notification({
    required this.notificationId,
    required this.userId,
    required this.title,
    required this.message,
    required this.type,
    this.referenceId,
    this.isRead = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.modifiedBy,
    this.user,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    DateTime _reqDate(dynamic v) {
      final d = (v == null) ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));
      return d ?? DateTime.now();
    }
    int _toInt(dynamic v) => v is num ? v.toInt() : int.parse(v.toString());
    int? _asInt(dynamic v) => v == null ? null : (v is num ? v.toInt() : int.tryParse(v.toString()));
    String _str(dynamic v) => v?.toString() ?? '';
    bool _asBool(dynamic v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
      return fallback;
    }
    NotificationType _parseType(dynamic v) {
      if (v == null) return NotificationType.system;
      final s = v.toString();
      try { return NotificationType.fromString(s); } catch (_) { return NotificationType.system; }
    }
    final created = _reqDate(json['createdAt']);
    final updated = _reqDate(json['updatedAt'] ?? created);
    return Notification(
      notificationId: _toInt(json['notificationId']),
      userId: _toInt(json['userId']),
      title: _str(json['title']),
      message: _str(json['message']),
      type: _parseType(json['type']),
      referenceId: _asInt(json['referenceId']),
      isRead: _asBool(json['isRead'], fallback: false),
      createdAt: created,
      updatedAt: updated,
      createdBy: _asInt(json['createdBy']),
      modifiedBy: _asInt(json['modifiedBy']),
      user: null,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'notificationId': notificationId,
        'userId': userId,
        'title': title,
        'message': message,
        'type': type.typeName,
        'referenceId': referenceId,
        'isRead': isRead,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'createdBy': createdBy,
        'modifiedBy': modifiedBy,
      };
}