import 'package:e_rents_mobile/models/message.dart';

class ChatRoom {
  final String id;
  final List<String> participantIds; // IDs of the users in the chat
  final List<Message> messages;

  ChatRoom({
    required this.id,
    required this.participantIds,
    required this.messages,
  });

  // Add methods for serialization/deserialization if necessary
}
