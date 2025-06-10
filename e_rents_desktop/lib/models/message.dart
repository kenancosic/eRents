class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String messageText;
  final DateTime dateSent;
  final bool isRead;
  final bool isDeleted;

  // Fields from other entities - use "EntityName + FieldName" pattern
  final String? userFirstNameSender; // Sender's first name
  final String? userLastNameSender; // Sender's last name
  final String? userFirstNameReceiver; // Receiver's first name
  final String? userLastNameReceiver; // Receiver's last name

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    required this.dateSent,
    this.isRead = false,
    this.isDeleted = false,
    this.userFirstNameSender,
    this.userLastNameSender,
    this.userFirstNameReceiver,
    this.userLastNameReceiver,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as int,
      senderId: json['senderId'] as int,
      receiverId: json['receiverId'] as int,
      messageText: json['messageText'] as String,
      dateSent: DateTime.parse(json['dateSent'] as String),
      isRead: json['isRead'] as bool? ?? false,
      isDeleted: json['isDeleted'] as bool? ?? false,
      // Fields from other entities - use "EntityName + FieldName" pattern
      userFirstNameSender: json['userFirstNameSender'] as String?,
      userLastNameSender: json['userLastNameSender'] as String?,
      userFirstNameReceiver: json['userFirstNameReceiver'] as String?,
      userLastNameReceiver: json['userLastNameReceiver'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'messageText': messageText,
      'dateSent': dateSent.toIso8601String(),
      'isRead': isRead,
      'isDeleted': isDeleted,
    };
  }

  Message copyWith({
    int? id,
    int? senderId,
    int? receiverId,
    String? messageText,
    DateTime? dateSent,
    bool? isRead,
    bool? isDeleted,
    String? userFirstNameSender,
    String? userLastNameSender,
    String? userFirstNameReceiver,
    String? userLastNameReceiver,
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      messageText: messageText ?? this.messageText,
      dateSent: dateSent ?? this.dateSent,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      userFirstNameSender: userFirstNameSender ?? this.userFirstNameSender,
      userLastNameSender: userLastNameSender ?? this.userLastNameSender,
      userFirstNameReceiver:
          userFirstNameReceiver ?? this.userFirstNameReceiver,
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
}
