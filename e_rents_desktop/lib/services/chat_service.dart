import 'dart:convert';
import 'package:e_rents_desktop/models/message.dart';
import 'package:e_rents_desktop/models/user.dart';
import 'package:e_rents_desktop/services/api_service.dart';

class ChatService extends ApiService {
  ChatService(super.baseUrl, super.storageService);

  Future<List<User>> getContacts() async {
    // Assuming an endpoint like '/api/Chat/Contacts' or similar
    // Adjust endpoint as per your actual API
    final response = await get('/Chat/Contacts', authenticated: true);
    final List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((json) => User.fromJson(json)).toList();
  }

  Future<List<Message>> getMessages(
    String contactId, {
    int? page,
    int? pageSize,
  }) async {
    // Endpoint like '/api/Chat/{contactId}/Messages'
    // Add query parameters for pagination if supported by API
    String endpoint = '/Chat/$contactId/Messages';
    Map<String, String> queryParams = {};
    if (page != null) queryParams['page'] = page.toString();
    if (pageSize != null) queryParams['pageSize'] = pageSize.toString();

    if (queryParams.isNotEmpty) {
      endpoint += '?' + Uri(queryParameters: queryParams).query;
    }

    final response = await get(endpoint, authenticated: true);
    final List<dynamic> jsonResponse = json.decode(response.body);
    return jsonResponse.map((json) => Message.fromJson(json)).toList();
  }

  Future<Message> sendMessage(String receiverId, String messageText) async {
    // Endpoint like '/api/Chat/SendMessage' or '/api/Messages'
    final response = await post('/Chat/SendMessage', {
      'receiverId': receiverId,
      'messageText': messageText,
      // Backend should set senderId based on authenticated user, and generate ID/timestamp
    }, authenticated: true);
    final Map<String, dynamic> jsonResponse = json.decode(response.body);
    return Message.fromJson(jsonResponse);
  }

  Future<void> deleteMessage(String messageId) async {
    // Endpoint like '/api/Messages/{messageId}'
    await delete('/Messages/$messageId', authenticated: true);
  }

  Future<void> markMessageAsRead(String messageId) async {
    // Endpoint like '/api/Messages/{messageId}/Read'
    await put('/Messages/$messageId/Read', {}, authenticated: true);
  }
}
