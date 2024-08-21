import 'dart:convert';
import 'package:e_rents_mobile/services/rabbitmq_service.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';

class MessageService {
  final RabbitMQService _client;

  MessageService({required String hostname, required int port, required String username, required String password})
      : _client = RabbitMQService(hostname: hostname, port: port, username: username, password: password);

  void sendMessage(String queueName, Message message) {
    final jsonMessage = jsonEncode(message.toJson());
    _client.publish(queueName, jsonMessage);
  }

  void subscribeToMessages(String queueName, Function(Map<String, dynamic>) onMessage) {
    _client.subscribe(queueName, (message) {
      final decodedMessage = jsonDecode(message);
      onMessage(decodedMessage);
    });
  }
}
