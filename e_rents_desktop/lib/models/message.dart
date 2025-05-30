class Message {
  final int id;
  final int senderId;
  final int receiverId;
  final String messageText;
  final DateTime dateSent;
  final bool isRead;
  final bool isDeleted;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    required this.dateSent,
    this.isRead = false,
    this.isDeleted = false,
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
  }) {
    return Message(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      messageText: messageText ?? this.messageText,
      dateSent: dateSent ?? this.dateSent,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }
}
