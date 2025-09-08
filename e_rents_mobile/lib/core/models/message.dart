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
    // Handle both camelCase and PascalCase field names
    final id = json['messageId'] ?? json['MessageId'] ?? json['id'] ?? json['Id'] ?? 0;
    final senderId = json['senderId'] ?? json['SenderId'] ?? 0;
    final receiverId = json['receiverId'] ?? json['ReceiverId'] ?? 0;
    final messageText = json['messageText'] ?? json['MessageText'] ?? '';
    final isRead = json['isRead'] ?? json['IsRead'] ?? false;
    
    // Handle date parsing for both string and numeric timestamps
    DateTime? dateSent;
    final createdAt = json['createdAt'] ?? json['CreatedAt'];
    if (createdAt != null) {
      if (createdAt is String) {
        dateSent = DateTime.tryParse(createdAt);
      } else if (createdAt is int) {
        // Handle both milliseconds and seconds since epoch
        if (createdAt > 10000000000) {
          // Milliseconds
          dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt);
        } else {
          // Seconds
          dateSent = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
        }
      }
    }

    return Message(
      messageId: id is int ? id : (int.tryParse(id.toString()) ?? 0),
      senderId: senderId is int ? senderId : (int.tryParse(senderId.toString()) ?? 0),
      receiverId: receiverId is int ? receiverId : (int.tryParse(receiverId.toString()) ?? 0),
      messageText: messageText is String ? messageText : messageText.toString(),
      dateSent: dateSent,
      isRead: isRead is bool ? isRead : (isRead?.toString().toLowerCase() == 'true'),
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
