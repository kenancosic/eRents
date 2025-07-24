import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/services/api_service.dart';
import 'package:e_rents_mobile/feature/chat/models/chat_room.dart';
import 'package:e_rents_mobile/feature/chat/models/chat_message.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService;

  ChatProvider(this._apiService);

  // State for chat rooms
  List<ChatRoom> _chatRooms = [];
  bool _isLoadingRooms = false;
  String? _roomsError;
  DateTime? _lastRoomsFetch;

  // State for messages within a specific room
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, bool> _isLoadingMessages = {};
  final Map<String, String?> _messagesError = {};

  // Getters
  List<ChatRoom> get chatRooms => _chatRooms;
  bool get isLoadingRooms => _isLoadingRooms;
  String? get roomsError => _roomsError;

  List<ChatMessage> messagesForRoom(String roomId) => _messages[roomId] ?? [];
  bool isLoadingMessages(String roomId) => _isLoadingMessages[roomId] ?? false;
  String? messageErrorForRoom(String roomId) => _messagesError[roomId];

  // Caching for chat rooms list
  bool get _isRoomsCacheValid {
    if (_lastRoomsFetch == null) return false;
    return DateTime.now().difference(_lastRoomsFetch!).inMinutes < 5; // 5-minute cache
  }

  // --- Methods ---

  Future<void> fetchChatRooms({bool forceRefresh = false}) async {
    if (!forceRefresh && _isRoomsCacheValid) {
      return;
    }

    _isLoadingRooms = true;
    _roomsError = null;
    notifyListeners();

    try {
      final data = await _apiService.get('chat/rooms');
      _chatRooms = (data as List).map((json) => ChatRoom.fromJson(json)).toList();
      _lastRoomsFetch = DateTime.now();
    } catch (e) {
      _roomsError = 'Failed to load chat rooms: $e';
    } finally {
      _isLoadingRooms = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String roomId) async {
    _isLoadingMessages[roomId] = true;
    _messagesError[roomId] = null;
    notifyListeners();

    try {
      final data = await _apiService.get('chat/rooms/$roomId/messages');
      final messages = (data as List).map((json) => ChatMessage.fromJson(json)).toList();
      _messages[roomId] = messages.reversed.toList(); // Assuming API returns latest first
    } catch (e) {
      _messagesError[roomId] = 'Failed to load messages: $e';
    } finally {
      _isLoadingMessages[roomId] = false;
      notifyListeners();
    }
  }

  Future<bool> sendMessage(String roomId, String text) async {
    try {
      final response = await _apiService.post('chat/rooms/$roomId/messages', {'text': text});
      final newMessage = ChatMessage.fromJson(response as Map<String, dynamic>);

      if (_messages.containsKey(roomId)) {
        _messages[roomId]?.add(newMessage);
      } else {
        _messages[roomId] = [newMessage];
      }

      // Optionally, refresh the chat rooms list to update the 'lastMessage'
      fetchChatRooms(forceRefresh: true);

      notifyListeners();
      return true;
    } catch (e) {
      _messagesError[roomId] = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }
}
