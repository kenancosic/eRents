import 'package:flutter/foundation.dart';
import '../services/message_service.dart';
import '../models/message.dart';
import 'base_provider.dart';

class MessageProvider extends BaseProvider {
  final MessageService _messageService;
  List<Message> _messages = [];

  List<Message> get messages => _messages;

  MessageProvider({required MessageService messageService})
      : _messageService = messageService {
    _messageService.subscribeToMessages('message_queue', _handleIncomingMessage);
  }

  void _handleIncomingMessage(Map<String, dynamic> message) {
    final newMessage = Message.fromJson(message);
    _messages.add(newMessage);
    notifyListeners();
  }

  void sendMessage(Message message) {
    _messageService.sendMessage('message_queue', message);
    _messages.add(message);
    notifyListeners();
  }
}
