import 'dart:convert';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';

// TODO: Full backend integration for all chat features is pending.
// Ensure all endpoints are functional and error handling is robust.
class ChatService extends ApiService {
  ChatService(super.baseUrl, super.storageService);

  Future<List<User>> getContacts() async {
    print('ChatService: Attempting to fetch contacts...');
    try {
      final response = await get('/Chat/Contacts', authenticated: true);
      final List<dynamic> jsonResponse = json.decode(response.body);
      // Add individual item parsing try-catch if needed
      final contacts = jsonResponse.map((json) => User.fromJson(json)).toList();
      print('ChatService: Successfully fetched ${contacts.length} contacts.');
      return contacts;
    } catch (e) {
      print(
        'ChatService: Error fetching contacts: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch contacts. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<List<Message>> getMessages(
    int contactId, {
    int? page,
    int? pageSize,
  }) async {
    print(
      'ChatService: Attempting to fetch messages for contact $contactId...',
    );
    String endpoint = '/Chat/$contactId/Messages';
    Map<String, String> queryParams = {};
    if (page != null) queryParams['page'] = page.toString();
    if (pageSize != null) queryParams['pageSize'] = pageSize.toString();

    if (queryParams.isNotEmpty) {
      endpoint += '?' + Uri(queryParameters: queryParams).query;
    }

    try {
      final response = await get(endpoint, authenticated: true);
      final List<dynamic> jsonResponse = json.decode(response.body);
      // Add individual item parsing try-catch if needed
      final messages =
          jsonResponse.map((json) => Message.fromJson(json)).toList();
      print(
        'ChatService: Successfully fetched ${messages.length} messages for contact $contactId.',
      );
      return messages;
    } catch (e) {
      print(
        'ChatService: Error fetching messages for contact $contactId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to fetch messages for contact $contactId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<Message> sendMessage(int receiverId, String messageText) async {
    print('ChatService: Attempting to send message to $receiverId...');
    try {
      final response = await post('/Chat/SendMessage', {
        'receiverId': receiverId,
        'messageText': messageText,
      }, authenticated: true);
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      final sentMessage = Message.fromJson(jsonResponse);
      print(
        'ChatService: Successfully sent message ${sentMessage.id} to $receiverId.',
      );
      return sentMessage;
    } catch (e) {
      print(
        'ChatService: Error sending message to $receiverId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to send message to $receiverId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<void> deleteMessage(int messageId) async {
    print('ChatService: Attempting to delete message $messageId...');
    try {
      await delete('/Messages/$messageId', authenticated: true);
      print('ChatService: Successfully deleted message $messageId.');
    } catch (e) {
      print(
        'ChatService: Error deleting message $messageId: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to delete message $messageId. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }

  Future<void> markMessageAsRead(int messageId) async {
    print('ChatService: Attempting to mark message $messageId as read...');
    try {
      await put('/Messages/$messageId/Read', {}, authenticated: true);
      print('ChatService: Successfully marked message $messageId as read.');
    } catch (e) {
      print(
        'ChatService: Error marking message $messageId as read: $e. Backend integration might be pending or endpoint unavailable.',
      );
      throw Exception(
        'Failed to mark message $messageId as read. Backend integration pending or endpoint unavailable. Cause: $e',
      );
    }
  }
}
