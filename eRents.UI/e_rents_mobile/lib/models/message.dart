class Message {
  final int messageId;
  final int senderId;
  final int receiverId;
  final String messageText;
  final DateTime? dateSent;
  final bool? isRead;

  Message({
    required this.messageId,
    required this.senderId,
    required this.receiverId,
    required this.messageText,
    this.dateSent,
    this.isRead,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['messageId'],
      senderId: json['senderId'],
      receiverId: json['receiverId'],
      messageText: json['messageText'],
      dateSent: json['dateSent'] != null ? DateTime.parse(json['dateSent']) : null,
      isRead: json['isRead'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'receiverId': receiverId,
      'messageText': messageText,
      'dateSent': dateSent?.toIso8601String(),
      'isRead': isRead,
    };
  }
}
