import 'package:flutter/material.dart';
import 'package:e_rents_mobile/core/base/base_provider.dart';
import 'package:e_rents_mobile/core/base/api_service_extensions.dart';
import 'package:e_rents_mobile/features/chat/models/chat_room.dart';
import 'package:e_rents_mobile/features/chat/models/chat_message.dart';

/// Chat provider for managing chat rooms and messages
/// Migrated to use new standardized BaseProvider without caching
/// Uses proper state management and error handling
class ChatProvider extends BaseProvider {
  ChatProvider(super.api);

  // ─── State ──────────────────────────────────────────────────────────────
  // Use inherited loading/error state from BaseProvider for general operations
  // isLoading, error, isError are available from BaseProvider

  // Chat rooms state
  List<ChatRoom> _chatRooms = [];
  
  // Messages state - organized by room ID
  final Map<String, List<ChatMessage>> _messages = {};
  final Map<String, bool> _isLoadingMessages = {};
  final Map<String, String?> _messagesError = {};

  // ─── Getters ────────────────────────────────────────────────────────────
  List<ChatRoom> get chatRooms => _chatRooms;
  
  // For backward compatibility, provide isLoadingRooms getter
  // This delegates to BaseProvider's isLoading for chat rooms operations
  bool get isLoadingRooms => isLoading;
  String? get roomsError => error?.message;

  List<ChatMessage> messagesForRoom(String roomId) => _messages[roomId] ?? [];
  bool isLoadingMessages(String roomId) => _isLoadingMessages[roomId] ?? false;
  String? messageErrorForRoom(String roomId) => _messagesError[roomId];
  
  // Convenience getters
  bool get hasRooms => _chatRooms.isNotEmpty;
  int get roomsCount => _chatRooms.length;

  // ─── Public API ─────────────────────────────────────────────────────────

  /// Fetch chat rooms with proper error handling
  Future<void> fetchChatRooms({bool forceRefresh = false}) async {
    // If not forcing refresh and we already have data, skip
    if (!forceRefresh && _chatRooms.isNotEmpty) {
      return;
    }

    final rooms = await executeWithState(
      () => api.getListAndDecode('chat/rooms', ChatRoom.fromJson),
    );

    if (rooms != null) {
      _chatRooms = rooms;
      debugPrint('ChatProvider: Loaded ${_chatRooms.length} chat rooms');
    }
  }

  /// Fetch messages for a specific room
  /// Uses per-room loading states for better UX
  Future<void> fetchMessages(String roomId) async {
    _isLoadingMessages[roomId] = true;
    _messagesError[roomId] = null;
    notifyListeners();

    try {
      // Use BaseProvider's API extensions for type-safe calls
      final messages = await api.getListAndDecode(
        'chat/rooms/$roomId/messages', 
        ChatMessage.fromJson,
      );
      
      // Store messages (reverse if API returns latest first)
      _messages[roomId] = messages.reversed.toList();
      
      debugPrint('ChatProvider: Loaded ${messages.length} messages for room $roomId');
    } catch (e) {
      _messagesError[roomId] = 'Failed to load messages: $e';
      debugPrint('ChatProvider: Error loading messages for room $roomId: $e');
    } finally {
      _isLoadingMessages[roomId] = false;
      notifyListeners();
    }
  }

  /// Send a message to a specific room
  /// Uses BaseProvider's executeWithState for proper error handling
  Future<bool> sendMessage(String roomId, String text) async {
    final success = await executeWithStateForSuccess(() async {
      // Send message via API
      final newMessage = await api.postAndDecode(
        'chat/rooms/$roomId/messages',
        {'text': text},
        ChatMessage.fromJson,
      );

      // Add message to local state for immediate UI update
      if (_messages.containsKey(roomId)) {
        _messages[roomId]?.add(newMessage);
      } else {
        _messages[roomId] = [newMessage];
      }
      
      // Optionally refresh chat rooms to update lastMessage
      unawaited(fetchChatRooms(forceRefresh: true));

      debugPrint('ChatProvider: Message sent successfully to room $roomId');
    }, errorMessage: 'Failed to send message');

    return success;
  }

  /// Clear messages for a specific room
  void clearMessagesForRoom(String roomId) {
    _messages.remove(roomId);
    _isLoadingMessages.remove(roomId);
    _messagesError.remove(roomId);
    notifyListeners();
    debugPrint('ChatProvider: Cleared messages for room $roomId');
  }

  /// Refresh all data (rooms and messages)
  Future<void> refreshAllData() async {
    await fetchChatRooms(forceRefresh: true);
    
    // Refresh messages for currently loaded rooms
    for (final roomId in _messages.keys.toList()) {
      await fetchMessages(roomId);
    }
    
    debugPrint('ChatProvider: Refreshed all chat data');
  }

  /// Helper method for fire-and-forget async operations
  void unawaited(Future<void> future) {
    // Intentionally not awaiting this future
    future.catchError((error) {
      debugPrint('ChatProvider: Background operation failed: $error');
    });
  }
}
