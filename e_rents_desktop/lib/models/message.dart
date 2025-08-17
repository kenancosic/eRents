class Message {
  final int messageId;
  final int senderId;
  final int receiverId;
  final String messageText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool? isRead;
  final bool isDeleted;

  // Fields from other entities - use "EntityName + FieldName" pattern
  final String? userFirstNameSender; // Sender's first name
  final String? userLastNameSender; // Sender's last name
  final String? userFirstNameReceiver; // Receiver's first name
  final String? userLastNameReceiver; // Receiver's last name

  const Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    required this.createdAt,
    required this.updatedAt,
    this.isRead = false,
    this.isDeleted = false,
    this.userFirstNameSender,
    this.userLastNameSender,
    this.userFirstNameReceiver,
    this.userLastNameReceiver,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    DateTime _reqDate(dynamic v) {
      final d = (v == null) ? null : (v is DateTime ? v : DateTime.tryParse(v.toString()));
      return d ?? DateTime.now();
    }
    int _toInt(dynamic v) => v is num ? v.toInt() : int.parse(v.toString());
    String _str(dynamic v) => v?.toString() ?? '';
    bool _asBool(dynamic v, {bool fallback = false}) {
      if (v == null) return fallback;
      if (v is bool) return v;
      final s = v.toString().toLowerCase();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
      return fallback;
    }
    return Message(
      messageId: _toInt(json['messageId']),
      senderId: _toInt(json['senderId']),
      receiverId: _toInt(json['receiverId']),
      messageText: _str(json['messageText']),
      createdAt: _reqDate(json['createdAt']),
      updatedAt: _reqDate(json['updatedAt'] ?? json['createdAt']),
      isRead: _asBool(json['isRead'], fallback: false),
      isDeleted: _asBool(json['isDeleted'], fallback: false),
      userFirstNameSender: json['userFirstNameSender']?.toString(),
      userLastNameSender: json['userLastNameSender']?.toString(),
      userFirstNameReceiver: json['userFirstNameReceiver']?.toString(),
      userLastNameReceiver: json['userLastNameReceiver']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'messageId': messageId,
        'senderId': senderId,
        'receiverId': receiverId,
        'messageText': messageText,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isRead': isRead ?? false,
        'isDeleted': isDeleted,
        'userFirstNameSender': userFirstNameSender,
        'userLastNameSender': userLastNameSender,
        'userFirstNameReceiver': userFirstNameReceiver,
        'userLastNameReceiver': userLastNameReceiver,
      };

  // CopyWith method for immutable updates
  Message copyWith({
    int? messageId,
    int? senderId,
    int? receiverId,
    String? messageText,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    bool? isDeleted,
    String? userFirstNameSender,
    String? userLastNameSender,
    String? userFirstNameReceiver,
    String? userLastNameReceiver,
  }) {
    return Message(
      messageId: messageId ?? this.messageId,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      messageText: messageText ?? this.messageText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      userFirstNameSender: userFirstNameSender ?? this.userFirstNameSender,
      userLastNameSender: userLastNameSender ?? this.userLastNameSender,
      userFirstNameReceiver: userFirstNameReceiver ?? this.userFirstNameReceiver,
      userLastNameReceiver: userLastNameReceiver ?? this.userLastNameReceiver,
    );
  }

  // Computed properties for UI convenience (for backward compatibility)
  String? get senderName =>
      !((userFirstNameSender?.isEmpty ?? true) &&
              (userLastNameSender?.isEmpty ?? true))
          ? '${userFirstNameSender ?? ''} ${userLastNameSender ?? ''}'.trim()
          : null;

  String? get receiverName =>
      !((userFirstNameReceiver?.isEmpty ?? true) &&
              (userLastNameReceiver?.isEmpty ?? true))
          ? '${userFirstNameReceiver ?? ''} ${userLastNameReceiver ?? ''}'
              .trim()
          : null;

  // Legacy compatibility getters
  int get id => messageId;
  DateTime get dateSent => createdAt;
  String? get senderUsername => senderName;
  String? get receiverUsername => receiverName;
}