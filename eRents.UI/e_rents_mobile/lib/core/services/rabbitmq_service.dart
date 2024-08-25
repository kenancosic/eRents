// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:rabbitmq_client/rabbitmq_client.dart'; // Example package for RabbitMQ integration

// class RabbitMQService {
//   final RabbitMQClient _client;

//   RabbitMQService({required String hostname, required int port, required String username, required String password})
//       : _client = RabbitMQClient(hostname: hostname, port: port, username: username, password: password);

//   void subscribeToNotifications(String queueName, Function(Map<String, dynamic>) onMessage) {
//     _client.subscribe(queueName, (message) {
//       final decodedMessage = jsonDecode(message);
//       onMessage(decodedMessage);
//     });
//   }
// }
