class Message {
  final String id;
  final String senderId; // ID of the user who sent the message
  final String receiverId; // ID of the user who receives the message
  final String content;
  final DateTime timestamp;

  Message({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.content,
    required this.timestamp,
  });

  // Add methods for serialization/deserialization if necessary
}
