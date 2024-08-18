class UserMessage {
  final String senderUsername;
  final String recipientUsername;
  final String subject;
  final String body;

  UserMessage({required this.senderUsername, required this.recipientUsername, required this.subject, required this.body});

  factory UserMessage.fromJson(Map<String, dynamic> json) {
    return UserMessage(
      senderUsername: json['senderUsername'],
      recipientUsername: json['recipientUsername'],
      subject: json['subject'],
      body: json['body'],
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
