import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/models/message.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';

/// Simplified chat service for tenant-landlord communication
/// Handles messaging, property offers, and communication history
class SimpleChatService {
  final ApiService _apiService;

  SimpleChatService(this._apiService);

  /// Get chat conversations for current tenant
  Future<List<Map<String, dynamic>>> getConversations() async {
    try {
      final response = await _apiService.get('api/Chat/conversations');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      return [];
    }
  }

  /// Get messages for a specific conversation
  Future<List<Message>> getMessages(String conversationId) async {
    try {
      final response = await _apiService.get('api/Chat/conversations/$conversationId/messages');
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => Message.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error loading messages: $e');
      return [];
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    String? messageType,
  }) async {
    try {
      final messageData = {
        'conversationId': conversationId,
        'content': content,
        'messageType': messageType ?? 'text',
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _apiService.post('api/Chat/messages', messageData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  /// Start a new conversation with a landlord
  Future<String?> startConversation({
    required int landlordId,
    required int propertyId,
    String? initialMessage,
  }) async {
    try {
      final conversationData = {
        'landlordId': landlordId,
        'propertyId': propertyId,
        'initialMessage': initialMessage ?? 'Hello, I\'m interested in your property.',
      };

      final response = await _apiService.post('api/Chat/conversations', conversationData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        return data['conversationId'] as String?;
      }
      return null;
    } catch (e) {
      debugPrint('Error starting conversation: $e');
      return null;
    }
  }

  /// Mark messages as read
  Future<bool> markMessagesAsRead(String conversationId) async {
    try {
      final response = await _apiService.put('api/Chat/conversations/$conversationId/mark-read', {});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      return false;
    }
  }

  /// Get unread message count
  Future<int> getUnreadCount() async {
    try {
      final response = await _apiService.get('api/Chat/unread-count');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['unreadCount'] as int? ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  /// Request property viewing
  Future<bool> requestPropertyViewing({
    required int propertyId,
    required DateTime preferredDate,
    String? message,
  }) async {
    try {
      final requestData = {
        'propertyId': propertyId,
        'preferredDate': preferredDate.toIso8601String(),
        'message': message ?? 'I would like to schedule a viewing for this property.',
        'requestType': 'propertyViewing',
      };

      final response = await _apiService.post('api/Chat/property-viewing-request', requestData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error requesting property viewing: $e');
      return false;
    }
  }

  /// Send inquiry about property
  Future<bool> sendPropertyInquiry({
    required int propertyId,
    required String inquiry,
  }) async {
    try {
      final inquiryData = {
        'propertyId': propertyId,
        'inquiry': inquiry,
        'messageType': 'propertyInquiry',
      };

      final response = await _apiService.post('api/Chat/property-inquiry', inquiryData);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending property inquiry: $e');
      return false;
    }
  }
}