class UserMessage {
  final String senderUsername;
  final String recipientUsername;
  final String subject;
  final String body;

  UserMessage({required this.senderUsername, required this.recipientUsername, required this.subject, required this.body});

  factory UserMessage.fromJson(Map<String, dynamic> json) {
    return UserMessage(
      senderUsername: json['senderUsername'] as String? ?? '',
      recipientUsername: json['recipientUsername'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'senderUsername': senderUsername,
      'recipientUsername': recipientUsername,
      'subject': subject,
      'body': body,
    };
  }
}
