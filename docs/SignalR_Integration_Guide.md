# SignalR Integration Guide for eRents Chat

This guide explains how to integrate SignalR for real-time chat functionality in the eRents frontend applications.

## Overview

The eRents platform uses SignalR for real-time communication, enabling instant message delivery, typing indicators, and online status updates.

## Frontend Integration (Flutter/Dart)

### 1. Add SignalR Client Package

Add the SignalR client to your `pubspec.yaml`:

```yaml
dependencies:
  signalr_netcore: ^1.3.3
```

### 2. Create SignalR Service

```dart
import 'package:signalr_netcore/signalr_netcore.dart';

class SignalRService {
  late HubConnection _hubConnection;
  final String _baseUrl = 'http://localhost:5000';
  
  Future<void> initializeConnection(String authToken) async {
    _hubConnection = HubConnectionBuilder()
        .withUrl('$_baseUrl/chatHub', options: HttpConnectionOptions(
          accessTokenFactory: () async => authToken,
        ))
        .withAutomaticReconnect()
        .build();
    
    _setupEventHandlers();
    await startConnection();
  }
  
  void _setupEventHandlers() {
    // Handle incoming messages
    _hubConnection.on('ReceiveMessage', (arguments) {
      final messageData = arguments?[0];
      // Process incoming message
      print('New message: $messageData');
    });
    
    // Handle connection status
    _hubConnection.on('Connected', (arguments) {
      final connectionInfo = arguments?[0];
      print('Connected: $connectionInfo');
    });
    
    // Handle typing indicators
    _hubConnection.on('UserTyping', (arguments) {
      final typingInfo = arguments?[0];
      print('User typing: $typingInfo');
    });
    
    // Handle user status updates
    _hubConnection.on('UserStatusChanged', (arguments) {
      final statusInfo = arguments?[0];
      print('User status changed: $statusInfo');
    });
  }
  
  Future<void> startConnection() async {
    try {
      await _hubConnection.start();
      print('SignalR connection started');
    } catch (e) {
      print('Error starting SignalR connection: $e');
      // Retry after delay
      Future.delayed(Duration(seconds: 5), () => startConnection());
    }
  }
  
  // Send message
  Future<void> sendMessage(int receiverId, String message) async {
    try {
      await _hubConnection.invoke('SendMessageToUser', args: [receiverId, message]);
    } catch (e) {
      print('Error sending message: $e');
    }
  }
  
  // Send typing indicator
  Future<void> sendTypingIndicator(int receiverId) async {
    try {
      await _hubConnection.invoke('UserTyping', args: [receiverId]);
    } catch (e) {
      print('Error sending typing indicator: $e');
    }
  }
  
  // Stop typing indicator
  Future<void> stopTypingIndicator(int receiverId) async {
    try {
      await _hubConnection.invoke('UserStoppedTyping', args: [receiverId]);
    } catch (e) {
      print('Error stopping typing indicator: $e');
    }
  }
  
  // Get user online status
  Future<void> getUserOnlineStatus(int userId) async {
    try {
      await _hubConnection.invoke('GetUserOnlineStatus', args: [userId]);
    } catch (e) {
      print('Error getting user status: $e');
    }
  }
  
  // Mark message as read
  Future<void> markMessageAsRead(int messageId) async {
    try {
      await _hubConnection.invoke('MarkMessageAsRead', args: [messageId]);
    } catch (e) {
      print('Error marking message as read: $e');
    }
  }
  
  void dispose() {
    _hubConnection.stop();
  }
}
```

### 3. Update Chat Provider

Update your chat provider to use SignalR:

```dart
class ChatProvider extends ChangeNotifier {
  final SignalRService _signalRService = SignalRService();
  final ChatRepository _chatRepository;
  
  // Initialize SignalR when user logs in
  Future<void> initializeChat(String authToken) async {
    await _signalRService.initializeConnection(authToken);
    
    // Set up message handler
    _signalRService.onMessageReceived = (messageData) {
      // Add message to local list
      _messages.add(Message.fromJson(messageData));
      notifyListeners();
    };
  }
  
  // Send message via SignalR
  Future<void> sendMessage(int receiverId, String text) async {
    // Send via SignalR for real-time delivery
    await _signalRService.sendMessage(receiverId, text);
    
    // Also save via REST API for persistence
    await _chatRepository.sendMessage(receiverId, text);
  }
}
```

## WebSocket Connection States

Handle different connection states:

```dart
enum ConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

class ChatConnectionManager {
  ConnectionState _state = ConnectionState.disconnected;
  
  void handleConnectionChange(HubConnectionState state) {
    switch (state) {
      case HubConnectionState.Connected:
        _state = ConnectionState.connected;
        break;
      case HubConnectionState.Connecting:
        _state = ConnectionState.connecting;
        break;
      case HubConnectionState.Reconnecting:
        _state = ConnectionState.reconnecting;
        break;
      case HubConnectionState.Disconnected:
        _state = ConnectionState.disconnected;
        break;
    }
  }
}
```

## Authentication

SignalR uses the same JWT authentication as the REST API:

```dart
final token = await authProvider.getAuthToken();
await signalRService.initializeConnection(token);
```

## Message Format

Messages are sent and received in this format:

```json
{
  "senderId": 123,
  "senderName": "John Doe",
  "receiverId": 456,
  "messageText": "Hello!",
  "dateSent": "2024-01-15T10:30:00Z",
  "isRead": false
}
```

## Error Handling

Implement proper error handling and reconnection logic:

```dart
_hubConnection.onclose((error) {
  print('Connection closed: $error');
  // Attempt to reconnect
  Future.delayed(Duration(seconds: 5), () {
    startConnection();
  });
});

_hubConnection.onreconnecting((error) {
  print('Attempting to reconnect: $error');
  // Update UI to show reconnecting state
});

_hubConnection.onreconnected((connectionId) {
  print('Reconnected with ID: $connectionId');
  // Refresh data after reconnection
});
```

## Testing

Test SignalR connection:

```bash
# 1. Start RabbitMQ
docker run -d --name rabbitmq -p 5672:5672 -p 15672:15672 rabbitmq:3-management

# 2. Start the RabbitMQ Microservice
cd eRents.RabbitMQMicroservice
dotnet run

# 3. Start the WebAPI
cd eRents.WebApi
dotnet run

# 4. Test SignalR connection
# Use a tool like wscat or Postman to test WebSocket connection
```

## Troubleshooting

### Common Issues

1. **Connection fails**: Check CORS configuration in WebAPI
2. **Authentication fails**: Ensure JWT token is valid and properly formatted
3. **Messages not received**: Verify user is in the correct SignalR group
4. **Reconnection issues**: Implement exponential backoff for reconnection attempts

### Debug Mode

Enable detailed logging:

```dart
_hubConnection = HubConnectionBuilder()
    .withUrl('$_baseUrl/chatHub')
    .configureLogging(LogLevel.debug)
    .build();
```

## Performance Considerations

1. **Message Batching**: For high-volume chats, consider batching messages
2. **Connection Pooling**: Reuse connections across different chat screens
3. **Offline Support**: Queue messages locally when disconnected
4. **Compression**: Enable message compression for large payloads

## Security

1. **Authentication**: Always use JWT tokens for authentication
2. **Authorization**: Verify user permissions on the server
3. **Message Validation**: Validate and sanitize all messages
4. **Rate Limiting**: Implement rate limiting to prevent spam