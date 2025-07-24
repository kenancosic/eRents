import 'package:e_rents_mobile/feature/chat/models/chat_message.dart';

class ChatRoom {
  final String id;
  final List<String> userIds;
  final Map<String, String> userNames;
  final Map<String, String> userImages;
  final ChatMessage? lastMessage;

  ChatRoom({
    required this.id,
    required this.userIds,
    required this.userNames,
    required this.userImages,
    this.lastMessage,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      userIds: List<String>.from(json['userIds']),
      userNames: Map<String, String>.from(json['userNames']),
      userImages: Map<String, String>.from(json['userImages']),
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
    );
  }
}
